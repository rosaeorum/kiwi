const CommandBuffer = @This();

// TODO: Implement an automatic fallback that issues a vkCmdPipelineBarrier,
// submits the current command buffer, waits for it, resets the staging offset, and
// resumes recording. This would allow us to handle big asset uploads transparently.

gpu: *Gpu,
handle: vk.CommandBuffer,
staging: Gpu.StagingBuffer,

area: ?vk.Rect2D,
pipeline: ?struct { state: *Gpu.Pipeline, push_constant_index: u32 = 0 },

wait_semas: base.ArrayList(vk.Semaphore),
signal_semas: base.ArrayList(vk.Semaphore),
image_barriers: base.ArrayMap(Gpu.Image, vk.ImageMemoryBarrier),

in_flight_fence: vk.Fence,

flushed: bool,

pub fn init(gpu: *Gpu) !CommandBuffer {
    var self: CommandBuffer = undefined;
    self.gpu = gpu;
    self.flushed = false;

    try self.gpu.device.proxy.allocateCommandBuffers(
        &.{
            .command_pool = self.gpu.command_pool,
            .level = .primary,
            .command_buffer_count = 1,
        },
        @ptrCast(&self.handle),
    );
    errdefer self.gpu.device.proxy.freeCommandBuffers(self.gpu.command_pool, &.{self.handle});

    self.staging = try Gpu.StagingBuffer.init(
        self.gpu,
        (@import("static_config").gpu_staging_capacity * 1024 * 1024),
    );
    errdefer self.staging.deinit(self.gpu);

    self.area = null;
    self.pipeline = null;

    self.wait_semas = try .initCapacity(base.gpa, 4096);
    errdefer self.wait_semas.deinit(base.gpa);

    self.signal_semas = try .initCapacity(base.gpa, 4096);
    errdefer self.signal_semas.deinit(base.gpa);

    self.image_barriers = .empty;
    try self.image_barriers.ensureTotalCapacity(base.gpa, 4096);
    errdefer self.image_barriers.deinit(base.gpa);

    self.in_flight_fence = try self.gpu.device.proxy.createFence(
        &.{ .flags = .{ .signaled = true } },
        null,
    );

    return self;
}

pub fn deinit(self: *CommandBuffer) void {
    self.wait_semas.deinit(base.gpa);
    self.signal_semas.deinit(base.gpa);
    self.image_barriers.deinit(base.gpa);
    self.gpu.device.proxy.destroyFence(self.in_flight_fence, null);

    self.gpu.device.proxy.freeCommandBuffers(self.gpu.command_pool, &.{self.handle});
    self.staging.deinit(self.gpu);
}

pub fn reset(self: *CommandBuffer) !void {
    _ = try self.gpu.device.proxy.waitForFences(
        &.{self.in_flight_fence},
        .true,
        base.math.maxInt(u64),
    );
    try self.gpu.device.proxy.resetFences(&.{self.in_flight_fence});

    self.wait_semas.clearRetainingCapacity();
    self.signal_semas.clearRetainingCapacity();

    try self.gpu.device.proxy.resetCommandBuffer(self.handle, .{});
    try self.gpu.device.proxy.beginCommandBuffer(self.handle, &.{});
    self.staging.reset();

    self.flushed = false;
}

pub fn submit(self: *CommandBuffer) void {
    self.flush();

    self.gpu.device.proxy.endCommandBuffer(self.handle) catch |err| {
        log.err("Failed to submit commandbuffer: {s}", .{@errorName(err)});
        return;
    };

    const wait_stages = base.temp.alloc(vk.PipelineStageFlags, self.wait_semas.items.len) catch |err| {
        log.err("Failed to submit commandbuffer: {s}", .{@errorName(err)});
        return;
    };
    for (wait_stages) |*stage| stage.* = .{ .color_attachment_output = true };

    self.gpu.device.proxy.queueSubmit(
        self.gpu.device.graphics_queue.handle,
        &[_]vk.SubmitInfo{.{
            .wait_semaphore_count = @intCast(self.wait_semas.items.len),
            .p_wait_semaphores = self.wait_semas.items.ptr,
            .p_wait_dst_stage_mask = wait_stages.ptr,
            .command_buffer_count = 1,
            .p_command_buffers = &.{self.handle},
            .signal_semaphore_count = @intCast(self.signal_semas.items.len),
            .p_signal_semaphores = self.signal_semas.items.ptr,
        }},
        self.in_flight_fence,
    ) catch |err| {
        log.err("Failed to submit commandbuffer: {s}", .{@errorName(err)});
        return;
    };
}

