pub const Buffer = packed struct(u64) {
    storage_index: u32,
    generation: u32,

    pub fn init(gpu: *Gpu, size: u32) !Buffer {
        return initAdvanced(
            gpu,
            size,
            .{ .transfer_dst = true, .shader_device_address = true },
            .{ .device_local = true },
        );
    }

    pub fn initAdvanced(gpu: *Gpu, size: u32, usage: vk.BufferUsageFlags, flags: vk.MemoryPropertyFlags) !Buffer {
        return gpu.store.buffer.create(size, usage, flags);
    }

    pub fn getDeviceAddress(self: Buffer, gpu: *Gpu) Gpu.DeviceAddress {
        return gpu.store.buffer.getAddress(self);
    }

    pub fn getHandle(self: Buffer, gpu: *Gpu) vk.Buffer {
        return gpu.store.buffer.getHandle(self);
    }

    pub fn getAllocation(self: Buffer, gpu: *Gpu) *vma.Allocation {
        return gpu.store.buffer.getAllocation(self);
    }

    pub fn getAllocationInfo(self: Buffer, gpu: *Gpu) *const vma.AllocationInfo {
        return gpu.store.buffer.getAllocationInfo(self);
    }

    pub fn deinit(self: Buffer, gpu: *Gpu) void {
        gpu.store.buffer.destroy(self) catch |err| {
            log.err("memory leak: failed to properly free buffer {any} ({s})", .{ self, @errorName(err) });
        };
    }
};

pub const Data = struct {
    generation: u32 = 0,
    state: ?State = null,
    barrier: ?vk.BufferMemoryBarrier = null,
    size: u32 = 0,
};

pub const State = struct {
    handle: vk.Buffer,
    allocation: *vma.Allocation,
    allocation_info: vma.AllocationInfo,
};

pub const Store = struct {
    gpu: *Gpu,
    storage: base.VMultiArray(Data) = .empty,
    freelist: base.VArray(u32) = .empty,

    pub const max_capacity = math.maxInt(u32);

    pub fn init(gpu: *Gpu) !*Store {
        const self = try base.gpa.create(Store);
        self.* = Store{ .gpu = gpu };
        return self;
    }

    pub fn deinit(self: *Store) void {
        for (0..self.storage.count) |storage_index| {
            if (self.storage.fieldMut(.state, storage_index).*) |*state| {
                vma.destroyBuffer(self.gpu.allocator, state.handle, state.allocation);
            }
        }
        base.gpa.destroy(self);
    }

    pub fn create(self: *Store, size: u32, usage: vk.BufferUsageFlags, flags: vk.MemoryPropertyFlags) !Buffer {
        debug.assert(size > 0);

        const storage_index = storage_index: {
            if (self.freelist.isEmpty()) {
                const index = self.storage.count;

                if (self.storage.count >= max_capacity) return error.OutOfMemory;

                try self.storage.push(Data{});

                break :storage_index index;
            } else {
                break :storage_index self.freelist.pop();
            }
        };
        errdefer self.freelist.push(@intCast(storage_index)) catch |err| {
            log.debug("memory leak: failed to restore buffer freelist index {any} after failed allocation ({s})", .{ storage_index, @errorName(err) });
        };

        const state: *?State = self.storage.fieldMut(.state, storage_index);
        debug.assert(state.* == null);

        var alloc_flags = vma.AllocationCreateFlags{};
        if (flags.host_visible) {
            alloc_flags.mapped_bit = true;
            alloc_flags.host_access_sequential_write_bit = true;
        }

        const result = vma.createBuffer(self.gpu.allocator, .{
            .size = size,
            .usage = usage,
            .sharing_mode = .exclusive,
        }, .{
            .usage = .auto,
            .flags = alloc_flags,
            .requiredFlags = flags,
        }) catch {
            log.err("Failed to allocate buffer", .{});
            return error.OutOfMemory;
        };

        state.* = State{
            .handle = result.buffer,
            .allocation = result.allocation,
            .allocation_info = result.allocation_info,
        };

        return Buffer{
            .storage_index = @intCast(storage_index),
            .generation = self.storage.field(.generation, storage_index),
        };
    }

    pub fn getSize(self: *Store, buffer: Buffer) u32 {
        debug.assert(buffer.generation == self.storage.field(.generation, buffer.storage_index));
        return self.storage.field(.size, buffer.storage_index);
    }

    pub fn getHandle(self: *Store, buffer: Buffer) vk.Buffer {
        debug.assert(buffer.generation == self.storage.field(.generation, buffer.storage_index));
        return self.storage.fieldPtr(.state, buffer.storage_index).*.?.handle;
    }

    pub fn getAllocation(self: *Store, buffer: Buffer) *vma.Allocation {
        debug.assert(buffer.generation == self.storage.field(.generation, buffer.storage_index));
        return self.storage.fieldPtr(.state, buffer.storage_index).*.?.allocation;
    }

    pub fn getAllocationInfo(self: *Store, buffer: Buffer) *const vma.AllocationInfo {
        debug.assert(buffer.generation == self.storage.field(.generation, buffer.storage_index));
        return &self.storage.fieldPtr(.state, buffer.storage_index).*.?.allocation_info;
    }

    pub fn getAddress(self: *Store, buffer: Buffer) Gpu.DeviceAddress {
        return self.gpu.device.proxy.getBufferDeviceAddress(&.{ .buffer = self.getHandle(buffer) });
    }

    pub fn destroy(self: *Store, buffer: Buffer) !void {
        if (buffer.generation != self.storage.field(.generation, buffer.storage_index)) {
            @branchHint(.cold);
            return error.UseAfterFree;
        }

        self.storage.fieldMut(.generation, buffer.storage_index).* += 1;
        const state: *?State = self.storage.fieldMut(.state, buffer.storage_index);
        const old_state = &state.*.?;
        vma.destroyBuffer(self.gpu.allocator, old_state.handle, old_state.allocation);
        state.* = null;

        try self.freelist.push(buffer.storage_index);
    }
};

const base = @import("../base.zig");
const vk = @import("../vulkan.zig");
const vma = @import("../vma.zig");
const Gpu = @import("../Gpu.zig");

const mem = base.mem;
const math = base.math;
const debug = base.debug;

const log = base.log.scoped(.Gpu);
