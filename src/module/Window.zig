//! Primary desktop window abstraction for kiwi. Requires linking GLFW; see `Client` for usage.

const Window = @This();

gpu: *Gpu,
handle: *c.struct_GLFWwindow,
surface: Gpu.Surface,
swap_chain: Gpu.SwapChain,

pub const Config = extern struct {
    pub const default_title = "untitled window";

    /// the initial title for the window
    title: [*:0]const u8 = default_title,
    /// the initial size of the window
    size: [2]u32 = .{ 800, 600 },
    /// the initial position of the window
    ///
    /// `null` will automatically position the window, centered on the active monitor
    position: ?*const [2]i32 = null,
    /// the monitor onto which to spawn the window in fullscreen mode
    fullscreen_monitor: ?*Monitor = null,

    flags: packed struct(u32) {
        /// specifies whether the windowed mode window will be given input focus when created
        ///
        /// ignored for full screen and initially hidden windows
        focused: bool = false,
        /// specifies whether the windowed mode will be iconified when created
        iconified: bool = false,
        /// specifies whether the windowed mode window will be initially visible
        ///
        /// ignored for full screen windows
        visible: bool = false,
        /// specifies whether the windowed mode window will be maximized when created
        ///
        /// ignored for full screen windows
        maximized: bool = false,

        /// specifies whether the windowed mode window will have window decorations such as a border, a close widget, etc
        ///
        /// ignored for full screen windows
        decorated: bool = true,

        /// specifies whether the windowed mode window will be floating above other regular windows, also called topmost or always-on-top
        ///
        /// "intended primarily for debugging purposes and cannot be used to implement proper full screen windows"
        ///
        /// ignored for full screen windows
        floating: bool = false,
        /// specifies whether the windowed mode window will be resizable *by the user*
        ///
        /// ignored for full screen and undecorated windows
        resizable: bool = true,

        /// specifies whether the full screen window will automatically iconify and restore the previous video mode on input focus loss
        ///
        /// ignored for windowed mode windows
        auto_iconify: bool = true,
        /// specifies whether the window will be given input focus when Window.show() is called
        ///
        focus_on_show: bool = true,
        /// specifies whether the cursor should be centered over newly created full screen windows
        ///
        /// ignored for windowed mode windows
        center_cursor: bool = false,

        /// specifies whether the window content area should be resized based on content scale changes
        ///
        /// a content scale change can occur because of a global user settings change, or
        /// because the window was moved to a monitor with different scale settings
        ///
        /// this only has an effect on platforms where screen coordinates and pixels always map 1:1, such as Windows and X11
        ///
        /// on platforms like macOS, the resolution of the framebuffer can change independently of the window size
        scale_to_monitor: bool = false,
        /// specifies whether the framebuffer should be resized based on content scale changes
        ///
        /// a content scale change can occur because of a global user settings change, or
        /// because the window was moved to a monitor with different scale settings
        ///
        /// this hint only has an effect on platforms where screen coordinates can be scaled relative to pixel coordinates, such as macOS and Wayland
        ///
        /// on platforms like Windows and X11 the framebuffer and window content area sizes always map 1:1
        scale_framebuffer: bool = false,

        /// specifies whether the window framebuffer will be transparent
        ///
        /// if enabled and supported by the system, the window framebuffer alpha channel will be used to combine the framebuffer with the background
        ///
        /// this does not affect window decorations
        transparent_framebuffer: bool = false,

        /// specifies whether the window is transparent to mouse input, letting any mouse events pass through to whatever window is behind it
        ///
        /// only supported for undecorated windows
        ///
        /// decorated windows with this enabled will behave differently between platforms
        mouse_passthrough: bool = false,

        // platform specific extensions

        cocoa_graphics_switching: bool = false,
        win32_keyboard_menu: bool = false,
        win32_showdefault: bool = true,

        _unused_bits: u15 = 0,
    } = .{},

    strings: extern struct {
        cocoa_frame_name: ?[*:0]const u8 = null,
        x11_class_name: ?[*:0]const u8 = null,
        x11_instance_name: ?[*:0]const u8 = null,
        wayland_app_id: ?[*:0]const u8 = null,
    } = .{},

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
};

pub const Monitor = struct {
    handle: *c.struct_GLFWmonitor,
};

pub fn init(gpu: *Gpu, config: *const Config) !*Window {
    const self = try _beginPreinit(gpu.device.instance, config);
    errdefer self._destroyPreinit(gpu.device.instance);

    try self._finalizePreinit(gpu);

    return self;
}

pub fn deinit(self: *Window) void {
    self.swap_chain.deinit();
    self._destroyPreinit(self.gpu.device.instance);
}

pub fn _beginPreinit(instance: *Gpu.Instance, config: *const Config) !*Window {
    const self = try base.gpa.create(Window);
    errdefer base.gpa.destroy(self);

    c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);

    if (config.position) |pos| {
        c.glfwWindowHint(c.GLFW_POSITION_X, pos[0]);
        c.glfwWindowHint(c.GLFW_POSITION_Y, pos[1]);
    }

    inline for (comptime meta.fieldNames(@FieldType(Config, "flags"))) |boolean| {
        if (comptime base.mem.eql(u8, boolean, "_unused_bits")) continue;

        c.glfwWindowHint(@field(Config.flag_enums, boolean), @intFromBool(@field(config.flags, boolean)));
    }

    inline for (comptime meta.fieldNames(@FieldType(Config, "strings"))) |string| {
        if (@field(config.strings, string)) |value| {
            c.glfwWindowHintString(@field(Config.string_enums, string), value);
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

const c = @import("glfw.zig");
const vk = @import("vulkan.zig");

const linalg = @import("linalg.zig");
const frame = @import("frame.zig");
const base = @import("base.zig");
const meta = base.meta;
const log = base.log.scoped(.window);
const Gpu = @import("Gpu.zig");
