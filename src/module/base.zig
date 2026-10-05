// public domain

//! A light wrapper for the Zig `std` library, with some additions useful for the realtime software domain.

const base = @This();

pub const Io = std.Io;
pub const Build = std.Build;

pub const log = std.log;
pub const fmt = std.fmt;
pub const mem = std.mem;
pub const path = std.Io.Dir.path;
pub const atomic = std.atomic;
pub const hash = std.hash;
pub const heap = std.heap;
pub const math = std.math;
pub const meta = std.meta;
pub const debug = std.debug;
pub const process = std.process;
pub const zig_builtin = std.builtin;
pub const zig_lang = std.zig;
pub const zon = std.zon;
pub const testing = std.testing;
pub const unicode = std.unicode;
pub const hash_map = std.hash_map;
pub const array_map = std.array_hash_map;
pub const time = std.time;
pub const posix = std.posix;
pub const os = std.os;
pub const sort = std.sort;

pub fn todo(comptime T: type) T {
    @panic("TODO");
}

pub const Result = enum(u64) { success = 0, _ };

pub const build_info = @import("builtin");
pub const debug_safety = build_info.mode == .Debug or build_info.mode == .ReleaseSafe;

pub const StdOptions = std.Options;
pub const SemanticVersion = std.SemanticVersion;
pub const Target = std.Target;

pub const Alignment = mem.Alignment;
pub const page_align = heap.page_size_min;
pub const page_alignment = Alignment.fromByteUnits(page_align);

pub const Signedness = zig_builtin.Signedness;
pub const Wyhash = hash.Wyhash;
pub const default_wyhash_seed = 0;
pub fn wyhash(value: []const u8) u64 {
    return Wyhash.hash(default_wyhash_seed, value);
}

pub const Arena = heap.ArenaAllocator;

pub const Pool = heap.MemoryPool;
pub const FixedBuffer = heap.FixedBufferAllocator;
pub const Allocator = mem.Allocator;
pub const ArrayList = std.ArrayListUnmanaged;
pub const MultiArrayList = std.MultiArrayList;
pub const StringMap = std.StringHashMapUnmanaged;
pub const StringArrayMap = std.StringArrayHashMapUnmanaged;
pub const ArrayMap = std.AutoArrayHashMapUnmanaged;
pub const CustomArrayMap = std.ArrayHashMapUnmanaged;
pub const HashMap = std.AutoHashMapUnmanaged;
pub const CustomHashMap = std.HashMapUnmanaged;
pub const DynamicBitSet = std.DynamicBitSetUnmanaged;
pub const StaticBitSet = std.StaticBitSet;

pub const StringArraySet = StringArrayMap(void);
pub const StringSet = StringMap(void);

pub fn ArraySet(comptime T: type) type {
    return ArrayMap(T, void);
}

pub fn CustomArraySet(comptime T: type, comptime Context: type, comptime store_hash: bool) type {
    return CustomArrayMap(T, void, Context, store_hash);
}

pub fn HashSet(comptime T: type) type {
    return HashMap(T, void);
}

pub fn CustomHashSet(comptime T: type, comptime Context: type, comptime max_load_percentage: u64) type {
    return CustomHashMap(T, void, Context, max_load_percentage);
}

pub const Layout = packed struct(u38) {
    size: u32,
    alignment: Alignment,
};

