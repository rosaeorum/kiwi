//! Primary desktop window abstraction for kiwi. Requires linking GLFW; see `Client` for usage.

const Window = @This();

gpu: *Gpu,
handle: *c.struct_GLFWwindow,
surface: Gpu.Surface,
swap_chain: Gpu.SwapChain,

pub fn init(gpu: *Gpu, config: *const api.WindowConfig) !*Window {
    const self = try _beginPreinit(gpu.device.instance, config);
    errdefer self._destroyPreinit(gpu.device.instance);

    try self._finalizePreinit(gpu);

    return self;
}

pub fn deinit(self: *Window) void {
    self.swap_chain.deinit();
    self._destroyPreinit(self.gpu.device.instance);
}

pub const flag_enums = struct {
    pub const focused = c.GLFW_FOCUSED;
    pub const iconified = c.GLFW_ICONIFIED;
    pub const visible = c.GLFW_VISIBLE;
    pub const maximized = c.GLFW_MAXIMIZED;
    pub const decorated = c.GLFW_DECORATED;
    pub const floating = c.GLFW_FLOATING;
    pub const resizable = c.GLFW_RESIZABLE;
    pub const auto_iconify = c.GLFW_AUTO_ICONIFY;
    pub const focus_on_show = c.GLFW_FOCUS_ON_SHOW;
    pub const center_cursor = c.GLFW_CENTER_CURSOR;
    pub const scale_to_monitor = c.GLFW_SCALE_TO_MONITOR;
    pub const scale_framebuffer = c.GLFW_SCALE_FRAMEBUFFER;
    pub const transparent_framebuffer = c.GLFW_TRANSPARENT_FRAMEBUFFER;
    pub const mouse_passthrough = c.GLFW_MOUSE_PASSTHROUGH;
    pub const cocoa_graphics_switching = c.GLFW_COCOA_GRAPHICS_SWITCHING;
    pub const win32_keyboard_menu = c.GLFW_WIN32_KEYBOARD_MENU;
    pub const win32_showdefault = c.GLFW_WIN32_SHOWDEFAULT;
};

pub const string_enums = struct {
    pub const cocoa_frame_name = c.GLFW_COCOA_FRAME_NAME;
    pub const x11_class_name = c.GLFW_X11_CLASS_NAME;
    pub const x11_instance_name = c.GLFW_X11_INSTANCE_NAME;
    pub const wayland_app_id = c.GLFW_WAYLAND_APP_ID;
};

pub fn _beginPreinit(instance: *Gpu.Instance, config: *const api.WindowConfig) !*Window {
    const self = try base.gpa.create(Window);
    errdefer base.gpa.destroy(self);

    c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);

    if (config.position) |pos| {
        c.glfwWindowHint(c.GLFW_POSITION_X, pos[0]);
        c.glfwWindowHint(c.GLFW_POSITION_Y, pos[1]);
    }

    inline for (comptime meta.fieldNames(flag_enums)) |boolean| {
        if (comptime base.mem.eql(u8, boolean, "_unused_bits")) continue;

        c.glfwWindowHint(@field(flag_enums, boolean), @intFromBool(@field(config.flags, boolean)));
    }

    inline for (comptime meta.fieldNames(string_enums)) |string| {
        if (@field(config.strings, string)) |value| {
            c.glfwWindowHintString(@field(string_enums, string), value);
        }
    }

    self.handle = c.glfwCreateWindow(
        @intCast(config.size[0]),
        @intCast(config.size[1]),
        config.title,
        @ptrCast(config.fullscreen_monitor),
        null,
    ) orelse {
        @branchHint(.cold);
        return error.FailedToCreateWindow;
    };
    errdefer c.glfwDestroyWindow(self.handle);

    const glfwCreateWindowSurface = @extern(*const fn (
        instance: vk.Instance,
        window: *c.struct_GLFWwindow,
        allocator: ?*const vk.AllocationCallbacks,
        surface: *vk.SurfaceKHR,
    ) callconv(.c) vk.Result, .{ .name = "glfwCreateWindowSurface" });

    const surface_result = glfwCreateWindowSurface(
        @ptrCast(instance.proxy.handle),
        self.handle,
        null,
        &self.surface,
    );

    if (surface_result != .success) {
        @branchHint(.cold);
        return error.FailedToCreateSurface;
    }
    errdefer instance.proxy.destroySurfaceKHR(self.surface, null);

    return self;
}

pub fn _finalizePreinit(self: *Window, gpu: *Gpu) !void {
    self.gpu = gpu;
    self.swap_chain = try Gpu.SwapChain.init(gpu, self.extent());
}

pub fn _destroyPreinit(self: *Window, instance: *Gpu.Instance) void {
    instance.proxy.destroySurfaceKHR(self.surface, null);
    c.glfwDestroyWindow(self.handle);
    base.gpa.destroy(self);
}

pub fn show(self: *Window) void {
    c.glfwShowWindow(self.handle);
}

pub fn hide(self: *Window) void {
    c.glfwHideWindow(self.handle);
}

pub fn shouldClose(self: *Window) bool {
    return c.glfwWindowShouldClose(self.handle) == c.GLFW_TRUE;
}

pub fn extent(self: *Window) linalg.vec2u {
    var i = [2]i32{ 0, 0 };
    c.glfwGetFramebufferSize(self.handle, &i[0], &i[1]);
    return @intCast(@as(linalg.vec2i, i));
}

pub fn beginFrame(self: *Window, frame_id: frame.Id, cmd: *Gpu.CommandBuffer) ?struct { Gpu.ImageView, linalg.vec2u } {
    const size = self.extent();
    const view = self.swap_chain.beginFrame(frame_id, size, cmd) orelse return null;
    return .{ view, size };
}

pub fn endFrame(self: *Window, cmd: *Gpu.CommandBuffer) void {
    return self.swap_chain.endFrame(cmd);
}

pub fn present(self: *Window) Gpu.SwapChain.PresentState {
    return self.swap_chain.presentImage();
}

const c = @import("external/glfw.zig");
const vk = @import("external/vulkan.zig");

const api = @import("../api.zig");
const linalg = @import("../linalg.zig");
const frame = @import("frame.zig");
const base = @import("../base.zig");
const meta = base.meta;
const log = base.log.scoped(.window);
const Gpu = @import("Gpu.zig");
