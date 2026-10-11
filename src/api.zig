pub const Config = extern struct {
    /// Should the vulkan validation layer be enabled?
    validation: bool = base.build_info.mode == .debug,
    /// NOTE: if glfw selects wayland, renderdoc won't work; this flag forces it to use x11
    render_doc_compat: bool = base.build_info.mode == .debug,
    /// Name of the application utilizing kiwi engine; passed to the vulkan driver.
    application_name: [*:0]const u8 = "kiwi engine application",
    /// Version of the application utilizing kiwi engine; passed to the vulkan driver.
    application_version: SemVer = .none,
    /// Initial configuration for the client's primary window.
    main_window: WindowConfig = .default,
};

pub const WindowConfig = extern struct {
    pub const default_title = "untitled window";
    pub const default = WindowConfig{};

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
};

pub const Monitor = opaque {};

pub const SemVer = extern struct {
    major: u32 = 0,
    minor: u32 = 0,
    patch: u32 = 0,
    hash: u32 = 0,

    pub const none = SemVer{};

    pub fn toBase(self: *const SemVer) base.SemanticVersion {
        return .{
            .major = self.major,
            .minor = self.minor,
            .patch = self.patch,
            .build = base.fmt.allocPrint(base.static, "{x}", .{self.hash}) catch unreachable,
        };
    }

    pub fn fromBase(b: *const base.SemanticVersion) SemVer {
        var hasher = base.Wyhash.init(0);
        if (b.pre) |pre| hasher.update(pre);
        if (b.build) |build| hasher.update(build);
        return .{
            .major = @intCast(b.major),
            .minor = @intCast(b.minor),
            .patch = @intCast(b.patch),
            .hash = @truncate(hasher.final()),
        };
    }
};

const base = @import("base.zig");