pub fn setViewports(self: *CommandBuffer, viewports: []const vk.Viewport) void {
    self.gpu.device.proxy.cmdSetViewport(self.handle, 0, viewports);
}

pub fn setViewport(self: *CommandBuffer, viewport: vk.Viewport) void {
    self.gpu.device.proxy.cmdSetViewport(self.handle, 0, &.{viewport});
}

pub fn setScissors(self: *CommandBuffer, scissors: []const vk.Rect2D) void {
    self.gpu.device.proxy.cmdSetScissor(self.handle, 0, scissors);
}

pub fn setScissor(self: *CommandBuffer, scissor: vk.Rect2D) void {
    self.gpu.device.proxy.cmdSetScissor(self.handle, 0, &.{scissor});
}

pub fn transitionImageLayout(
    self: *CommandBuffer,
    image: vk.Image,
    old_layout: vk.ImageLayout,
    new_layout: vk.ImageLayout,
    src_stage: vk.PipelineStageFlags,
    src_access: vk.AccessFlags,
    dst_stage: vk.PipelineStageFlags,
    dst_access: vk.AccessFlags,
) void {
    const barrier = vk.ImageMemoryBarrier{
        .src_access_mask = src_access,
        .dst_access_mask = dst_access,
        .old_layout = old_layout,
        .new_layout = new_layout,
        .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
        .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
        .image = image,
        .subresource_range = .{
            .aspect_mask = .{ .color = true }, // TODO: Extend for depth buffers
            .base_mip_level = 0,
            .level_count = 1,
            .base_array_layer = 0,
            .layer_count = 1,
        },
    };

    self.gpu.device.proxy.cmdPipelineBarrier(
        self.handle,
        src_stage,
        dst_stage,
        .{},
        null,
        null,
        &.{barrier},
    );
}

pub fn beginRendering(
    self: *CommandBuffer,
    color_view: ?Gpu.ImageView,
    depth_view: ?Gpu.ImageView,
    area: vk.Rect2D,
    clear_color: ?linalg.vec4,
    clear_depth_stencil: ?vk.ClearDepthStencilValue,
) void {
    debug.assert(self.area == null);

    self.flush();

    var color_attachment = if (color_view) |cv| vk.RenderingAttachmentInfo{
        .image_view = cv,
        .image_layout = .color_attachment_optimal,
        .resolve_mode = .{},
        .resolve_image_view = .null_handle,
        .resolve_image_layout = .undefined,
        .load_op = if (clear_color != null) .clear else .load,
        .store_op = .store,
        .clear_value = if (clear_color) |c|
            .{ .color = .{ .float_32 = linalg.arrayVectorSwap(c) } }
        else
            undefined,
    } else undefined;

    var depth_attachment = if (depth_view) |dv| vk.RenderingAttachmentInfo{
        .image_view = dv,
        .image_layout = .depth_stencil_attachment_optimal,
        .resolve_mode = .{},
        .resolve_image_view = .null_handle,
        .resolve_image_layout = .undefined,
        .load_op = if (clear_depth_stencil != null) .clear else .load,
        .store_op = .store,
        .clear_value = if (clear_depth_stencil) |c|
            .{ .depth_stencil = c }
        else
            undefined,
    } else undefined;

    const rendering_info = vk.RenderingInfo{
        .flags = .{},
        .render_area = area,
        .layer_count = 1,
        .view_mask = 0,
        .color_attachment_count = if (color_view != null) 1 else 0,
        .p_color_attachments = if (color_view != null)
            @ptrCast(&color_attachment)
        else
            null,
        .p_depth_attachment = if (depth_view != null)
            @ptrCast(&depth_attachment)
        else
            null,
        .p_stencil_attachment = null,
    };

    self.gpu.device.proxy.cmdBeginRendering(self.handle, &rendering_info);
    self.area = area;
}

