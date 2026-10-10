const StagingBuffer = @This();

managed_buffer: Gpu.Buffer,
ptr: [*]u8,
offset: u64,
capacity: u64,

pub fn init(gpu: *Gpu, capacity: u32) !StagingBuffer {
    var self: StagingBuffer = undefined;

    self.offset = 0;
    self.capacity = capacity;

    self.managed_buffer = try Gpu.Buffer.initAdvanced(
        gpu,
        capacity,
        .{ .transfer_src = true },
        .{ .host_visible = true, .host_coherent = true },
    );
    errdefer self.managed_buffer.deinit(gpu);

    const alloc_info = self.managed_buffer.getAllocationInfo(gpu);
    self.ptr = @ptrCast(alloc_info.pMappedData.?);

    return self;
}

pub fn deinit(self: *StagingBuffer, gpu: *Gpu) void {
    self.managed_buffer.deinit(gpu);
    self.* = undefined;
}

pub fn reset(self: *StagingBuffer) void {
    self.offset = 0;
}

pub fn push(self: *StagingBuffer, bytes: []const u8) ![]const u8 {
    const a = self.offset;
    if (a + bytes.len > self.capacity) return error.OutOfMemory;
    self.offset += bytes.len;
    const buf = self.ptr[a..self.offset];
    @memcpy(buf, bytes);
    return buf;
}

const Gpu = @import("../Gpu.zig");