pub const kernel32 = if (build_info.target.os.tag == .windows) struct {
    pub extern "kernel32" fn VirtualAlloc(
        lpAddress: ?*anyopaque,
        dwSize: usize,
        flAllocationType: u32,
        flProtect: u32,
    ) callconv(.winapi) ?*anyopaque;

    pub extern "kernel32" fn VirtualFree(
        lpAddress: ?*anyopaque,
        dwSize: usize,
        dwFreeType: u32,
    ) callconv(.winapi) i32;

    pub extern "kernel32" fn LoadLibraryW(
        lpLibFileName: std.os.windows.LPCWSTR,
    ) callconv(.winapi) ?std.os.windows.HMODULE;

    pub extern "kernel32" fn GetProcAddress(
        hModule: std.os.windows.HMODULE,
        lpProcName: std.os.windows.LPCSTR,
    ) callconv(.winapi) ?std.os.windows.FARPROC;

    pub const MEM_COMMIT = 0x00001000;
    pub const MEM_RESERVE = 0x00002000;
    pub const MEM_RELEASE = 0x00008000;
    pub const PAGE_NOACCESS = 0x01;
    pub const PAGE_READONLY = 0x02;
    pub const PAGE_READWRITE = 0x04;
} else struct {};

pub fn map(max_size: u64) ![]align(page_align) u8 {
    if (comptime build_info.target.os.tag == .windows) {
        const ptr = kernel32.VirtualAlloc(
            null,
            max_size,
            kernel32.MEM_RESERVE,
            kernel32.PAGE_NOACCESS,
        ) orelse return error.SystemResources;

        const byte_ptr: [*]align(page_align) u8 = @ptrCast(@alignCast(ptr));
        return byte_ptr[0..max_size];
    } else return posix.mmap(
        null,
        max_size,
        .{},
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
}

pub fn unmap(buf: []align(page_align) u8) void {
    if (comptime build_info.target.os.tag == .windows) {
        _ = kernel32.VirtualFree(buf.ptr, 0, kernel32.MEM_RELEASE);
    } else return posix.munmap(buf);
}

pub fn protect(buf: []align(page_align) u8, x: process.MemoryProtection) !void {
    if (comptime build_info.target.os.tag == .windows) {
        // Map your abstract/POSIX protection flags to Win32 constants
        // (Adjust this logic depending on what type your `flags` param uses)
        const win_protect = kernel32.PAGE_READWRITE;

        // On Windows, you MUST explicitly commit the reserved space before/during protection
        // to assign physical pages to it.
        if (win_protect != kernel32.PAGE_NOACCESS) {
            _ = kernel32.VirtualAlloc(buf.ptr, buf.len, kernel32.MEM_COMMIT, win_protect) orelse return error.SystemResources;
        }
    }

    return process.protectMemory(buf, x);
}

pub const gpa = heap.smp_allocator;
pub const temp = temp_arena.allocator();

pub var temp_arena: VArena = .empty;

pub fn valloc(comptime T: type, size: u64) ![]align(page_align) T {
    const buf = try vmap(T, size);
    try vprotect(buf, 0, size);
    return buf[0..size];
}

pub fn vfree(slice: anytype) void {
    vunmap(slice.ptr, slice.len);
}

pub fn vmap(comptime T: type, max_size: u64) ![*]align(page_align) T {
    const byte_size = @sizeOf(T) * max_size;

    const byte_buffer = try map(
        base.page_alignment.forward(byte_size),
    );

    return mem.bytesAsSlice(T, byte_buffer[0..byte_size]).ptr;
}

pub fn vprotect(buf: anytype, start_index: usize, end_index: usize) !void {
    const S = @TypeOf(buf);
    const T = @typeInfo(S).pointer.child;
    const bytes: [*]u8 = @ptrCast(buf);
    const x = page_alignment.backward(start_index * @sizeOf(T));
    const y = page_alignment.forward(end_index * @sizeOf(T));

    try protect(
        @alignCast(bytes[x..y]),
        .{
            .read = true,
            .write = true,
        },
    );
}

pub fn vunmap(buf: anytype, max_size: u64) void {
    const S = @TypeOf(buf);
    const T = @typeInfo(S).pointer.child;
    const bytes: [*]u8 = @ptrCast(buf);
    const byte_size = max_size * @sizeOf(T);
    unmap(@alignCast(bytes[0..page_alignment.forward(byte_size)]));
}

pub fn concat(comptime T: type, allocator: Allocator, slice_of_slices: []const []const T) ![]T {
    var total_len: u64 = 0;
    for (slice_of_slices) |slice| total_len += slice.len;
    const out = try allocator.alloc(T, total_len);
    total_len = 0;
    for (slice_of_slices) |slice| {
        @memcpy(out[total_len .. total_len + slice.len], slice);
        total_len += slice.len;
    }
    return out;
}

pub const VArena = CustomVArena(math.maxInt(u32), math.maxInt(u16));

pub fn CustomVArena(comptime max_capacity: comptime_int, comptime initial_capacity: comptime_int) type {
    return struct {
        mapped_memory: ?[*]align(page_align) u8 = null,
        capacity: u64 = 0,
        count: u64 = 0,

        pub const empty = Self{};

        pub fn initCapacity(cap: u64) !Self {
            var self = empty;
            try self.ensureCapacity(cap);
            return self;
        }

        pub fn deinit(self: *Self) void {
            if (self.mapped_memory) |m| unmap(m[0..total_mapped_size]);
        }

        pub fn reset(self: *Self) void {
            self.count = 0;
        }

        pub fn ensureCapacity(self: *Self, req_cap: u64) !void {
            if (req_cap <= self.capacity) return;

            if (req_cap > max_capacity) return error.OutOfMemory;

            var new_cap = @max(self.capacity, initial_capacity);
            while (new_cap <= req_cap) new_cap *= 2;

            if (self.mapped_memory == null) {
                @branchHint(.unlikely);

                self.mapped_memory = (map(total_mapped_size) catch return error.OutOfMemory).ptr;
            }

            const old_byte_cap = self.capacity;
            const new_byte_cap = page_alignment.forward(new_cap);

            try protect(
                @alignCast(self.mapped_memory.?[old_byte_cap..new_byte_cap]),
                .{
                    .read = true,
                    .write = true,
                },
            );

            self.capacity = new_byte_cap;
        }

        pub fn allocRaw(self: *Self, size: u64, alignment: Alignment) ![]u8 {
            const offset = alignment.forward(self.count);
            const total = offset + size;

            try self.ensureCapacity(total);
            self.count = total;

            return self.mapped_memory.?[offset..total];
        }

        pub fn alloc(self: *Self, comptime T: type, n: u64) ![]T {
            const bytes = try self.allocRaw(@sizeOf(T) * n, Alignment.of(T));
            return @alignCast(mem.bytesAsSlice(T, bytes));
        }

        pub fn allocator(self: *Self) Allocator {
            return .{
                .ptr = self,
                .vtable = comptime &Allocator.VTable{
                    .alloc = &struct {
                        pub fn varena_zig_callback(
                            ptr: *anyopaque,
                            size: usize,
                            alignment: Alignment,
                            ret_addr: usize,
                        ) ?[*]u8 {
                            _ = ret_addr;
                            return (@as(*Self, @ptrCast(@alignCast(ptr))).allocRaw(size, alignment) catch return null).ptr;
                        }
                    }.varena_zig_callback,
                    .resize = &Allocator.noResize,
                    .remap = &Allocator.noRemap,
                    .free = &Allocator.noFree,
                },
            };
        }

        const Self = @This();
        const initial_protected_size = page_alignment.forward(initial_capacity);
        const total_mapped_size = page_alignment.forward(max_capacity);
    };
}

test VArena {
    var arena = VArena.empty;
    defer arena.deinit();

    var cells: [1024]*u32 = undefined;
    for (0..1024) |_| {
        for (try arena.alloc(u32, 1024), 0..) |*cell, i| {
            cell.* = @intCast(i);
            cells[i] = cell;
        }

        for (0..1024) |i| try testing.expectEqual(@as(u32, @intCast(i)), cells[i].*);
    }

    const concatenated = try base.concat(u32, temp, &.{
        &.{ 1, 2, 3 },
        &.{ 4, 5, 6 },
        &.{ 7, 8, 9 },
    });

    try testing.expectEqualSlices(
        u32,
        &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        concatenated,
    );
}

test "VArena pointer overlap" {
    var arena = VArena.empty;
    defer arena.deinit();

    const ptr1 = try arena.alloc(u32, 1);
    const ptr2 = try arena.alloc(u32, 1);

    ptr1[0] = 123;
    ptr2[0] = 456;

    try testing.expectEqual(@as(u32, 123), ptr1[0]);
}

pub const varray_default_initial_capacity = 1024;

pub fn VArray(comptime T: type) type {
    return CustomVArray(
        T,
        u64,
        math.maxInt(u32),
        varray_default_initial_capacity,
    );
}

pub fn CustomVArray(comptime T: type, comptime I: type, comptime max_capacity: I, comptime initial_capacity: I) type {
    return struct {
        mapped_memory: ?[*]align(page_align) u8 = null,
        capacity: I = 0,
        count: I = 0,

        pub const empty = Self{};

        const Self = @This();
        const total_mapped_size = page_alignment.forward(@sizeOf(T) * max_capacity);

        pub fn initCapacity(cap: I) !Self {
            var self = empty;
            try self.ensureCapacity(cap);
            return self;
        }

        pub fn deinit(self: *Self) void {
            if (self.mapped_memory) |m| unmap(m[0..total_mapped_size]);
        }

        pub fn ensureCapacity(self: *Self, req_cap: I) !void {
            if (req_cap <= self.capacity) return;

            if (req_cap > max_capacity) return error.OutOfMemory;

            var new_cap = @max(self.capacity, initial_capacity);
            while (new_cap <= req_cap) new_cap *= 2;

            if (self.mapped_memory == null) {
                @branchHint(.unlikely);

                self.mapped_memory = (map(total_mapped_size) catch return error.OutOfMemory).ptr;
            }

            const old_byte_cap = page_alignment.forward(self.capacity * @sizeOf(T));
            const new_byte_cap = page_alignment.forward(new_cap * @sizeOf(T));

            self.capacity = new_cap;

            protect(
                @alignCast(self.mapped_memory.?[old_byte_cap..new_byte_cap]),
                .{
                    .read = true,
                    .write = true,
                },
            ) catch return error.OutOfMemory;
        }

        pub fn addSlots(self: *Self, index: I, count: I) !void {
            if (count == 0) {
                @branchHint(.unlikely);
                return;
            }

            debug.assert(index <= self.count);
            debug.assert(self.count + count <= max_capacity);

            try self.ensureCapacity(self.count + count);
            const old_count = self.count;
            self.count += count;

            if (index == old_count) {
                // NOTE: The actual likeliness is debatable but we want to prioritize this case for efficiency in push-like conditions
                @branchHint(.likely);
                return;
            }

            @memmove(
                self.bufferMut()[index + count .. self.count + count],
                self.bufferMut()[index..],
            );
        }

        pub fn delSlots(self: *Self, index: I, count: I) void {
            if (count == 0) {
                @branchHint(.unlikely);
                return;
            }

            debug.assert(index <= self.count);
            debug.assert(index + count <= self.count);

            const old_count = self.count;
            self.count -= count;

            if (self.count == index) {
                // NOTE: The actual likeliness is debatable but we want to prioritize this case for efficiency in pop-like conditions
                @branchHint(.likely);
                return;
            }

            @memmove(
                self.bufferMut()[index..self.count],
                self.bufferMut()[index + count .. old_count],
            );
        }

        pub fn insert(self: *Self, index: I, value: T) !void {
            try self.addSlots(index, 1);
            self.sliceMut()[index] = value;
        }

        pub fn insertSlice(self: *Self, index: I, values: []const T) !void {
            try self.addSlots(index, @intCast(values.len));
            @memcpy(self.sliceMut()[index .. index + values.len], values);
        }

        pub fn push(self: *Self, value: T) !void {
            try self.insert(self.count, value);
        }

        pub fn pushSlice(self: *Self, values: []const T) !void {
            try self.insertSlice(self.count, values);
        }

        pub fn remove(self: *Self, index: I) T {
            const out = self.slice()[index];
            self.delSlots(index, 1);
            return out;
        }

        pub fn pop(self: *Self) T {
            debug.assert(self.count > 0);

            self.count -= 1;

            return self.bufferMut()[self.count];
        }
        pub const Dest = union(enum) {
            count_to_remove: I,
            output_slice: []T,

            // zig fmt: off
            pub fn count(i: I) Dest { return .{ .count_to_remove = i }; }
            pub fn take(i: []T) Dest { return .{ .output_slice = i }; }
            pub fn getLen(self: *Dest) I { return switch(self.*) { .count_to_remove => |i| i, .output_slice => |xs| @intCast(xs.len), }; }
            pub fn asSlice(self: *Dest) ?[]T { return switch (self.*) { .output_slice => |xs| xs, else => null }; }
            // zig fmt: on
        };

        pub fn removeSlice(self: *Self, index: I, dest: Dest) void {
            debug.assert(dest.getLen() > self.count);
            if (dest.asSlice()) |output_slice| {
                @memcpy(output_slice, self.slice()[index .. index + output_slice.len]);
            }
            self.delSlots(index, dest.getLen());
        }

        pub fn popSlice(self: *Self, dest: Dest) void {
            if (dest.getLen == 0) return;
            self.removeSlice(self.count - 1, dest);
        }

        pub fn bufferMut(self: *Self) [*]T {
            return @ptrCast(self.mapped_memory);
        }

        pub fn buffer(self: *const Self) [*]const T {
            return bufferMut(@constCast(self));
        }

        pub fn sliceMut(self: *Self) []T {
            if (self.mapped_memory != null) {
                @branchHint(.likely);
                return self.bufferMut()[0..self.count];
            }

            return &.{};
        }

        pub fn slice(self: *const Self) []const T {
            return sliceMut(@constCast(self));
        }

        pub fn get(self: *const Self, index: I) T {
            return self.slice()[index];
        }

        pub fn getPtr(self: *Self, index: I) *T {
            return &self.sliceMut()[index];
        }

        pub fn isMapped(self: *Self) bool {
            return self.mapped_memory != null;
        }

        pub fn isEmpty(self: *Self) bool {
            return self.count == 0;
        }

        pub fn isFull(self: *Self) bool {
            return self.count >= max_capacity;
        }

        pub fn totalCapacityRemaining(self: *Self) I {
            return max_capacity - self.count;
        }

        pub fn canContain(self: *Self, count: I) bool {
            return self.totalCapacityRemaining() >= count;
        }
    };
}

test VArray {
    var arr = VArray(u32).empty;
    defer arr.deinit();

    var i: u32 = 0;
    while (i < 2048) : (i += 1) {
        try arr.push(i);
    }

    try testing.expectEqual(2048, arr.count);
    try testing.expectEqual(2048, arr.capacity);
    try testing.expectEqual(10, arr.remove(10));
    try testing.expectEqual(11, arr.get(10));
    try testing.expectEqual(9, arr.slice()[9]);
    try testing.expectEqual(2047, arr.pop());
    try testing.expectEqual(2046, arr.count);
    try testing.expectEqual(2048, arr.capacity);

    try arr.insertSlice(10, &.{ 3, 2, 1 });

    try testing.expectEqual(2049, arr.count);
    try testing.expectEqual(4096, arr.capacity);
    try testing.expectEqual(3, arr.get(10));
    try testing.expectEqual(2, arr.get(11));
    try testing.expectEqual(1, arr.get(12));
    try testing.expectEqual(11, arr.get(13));
}

pub fn VMultiArray(comptime Table: type) type {
    return CustomVMultiArray(Table, u64, math.maxInt(u32), varray_default_initial_capacity);
}

pub fn CustomVMultiArray(comptime Table: type, comptime I: type, comptime max_capacity: I, comptime initial_capacity: I) type {
    return struct {
        mapped_memories: ?[*]align(page_align) [*]align(page_align) u8 = null,
        capacity: I = 0,
        count: I = 0,

        pub const empty = Self{};

        const Self = @This();
        const Items = meta.FieldEnum(Table);
        const total_mapped_sizes = map_sizes: {
            const field_names = meta.fieldNames(Table);
            var sizes: [field_names.len]comptime_int = undefined;
            for (field_names, 0..) |field_name, item_index| {
                const T = @FieldType(Table, field_name);
                sizes[item_index] = page_alignment.forward(@sizeOf(T) * max_capacity);
            }
            break :map_sizes sizes;
        };

        pub fn initCapacity(cap: I) Self {
            var self = empty;
            self.ensureCapacity(cap);
            return self;
        }

        pub fn deinit(self: *Self) void {
            if (self.mapped_memories) |mapped_memories| {
                @branchHint(.likely);

                inline for (mapped_memories, 0..total_mapped_sizes.len) |mapped_memory, item_index| {
                    unmap(mapped_memory[0..total_mapped_sizes[item_index]]);
                }
            }
        }

        pub fn ensureCapacity(self: *Self, req_cap: I) !void {
            if (req_cap <= self.capacity) return;

            var new_cap = @max(self.capacity, initial_capacity);
            while (new_cap <= req_cap) new_cap *= 2;

            if (self.mapped_memories == null) {
                @branchHint(.unlikely);

                self.mapped_memories =
                    (valloc([*]align(page_align) u8, total_mapped_sizes.len) catch
                        return error.OutOfMemory).ptr;

                inline for (0..total_mapped_sizes.len) |item_index| {
                    self.mapped_memories.?[item_index] = (map(total_mapped_sizes[item_index]) catch |err| norecover(
                        err,
                        .cpu_memory,
                        "mmap failure indicates hostile operating system state",
                    )).ptr;
                }
            }

            inline for (comptime meta.fieldNames(Table), 0..) |field_name, item_index| {
                const item_byte_size = @sizeOf(@FieldType(Table, field_name));
                const old_byte_cap = page_alignment.forward(self.capacity * item_byte_size);
                const new_byte_cap = page_alignment.forward(new_cap * item_byte_size);

                protect(
                    @alignCast(self.mapped_memories.?[item_index][old_byte_cap..new_byte_cap]),
                    .{
                        .read = true,
                        .write = true,
                    },
                ) catch return error.OutOfMemory;
            }

            self.capacity = new_cap;
        }

        pub fn addSlots(self: *Self, index: I, count: I) !void {
            if (count == 0) {
                @branchHint(.unlikely);
                return;
            }

            debug.assert(index <= self.count);
            debug.assert(self.count + count <= max_capacity);

            try self.ensureCapacity(self.count + count);
            const old_count = self.count;
            self.count += count;

            if (index == old_count) {
                // NOTE: The actual likeliness is debatable but we want to prioritize this case for efficiency in push-like conditions
                @branchHint(.likely);
                return;
            }

            inline for (comptime meta.fieldNames(Table)) |field_name| {
                const item = @field(Items, field_name);
                @memmove(
                    self.bufferMut(item)[index + count .. self.count + count],
                    self.bufferMut(item)[index..],
                );
            }
        }

        pub fn delSlots(self: *Self, index: I, count: I) void {
            if (count == 0) {
                @branchHint(.unlikely);
                return;
            }

            debug.assert(index <= self.count);
            debug.assert(index + count <= self.count);

            const old_count = self.count;
            self.count -= count;

            if (self.count == index) {
                // NOTE: The actual likeliness is debatable but we want to prioritize this case for efficiency in pop-like conditions
                @branchHint(.likely);
                return;
            }

            inline for (comptime meta.fieldNames(Table)) |field_name| {
                const item = @field(Items, field_name);
                @memmove(
                    self.bufferMut(item)[index..self.count],
                    self.bufferMut(item)[index + count .. old_count],
                );
            }
        }

        pub fn insert(self: *Self, index: I, value: Table) !void {
            try self.addSlots(index, 1);
            inline for (comptime meta.fieldNames(Table)) |field_name| {
                const item = @field(Items, field_name);
                self.sliceMut(item)[index] = @field(value, field_name);
            }
        }

        pub fn push(self: *Self, value: Table) !void {
            try self.insert(self.count, value);
        }

        pub fn remove(self: *Self, index: I) Table {
            var out: Table = undefined;
            inline for (comptime meta.fieldNames(Table)) |field_name| {
                const item = @field(Items, field_name);
                @field(out, field_name) = self.bufferMut(item)[index];
            }
            self.delSlots(index, 1);
            return out;
        }

        pub fn pop(self: *Self) Table {
            debug.assert(self.count > 0);

            self.count -= 1;

            var out: Table = undefined;
            inline for (comptime meta.fieldNames(Table)) |field_name| {
                const item = @field(Items, field_name);
                @field(out, field_name) = self.bufferMut(item)[self.count];
            }
            return out;
        }

        pub fn insertSlice(self: *Self, index: I, values: []const Table) !void {
            try self.addSlots(index, @intCast(values.len));

            inline for (comptime meta.fieldNames(Table)) |field_name| {
                const item = @field(Items, field_name);
                const items = self.sliceMut(item)[index .. index + values.len];
                for (values, 0..) |elem, local_index| {
                    items[local_index] = @field(elem, field_name);
                }
            }
        }

        pub fn pushSlice(self: *Self, values: []const Table) !void {
            try self.insertSlice(self.count, values);
        }

        pub const Dest = union(enum) {
            count_to_remove: I,
            output_slice: []Table,

            // zig fmt: off
            pub fn count(i: I) Dest { return .{ .count_to_remove = i }; }
            pub fn take(i: []Table) Dest { return .{ .output_slice = i }; }
            pub fn getLen(self: *Dest) I { return switch(self.*) { .count_to_remove => |i| i, .output_slice => |xs| @intCast(xs.len), }; }
            pub fn asSlice(self: *Dest) ?[]Table { return switch (self.*) { .output_slice => |xs| xs, else => null }; }
            // zig fmt: on
        };

        pub fn removeSlice(self: *Self, index: I, dest: Dest) void {
            debug.assert(dest.getLen() > self.count);
            if (dest.asSlice()) |output_slice| {
                inline for (comptime meta.fieldNames(Table)) |field_name| {
                    const item = @field(Items, field_name);
                    const items = self.sliceMut(item)[index .. index + output_slice.len];
                    for (output_slice.len, 0..) |*elem, local_index| {
                        @field(elem, field_name) = items[local_index];
                    }
                }
            }
            self.delSlots(index, dest.getLen());
        }

        pub fn popSlice(self: *Self, dest: Dest) void {
            if (dest.getLen == 0) return;
            self.removeSlice(self.count - 1, dest);
        }

        pub fn bufferMut(self: *Self, comptime name: Items) [*]@FieldType(Table, @tagName(name)) {
            return @ptrCast(self.mapped_memories.?[@backingInt(name)]);
        }

        pub fn buffer(self: *const Self, comptime name: Items) [*]const @FieldType(Table, @tagName(name)) {
            return bufferMut(@constCast(self), name);
        }

        pub fn sliceMut(self: *Self, comptime name: Items) []@FieldType(Table, @tagName(name)) {
            if (self.mapped_memories != null) {
                @branchHint(.likely);
                return self.bufferMut(name)[0..self.count];
            }

            return &.{};
        }

        pub fn slice(self: *const Self, comptime name: Items) []const @FieldType(Table, @tagName(name)) {
            return sliceMut(@constCast(self), name);
        }

        pub fn get(self: *const Self, index: I) Table {
            var out: Table = undefined;
            inline for (comptime meta.fieldNames(Table)) |field_name| {
                const item = @field(Items, field_name);
                @field(out, field_name) = self.buffer(item)[index];
            }
            return out;
        }

        pub fn field(self: *const Self, comptime name: Items, index: I) @FieldType(Table, @tagName(name)) {
            return self.slice(name)[index];
        }

        pub fn fieldPtr(self: *const Self, comptime name: Items, index: I) *const @FieldType(Table, @tagName(name)) {
            return &self.slice(name)[index];
        }

        pub fn fieldMut(self: *Self, comptime name: Items, index: I) *@FieldType(Table, @tagName(name)) {
            return &self.sliceMut(name)[index];
        }

        pub fn isMapped(self: *Self) bool {
            return self.mapped_memories != null;
        }

        pub fn isEmpty(self: *Self) bool {
            return self.count == 0;
        }

        pub fn isFull(self: *Self) bool {
            return self.count >= max_capacity;
        }

        pub fn totalCapacityRemaining(self: *Self) I {
            return max_capacity - self.count;
        }

        pub fn canContain(self: *Self, count: I) bool {
            return self.totalCapacityRemaining() >= count;
        }
    };
}

test VMultiArray {
    const V2 = struct {
        x: u32,
        y: u32,
        pub fn exp(x: u32) @This() {
            return .{ .x = x, .y = x * 2 };
        }
    };
    var arr = VMultiArray(V2).empty;
    defer arr.deinit();

    var i: u32 = 0;
    while (i < 2048) : (i += 1) {
        try arr.push(V2.exp(i));
    }

    try testing.expectEqual(2048, arr.count);
    try testing.expectEqual(2048, arr.capacity);
    try testing.expectEqual(V2.exp(10), arr.remove(10));
    try testing.expectEqual(V2.exp(11), arr.get(10));
    try testing.expectEqual(9, arr.slice(.x)[9]);
    try testing.expectEqual(V2.exp(2047), arr.pop());
    try testing.expectEqual(2046, arr.count);
    try testing.expectEqual(2048, arr.capacity);

    try arr.insertSlice(10, &.{ V2.exp(3), V2.exp(2), V2.exp(1) });

    try testing.expectEqual(2049, arr.count);
    try testing.expectEqual(4096, arr.capacity);
    try testing.expectEqual(V2.exp(3), arr.get(10));
    try testing.expectEqual(V2.exp(2), arr.get(11));
    try testing.expectEqual(V2.exp(1), arr.get(12));
    try testing.expectEqual(V2.exp(11), arr.get(13));
}

pub const NoRecoverReason = enum {
    unexpected,
    cpu_memory,
    gpu_driver,
    gpu_memory,
};

pub inline fn assert_norecover(cond: bool, err: anyerror, reason: NoRecoverReason, msg: []const u8) void {
    if (!cond) norecover(err, reason, msg);
}

pub inline fn norecover(err: anyerror, reason: NoRecoverReason, msg: []const u8) noreturn {
    @branchHint(.cold);
    debug.panic("Encountered {s} error, {s}: {any}; this situation is not recoverable.", .{ @tagName(reason), msg, err });
}

pub fn binarySearch(comptime T: type, context: anytype, items: []const T, callback: fn (ctx: @TypeOf(context), value: *const T) math.Order) struct { bool, u64 } {
    var low: u64 = 0;
    var high: u64 = items.len;
    var found_exact = false;

    while (low < high) {
        const mid = low + (high - low) / 2;
        switch (callback(context, &items[mid])) {
            .eq => {
                found_exact = true;
                low = mid;
                break;
            },
            .gt => low = mid + 1,
            .lt => high = mid,
        }
    }

    return .{ found_exact, low };
}

pub fn isSentinel(value: anytype) bool {
    return sentinel(@TypeOf(value)) == value;
}

pub fn sentinel(comptime T: type) T {
    return math.maxInt(T);
}

const std = @import("std");