pub fn endRendering(self: *CommandBuffer) void {
    debug.assert(self.area != null);
    self.gpu.device.proxy.cmdEndRendering(self.handle);
    self.area = null;
}

pub fn getOffset(self: *CommandBuffer) linalg.vec2i {
    return .{ self.area.offset.x, self.area.offset.y };
}

pub fn getOffsetF(self: *CommandBuffer) linalg.vec2 {
    return @floatFromInt(self.getOffset());
}

pub fn getSize(self: *CommandBuffer) linalg.vec2u {
    return .{ self.area.extent.width, self.area.extent.height };
}

pub fn getSizeF(self: *CommandBuffer) linalg.vec2 {
    return @floatFromInt(self.getSize());
}

pub fn bindPipeline(self: *CommandBuffer, pipeline: *Gpu.Pipeline) void {
    debug.assert(self.area != null);
    debug.assert(self.pipeline == null);

    self.gpu.device.proxy.cmdBindDescriptorSets(
        self.handle,
        .graphics,
        pipeline.layout,
        0,
        @ptrCast(&self.gpu.descriptor_set),
        null,
    );

    self.gpu.device.proxy.cmdBindPipeline(
        self.handle,
        .graphics,
        pipeline.handle,
    );

    self.pipeline = .{ .state = pipeline };
}

pub fn unbindPipeline(self: *CommandBuffer, pipeline: *Gpu.Pipeline) void {
    debug.assert(self.pipeline.?.state == pipeline);
    self.pipeline = null;
}

pub fn pushConstants(self: *CommandBuffer, constants: anytype) void {
    const current_constant = self.pipeline.?.state.push_constants[self.pipeline.?.push_constant_index];
    self.pipeline.?.push_constant_index += 1;

    debug.assert(@sizeOf(@TypeOf(constants)) == current_constant.size);

    self.gpu.device.proxy.cmdPushConstants(
        self.handle,
        self.pipeline.?.state.layout,
        current_constant.stage_flags,
        0,
        current_constant.size,
        &constants,
    );
}

pub fn draw(self: *CommandBuffer, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
    debug.assert(self.pipeline != null);

    self.gpu.device.proxy.cmdDraw(
        self.handle,
        vertex_count,
        instance_count,
        first_vertex,
        first_instance,
    );
}

pub fn flush(self: *CommandBuffer) void {
    if (self.flushed) return;
    defer self.flushed = true;

    const memory_barrier = vk.MemoryBarrier{
        .src_access_mask = .{ .transfer_write = true },
        .dst_access_mask = .{ .shader_read = true }, // Or vertex_attribute_read if using standard VBOs
    };

    self.gpu.device.proxy.cmdPipelineBarrier(
        self.handle,
        .{ .transfer = true },
        .{ .vertex_shader = true, .fragment_shader = true },
        .{},
        &[_]vk.MemoryBarrier{memory_barrier}, // <-- Added global memory barrier here!
        null,
        self.image_barriers.values(),
    );

    self.image_barriers.clearRetainingCapacity();
}

