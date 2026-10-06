pub const Image = packed struct(u64) {
    storage_index: u32,
    generation: u32,

    pub fn init(gpu: *Gpu, width: u32, height: u32) !Image {
        return initAdvanced(
            gpu,
            width,
            height,
            .r8g8b8a8_unorm,
            .{
                .transfer_dst = true,
                .sampled = true,
                .color_attachment = true,
            },
            .{ .device_local = true },
        );
    }

    pub fn initAdvanced(
        gpu: *Gpu,
        width: u32,
        height: u32,
        format: vk.Format,
        usage: vk.ImageUsageFlags,
        flags: vk.MemoryPropertyFlags,
    ) !Image {
        return gpu.store.image.create(
            width,
            height,
            format,
            usage,
            flags,
        );
    }

    pub fn deinit(image: Image, gpu: *Gpu) void {
        gpu.store.image.destroy(image) catch |err| {
            log.err("memory leak: failed to properly free image {any} ({s})", .{ image, @errorName(err) });
        };
    }

    pub fn getIndex(self: Image) u32 {
        return self.storage_index;
    }

    pub fn getHandle(self: Image, gpu: *Gpu) vk.Image {
        return gpu.store.image.storage.fieldPtr(.state, self.storage_index).*.?.handle;
    }
};

pub const Data = struct {
    generation: u32 = 0,
    state: ?State = null,
    width: u32 = 0,
    height: u32 = 0,
    format: vk.Format = .undefined,
};

pub const State = struct {
    handle: vk.Image,
    view: Gpu.ImageView,
    layout: vk.ImageLayout,
    allocation: *vma.Allocation,
};

pub const Store = struct {
    gpu: *Gpu,
    storage: base.VMultiArray(Data) = .empty,
    freelist: base.VArray(u32) = .empty,

    pub const max_capacity = math.maxInt(u16);

    pub fn init(gpu: *Gpu) !*Store {
        const self = try base.gpa.create(Store);

        self.* = .{ .gpu = gpu };

        return self;
    }

    pub fn deinit(self: *Store) void {
        for (0..self.storage.count) |storage_index| {
            if (self.storage.fieldPtr(.state, storage_index).*) |*state| {
                self.gpu.device.proxy.destroyImageView(state.view, null);
                vma.destroyImage(self.gpu.allocator, state.handle, state.allocation);
            }
        }

        self.storage.deinit();
        self.freelist.deinit();

        base.gpa.destroy(self);
    }

    pub fn create(
        self: *Store,
        width: u32,
        height: u32,
        format: vk.Format,
        usage: vk.ImageUsageFlags,
        flags: vk.MemoryPropertyFlags,
    ) !Image {
        const storage_index = storage_index: {
            if (self.freelist.isEmpty()) {
                const index = self.storage.count;
                if (index >= self.gpu.max_images) return error.OutOfMemory;

                try self.storage.push(Data{});

                break :storage_index index;
            } else {
                break :storage_index self.freelist.pop();
            }
        };

        const state: *?State = self.storage.fieldMut(.state, storage_index);

        debug.assert(state.* == null);

        self.storage.fieldMut(.width, storage_index).* = width;
        self.storage.fieldMut(.height, storage_index).* = height;
        self.storage.fieldMut(.format, storage_index).* = format;

        const result = vma.createImage(self.gpu.allocator, .{
            .image_type = .@"2d",
            .format = format,
            .extent = .{ .width = width, .height = height, .depth = 1 },
            .mip_levels = 1,
            .array_layers = 1,
            .samples = .{ .@"1" = true },
            .tiling = .optimal,
            .usage = usage,
            .sharing_mode = .exclusive,
            .initial_layout = .undefined,
        }, .{
            .usage = .auto,
            .requiredFlags = flags,
        }) catch {
            log.err("Failed to allocate image", .{});
            return error.OutOfMemory;
        };

        const view = try self.gpu.device.proxy.createImageView(&.{
            .image = result.image,
            .view_type = .@"2d",
            .format = format,
            .components = .{
                .r = .identity,
                .g = .identity,
                .b = .identity,
                .a = .identity,
            },
            .subresource_range = .{
                .aspect_mask = .{ .color = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
        }, null);
        errdefer self.gpu.device.proxy.destroyImageView(view, null);

        const image_info = vk.DescriptorImageInfo{
            .sampler = .null_handle,
            .image_view = view,
            .image_layout = .shader_read_only_optimal, // What it will be after sync
        };

        const write = vk.WriteDescriptorSet{
            .dst_set = self.gpu.descriptor_set,
            .dst_binding = 0,
            .dst_array_element = @intCast(storage_index),
            .descriptor_count = 1,
            .descriptor_type = .sampled_image,
            .p_image_info = @ptrCast(&image_info),
            .p_buffer_info = undefined,
            .p_texel_buffer_view = undefined,
        };
        self.gpu.device.proxy.updateDescriptorSets(&.{write}, null);

        state.* = .{
            .handle = result.image,
            .view = view,
            .allocation = result.allocation,
            .layout = .undefined,
        };

        return Image{
            .storage_index = @intCast(storage_index),
            .generation = self.storage.field(.generation, storage_index),
        };
    }

    pub fn destroy(self: *Store, image: Image) !void {
        if (image.storage_index >= self.storage.count) {
            @branchHint(.cold);
            return error.UseAfterFree;
        }

        if (image.generation != self.storage.field(.generation, image.storage_index)) {
            @branchHint(.cold);
            return error.UseAfterFree;
        }

        self.storage.fieldMut(.generation, image.storage_index).* += 1;
        const state: *?State = self.storage.fieldMut(.state, image.storage_index);
        const old_state = &state.*.?;

        self.gpu.device.proxy.destroyImageView(old_state.view, null);
        vma.destroyImage(self.gpu.allocator, old_state.handle, old_state.allocation);

        state.* = null;

        try self.freelist.push(image.storage_index);
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
