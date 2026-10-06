const SwapChain = @This();

gpu: *Gpu,
surface_format: vk.SurfaceFormatKHR,
present_mode: vk.PresentModeKHR,
extent: linalg.vec2u,
handle: vk.SwapchainKHR,

swap_images: []vk.Image,
swap_views: []Gpu.ImageView,
swap_semaphores: []vk.Semaphore,
image_index: u32,

avail_semaphores: frame.InFlightArray(vk.Semaphore),
fences: frame.InFlightArray(vk.Fence),

pub const PresentState = enum {
    optimal,
    suboptimal,
};

pub fn init(gpu: *Gpu, extent: linalg.vec2u) !SwapChain {
    var self = SwapChain{
        .gpu = gpu,
        .surface_format = undefined,
        .present_mode = undefined,
        .extent = extent,
        .handle = .null_handle,
        .swap_images = &.{},
        .swap_views = &.{},
        .swap_semaphores = &.{},
        .avail_semaphores = undefined,
        .fences = undefined,
        .image_index = 0,
    };

    var j: usize = 0;
    errdefer for (0..j) |index| {
        self.gpu.device.proxy.destroySemaphore(self.avail_semaphores[index], null);
    };

    for (0..frame.max_in_flight) |slot_index| {
        self.avail_semaphores[slot_index] = try self.gpu.device.proxy.createSemaphore(&.{}, null);
        errdefer self.gpu.device.proxy.destroySemaphore(self.avail_semaphores[slot_index], null);

        self.fences[slot_index] = try self.gpu.device.proxy.createFence(
            &.{ .flags = .{ .signaled = true } },
            null,
        );
        errdefer self.gpu.device.proxy.destroyFence(self.fences[slot_index], null);

        j += 1;
    }

    try self.initRecycle();

    return self;
}

pub fn initRecycle(self: *SwapChain) !void {
    const caps =
        try self.gpu.device.instance.proxy.getPhysicalDeviceSurfaceCapabilitiesKHR(self.gpu.device.pdev, self.gpu.device.present.?.surface);
    self.extent = findActualExtent(caps, self.extent);
    if (@reduce(.Or, linalg.zero(linalg.vec2u) == self.extent)) {
        return error.InvalidSurfaceDimensions;
    }

    const surface_format = try self.findSurfaceFormat();
    const present_mode = try self.findPresentMode();

    var image_count = caps.min_image_count + 1;
    if (caps.max_image_count > 0) {
        image_count = @min(image_count, caps.max_image_count);
    }

    const qfi = [_]u32{
        self.gpu.device.graphics_queue.family,
        self.gpu.device.present.?.queue.family,
    };
    const sharing_mode: vk.SharingMode =
        if (self.gpu.device.graphics_queue.family != self.gpu.device.present.?.queue.family)
            .concurrent
        else
            .exclusive;

    const handle = try self.gpu.device.proxy.createSwapchainKHR(&.{
        .surface = self.gpu.device.present.?.surface,
        .min_image_count = image_count,
        .image_format = surface_format.format,
        .image_color_space = surface_format.color_space,
        .image_extent = .{ .width = self.extent[0], .height = self.extent[1] },
        .image_array_layers = 1,
        .image_usage = .{ .color_attachment = true, .transfer_dst = true },
        .image_sharing_mode = sharing_mode,
        .queue_family_index_count = qfi.len,
        .p_queue_family_indices = &qfi,
        .pre_transform = caps.current_transform,
        .composite_alpha = .{ .opaque_khr = true },
        .present_mode = present_mode,
        .clipped = .true,
        .old_swapchain = self.handle,
    }, null);
    errdefer self.gpu.device.proxy.destroySwapchainKHR(handle, null);

    if (self.handle != .null_handle) {
        self.gpu.device.proxy.destroySwapchainKHR(self.handle, null);
    }

    self.handle = handle;
    self.surface_format = surface_format;
    self.present_mode = present_mode;
    self.image_index = 0;

    self.swap_images = try self.gpu.device.proxy.getSwapchainImagesAllocKHR(self.handle, base.gpa);
    errdefer base.gpa.free(self.swap_images);

    self.swap_views = try base.gpa.alloc(Gpu.ImageView, self.swap_images.len);
    errdefer base.gpa.free(self.swap_views);

    self.swap_semaphores = try base.gpa.alloc(vk.Semaphore, self.swap_images.len);
    errdefer base.gpa.free(self.swap_semaphores);

    var i: usize = 0;
    errdefer for (0..i) |index| {
        self.gpu.device.proxy.destroyImageView(self.swap_views[index], null);
        self.gpu.device.proxy.destroySemaphore(self.swap_semaphores[index], null);
    };

    for (0..self.swap_images.len) |index| {
        self.swap_views[index] = try self.gpu.device.proxy.createImageView(
            &.{
                .image = self.swap_images[index],
                .view_type = .@"2d",
                .format = surface_format.format,
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
            },
            null,
        );
        errdefer self.gpu.device.proxy.destroyImageView(self.swap_views[index], null);

        self.swap_semaphores[index] = try self.gpu.device.proxy.createSemaphore(&.{}, null);
        errdefer self.gpu.device.proxy.destroySemaphore(self.swap_semaphores[index], null);

        i += 1;
    }
}