pub fn syncImage(
    self: *CommandBuffer,
    image: Gpu.Image,
    bytes: []const u8,
) !void {
    if (bytes.len == 0) return;
    debug.assert(image.generation == self.gpu.store.image.storage.field(.generation, image.storage_index));

    const width = self.gpu.store.image.storage.field(.width, image.storage_index);
    const height = self.gpu.store.image.storage.field(.height, image.storage_index);
    if (width == 0 or height == 0) return;

    const gop = self.image_barriers.getOrPut(base.gpa, image) catch |err| {
        log.err("failed to queue image barrier: {s}", .{@errorName(err)});
        return err;
    };

    // Align offset to 16 bytes minimum
    const alignment: u64 = 16;
    self.staging.offset = (self.staging.offset + alignment - 1) & ~(alignment - 1);

    if (self.staging.offset + bytes.len > self.staging.capacity) {
        return error.StagingBufferOverflow;
    }

    const dst_ptr = self.staging.ptr + self.staging.offset;
    @memcpy(dst_ptr[0..bytes.len], bytes);

    if (!gop.found_existing) {
        // Pre-copy barrier (Executed immediately)
        self.gpu.device.proxy.cmdPipelineBarrier(
            self.handle,
            .{ .top_of_pipe = true },
            .{ .transfer = true },
            .{},
            null,
            null,
            &[_]vk.ImageMemoryBarrier{.{
                .src_access_mask = .{},
                .dst_access_mask = .{ .transfer_write = true },
                .old_layout = self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).*.?.layout,
                .new_layout = .transfer_dst_optimal,
                .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .image = image.getHandle(self.gpu),
                .subresource_range = .{
                    .aspect_mask = .{ .color = true },
                    .base_mip_level = 0,
                    .level_count = 1,
                    .base_array_layer = 0,
                    .layer_count = 1,
                },
            }},
        );

        // Post-copy barrier (Queued for later)
        gop.value_ptr.* = vk.ImageMemoryBarrier{
            .src_access_mask = .{ .transfer_write = true },
            .dst_access_mask = .{ .shader_read = true },
            .old_layout = .transfer_dst_optimal,
            .new_layout = .shader_read_only_optimal,
            .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .image = image.getHandle(self.gpu),
            .subresource_range = .{
                .aspect_mask = .{ .color = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
        };

        self.gpu.store.image.storage.fieldMut(.state, image.storage_index).*.?.layout = .shader_read_only_optimal;
    }

    // Perform copy
    self.gpu.device.proxy.cmdCopyBufferToImage(
        self.handle,
        self.staging.managed_buffer.getHandle(self.gpu),
        image.getHandle(self.gpu),
        .transfer_dst_optimal,
        &[_]vk.BufferImageCopy{.{
            .buffer_offset = self.staging.offset,
            .buffer_row_length = 0,
            .buffer_image_height = 0,
            .image_subresource = .{
                .aspect_mask = .{ .color = true },
                .mip_level = 0,
                .base_array_layer = 0,
                .layer_count = 1,
            },
            .image_offset = .{ .x = 0, .y = 0, .z = 0 },
            .image_extent = .{
                .width = width,
                .height = height,
                .depth = 1,
            },
        }},
    );

    self.staging.offset += bytes.len;
    self.flushed = false;
}

pub fn syncImageRegion(
    self: *CommandBuffer,
    image: Gpu.Image,
    bytes: []const u8,
    dest_pos: linalg.vec2u,
    dest_dims: linalg.vec2u,
) !void {
    if (dest_dims[0] == 0 or dest_dims[1] == 0 or bytes.len == 0) return;
    debug.assert(image.generation == self.gpu.store.image.storage.field(.generation, image.storage_index));

    // Align offset to 16 bytes minimum
    const alignment: u64 = 16;
    self.staging.offset = (self.staging.offset + alignment - 1) & ~(alignment - 1);

    if (self.staging.offset + bytes.len > self.staging.capacity) {
        return error.StagingBufferOverflow;
    }

    const dst_ptr = self.staging.ptr + self.staging.offset;
    @memcpy(dst_ptr[0..bytes.len], bytes);

    if (self.gpu.store.image.storage.field(.barrier, image.storage_index) == null) {
        // Pre-copy barrier (Executed immediately)
        self.gpu.device.proxy.cmdPipelineBarrier(
            self.handle,
            .{ .top_of_pipe = true },
            .{ .transfer = true },
            .{},
            null,
            null,
            &[_]vk.ImageMemoryBarrier{.{
                .src_access_mask = .{},
                .dst_access_mask = .{ .transfer_write = true },
                .old_layout = self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.layout,
                .new_layout = .transfer_dst_optimal,
                .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .image = self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.handle,
                .subresource_range = .{
                    .aspect_mask = .{ .color = true },
                    .base_mip_level = 0,
                    .level_count = 1,
                    .base_array_layer = 0,
                    .layer_count = 1,
                },
            }},
        );

        // Post-copy barrier (Queued for later)
        self.gpu.store.image.storage.fieldMut(.barrier, image.storage_index).* = vk.ImageMemoryBarrier{
            .src_access_mask = .{ .transfer_write = true },
            .dst_access_mask = .{ .shader_read = true },
            .old_layout = .transfer_dst_optimal,
            .new_layout = .shader_read_only_optimal,
            .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .image = self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.handle,
            .subresource_range = .{
                .aspect_mask = .{ .color = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
        };

        self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.layout = .shader_read_only_optimal;
    }

    self.gpu.device.proxy.cmdCopyBufferToImage(
        self.handle,
        self.staging.managed_buffer,
        self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.handle,
        .transfer_dst_optimal,
        &[_]vk.BufferImageCopy{.{
            .buffer_offset = self.staging.offset,
            .buffer_row_length = 0,
            .buffer_image_height = 0,
            .image_subresource = .{
                .aspect_mask = .{ .color = true },
                .mip_level = 0,
                .base_array_layer = 0,
                .layer_count = 1,
            },
            .image_offset = .{
                .x = @intCast(dest_pos[0]),
                .y = @intCast(dest_pos[1]),
                .z = 0,
            },
            .image_extent = .{
                .width = dest_dims[0],
                .height = dest_dims[1],
                .depth = 1,
            },
        }},
    );

    self.staging.offset += bytes.len;
    self.flushed = false;
}

pub fn syncBuffer(
    self: *CommandBuffer,
    buffer: Gpu.Buffer,
    bytes: []const u8,
) !void {
    if (buffer.generation != self.gpu.store.buffer.storage.field(.generation, buffer.storage_index)) return error.InvalidBuffer;

    // Align offset to 16 bytes to satisfy Vulkan copy requirements
    const alignment: u64 = 16;
    self.staging.offset = (self.staging.offset + alignment - 1) & ~(alignment - 1);

    if (self.staging.offset + bytes.len > self.staging.capacity) {
        return error.StagingBufferOverflow;
    }

    const dst_ptr = self.staging.ptr + self.staging.offset;
    @memcpy(dst_ptr[0..bytes.len], bytes);

    self.gpu.device.proxy.cmdCopyBuffer(
        self.handle,
        self.gpu.store.buffer.getHandle(self.staging.managed_buffer),
        self.gpu.store.buffer.getHandle(buffer),
        &[_]vk.BufferCopy{
            .{
                .src_offset = self.staging.offset,
                .dst_offset = 0,
                .size = bytes.len,
            },
        },
    );

    self.staging.offset += bytes.len;
    self.flushed = false;
}

pub fn syncBufferRegion(
    self: *CommandBuffer,
    buffer: Gpu.Buffer,
    dst_offset: u64,
    bytes: []const u8,
) !void {
    if (buffer.generation != self.gpu.store.buffer.storage.field(.generation, buffer.storage_index)) return error.InvalidBuffer;

    // Align offset to 16 bytes to satisfy Vulkan copy requirements
    const alignment: u64 = 16;
    self.staging.offset = (self.staging.offset + alignment - 1) & ~(alignment - 1);

    if (self.staging.offset + bytes.len > self.staging.capacity) {
        return error.StagingBufferOverflow;
    }

    const dst_ptr = self.staging.ptr + self.staging.offset;
    @memcpy(dst_ptr[0..bytes.len], bytes);

    self.gpu.device.proxy.cmdCopyBuffer(
        self.handle,
        self.staging.managed_buffer,
        self.gpu.store.buffer.storage.field(.state, buffer.storage_index).?.handle,
        &[_]vk.BufferCopy{
            .{
                .src_offset = self.staging.offset,
                .dst_offset = dst_offset,
                .size = bytes.len,
            },
        },
    );

    self.staging.offset += bytes.len;
    self.flushed = false;
}

const base = @import("../base.zig");
const vk = @import("../vulkan.zig");
const linalg = @import("../linalg.zig");
const Gpu = @import("../Gpu.zig");

const debug = base.debug;

const log = base.log.scoped(.Gpu);