pub fn deinit(self: *SwapChain) void {
    for (0..self.swap_images.len) |index| {
        self.gpu.device.proxy.destroySemaphore(self.swap_semaphores[index], null);
        self.gpu.device.proxy.destroyImageView(self.swap_views[index], null);
    }

    for (0..frame.max_in_flight) |index| {
        self.gpu.device.proxy.destroySemaphore(self.avail_semaphores[index], null);
        self.gpu.device.proxy.destroyFence(self.fences[index], null);
    }

    base.gpa.free(self.swap_images);
    base.gpa.free(self.swap_views);
    base.gpa.free(self.swap_semaphores);

    self.gpu.device.proxy.destroySwapchainKHR(self.handle, null);
}

pub fn recreate(self: *SwapChain, new_extent: linalg.vec2u) !void {
    // NOTE: Just because present has returned does not mean the gpu is done with this frame;
    //       in order to avoid an invalid free of the existing swapchain semaphore, we must wait for idle.
    try self.gpu.device.proxy.deviceWaitIdle();

    for (0..self.swap_images.len) |index| {
        self.gpu.device.proxy.destroySemaphore(self.swap_semaphores[index], null);
        self.gpu.device.proxy.destroyImageView(self.swap_views[index], null);
    }

    base.gpa.free(self.swap_images);
    base.gpa.free(self.swap_views);
    base.gpa.free(self.swap_semaphores);

    self.swap_images = &.{};
    self.swap_views = &.{};
    self.swap_semaphores = &.{};

    self.extent = new_extent;

    try self.initRecycle();
}

fn currentImage(self: *const SwapChain) vk.Image {
    return self.swap_images[self.image_index].image;
}

pub fn beginFrame(self: *SwapChain, frame_id: frame.Id, size: linalg.vec2u, commands: *Gpu.CommandBuffer) ?Gpu.ImageView {
    if (size[0] == 0 or size[1] == 0) {
        log.debug("cannot create 0-sized swap frame, skipping.", .{});
        return null;
    }

    if (size[0] != self.extent[0] or size[1] != self.extent[1] or self.swap_images.len == 0) {
        self.recreate(size) catch |err| {
            log.warn("failed to begin swapchain frame: {s}", .{@errorName(err)});
        };
        return null;
    }

    if (self.acquireNextImage(frame_id) catch |err| {
        log.warn("failed to begin swapchain frame: {s}", .{@errorName(err)});
        return null;
    }) {
        commands.wait_semas.append(base.gpa, self.avail_semaphores[frame_id]) catch |err| {
            log.warn("failed to begin swapchain frame: {s}", .{@errorName(err)});
            return null;
        };

        const swap_image = self.swap_images[self.image_index];
        const swap_view = self.swap_views[self.image_index];

        commands.transitionImageLayout(
            swap_image,

            // NOTE: passing .undefined as the old_layout discards the previous
            // contents of the image. For a swapchain, this is exactly what we
            // want, since we overwrite the whole screen anyway. Later
            // implementations referencing this one should note that this is
            // not always desired, for example in overdraw effects, but
            // discarding the previous frame's data is intentional here,
            // as it helps the rasterizer optimize memory bandwidth.

            .undefined,
            .color_attachment_optimal,
            .{ .color_attachment_output = true },
            .{},
            .{ .color_attachment_output = true },
            .{ .color_attachment_write = true },
        );
        return swap_view;
    }

    self.recreate(size) catch |err| {
        log.warn("failed to begin swapchain frame: {s}", .{@errorName(err)});
    };
    return null;
}

pub fn endFrame(self: *SwapChain, commands: *Gpu.CommandBuffer) void {
    const swap_image = self.swap_images[self.image_index];
    commands.transitionImageLayout(
        swap_image,
        .color_attachment_optimal,
        .present_src_khr,
        .{ .color_attachment_output = true },
        .{ .color_attachment_write = true },
        .{ .bottom_of_pipe = true },
        .{},
    );

    const swap_semaphore = self.swap_semaphores[self.image_index];
    commands.signal_semas.append(base.gpa, swap_semaphore) catch {
        log.err("failed to add swap chain semaphore to frame signal queue; window will miss an update", .{});
    };
}

fn acquireNextImage(self: *SwapChain, frame_id: frame.Id) !bool {
    const result = try self.gpu.device.proxy.acquireNextImageKHR(
        self.handle,
        math.maxInt(u64),
        self.avail_semaphores[frame_id],
        .null_handle,
    );

    // NOTE: Only return false if the swapchain is completely out of date.
    //       If it's suboptimal, we've still acquired an image and the semaphore
    //       will be signaled, so we must proceed and render to it.
    if (result.result == .error_out_of_date_khr) {
        return false;
    }

    self.image_index = result.image_index;

    return true;
}

pub fn presentImage(self: *SwapChain) PresentState {
    const swap_semaphore = self.swap_semaphores[self.image_index];

    const present_result = self.gpu.device.proxy.queuePresentKHR(
        self.gpu.device.present.?.queue.handle,
        &.{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = (&swap_semaphore)[0..1],
            .swapchain_count = 1,
            .p_swapchains = (&self.handle)[0..1],
            .p_image_indices = (&self.image_index)[0..1],
        },
    ) catch |err| switch (err) {
        error.OutOfDateKHR => return .suboptimal,
        else => |narrow| {
            log.err("Failed to present swapchain image: {s}", .{@errorName(narrow)});
            return .suboptimal;
        },
    };

    return switch (present_result) {
        .success => .optimal,
        .suboptimal_khr => .suboptimal,
        else => unreachable,
    };
}

fn findSurfaceFormat(self: *SwapChain) !vk.SurfaceFormatKHR {
    const preferred = vk.SurfaceFormatKHR{
        .format = .b8g8r8a8_srgb,
        .color_space = .srgb_nonlinear_khr,
    };

    const surface_formats = try self.gpu.device.instance.proxy.getPhysicalDeviceSurfaceFormatsAllocKHR(
        self.gpu.device.pdev,
        self.gpu.device.present.?.surface,
        base.gpa,
    );
    defer base.gpa.free(surface_formats);

    for (surface_formats) |sfmt| {
        if (meta.eql(sfmt, preferred)) {
            return preferred;
        }
    }

    return surface_formats[0]; // There must always be at least one supported surface format
}

fn findPresentMode(self: *SwapChain) !vk.PresentModeKHR {
    const present_modes = try self.gpu.device.instance.proxy.getPhysicalDeviceSurfacePresentModesAllocKHR(
        self.gpu.device.pdev,
        self.gpu.device.present.?.surface,
        base.gpa,
    );
    defer base.gpa.free(present_modes);

    const preferred = [_]vk.PresentModeKHR{
        .mailbox_khr,
        .immediate_khr,
    };

    for (preferred) |present_mode| {
        if (mem.indexOfScalar(vk.PresentModeKHR, present_modes, present_mode) != null) {
            return present_mode;
        }
    }

    return .fifo_khr;
}

fn findActualExtent(caps: vk.SurfaceCapabilitiesKHR, extent: linalg.vec2u) linalg.vec2u {
    if (caps.current_extent.width != 0xFFFF_FFFF) {
        return .{ caps.current_extent.width, caps.current_extent.height };
    } else {
        return .{
            math.clamp(extent[0], caps.min_image_extent.width, caps.max_image_extent.width),
            math.clamp(extent[1], caps.min_image_extent.height, caps.max_image_extent.height),
        };
    }
}

const base = @import("../base.zig");
const linalg = @import("../linalg.zig");
const vk = @import("../vulkan.zig");
const frame = @import("../frame.zig");
const Gpu = @import("../Gpu.zig");

const mem = base.mem;
const math = base.math;
const meta = base.meta;

const log = base.log.scoped(.Gpu);
