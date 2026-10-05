//! The main entry point for realtime clients, containing the `Gpu` handle and the primary `Window`.

const Client = @This();

gpu: *Gpu,
main_window: *Window,

pub const Config = struct {
    /// Should the vulkan validation layer be enabled?
    validation: bool = base.build_info.mode == .debug,
    /// NOTE: if glfw selects wayland, renderdoc won't work; this flag forces it to use x11
    render_doc_compat: bool = base.build_info.mode == .debug,
    /// Name of the application utilizing kiwi engine; passed to the vulkan driver.
    application_name: [*:0]const u8 = "kiwi engine application",
    /// Version of the application utilizing kiwi engine; passed to the vulkan driver.
    application_version: base.SemanticVersion = .{ .major = 0, .minor = 0, .patch = 0 },
    /// Initial configuration for the client's primary window.
    main_window: Window.Config = .{},
};

pub fn init(config: *const Config) !*Client {
    var exts: base.ArrayList(Gpu.Extension) = try .initCapacity(base.temp, Gpu.vk_extension_names.len);

    if (config.render_doc_compat and base.build_info.os.tag == .linux) {
        glfw.initHint(.{ .platform = .x11 });
    }

    try glfw.init();

    var glfw_ext_count: u32 = 0;

    const glfw_exts = glfw.getRequiredInstanceExtensions(&glfw_ext_count);

    for (0..glfw_ext_count) |i| {
        const ext_name = mem.span(glfw_exts[i]);
        if (Gpu.getExtensionByName(ext_name)) |ext| {
            exts.appendAssumeCapacity(ext);
        } else |err| {
            log.err("Could not resolve GLFW requested extension: {s}", .{@errorName(err)});
        }
    }
    errdefer glfw.deinit();

    const self = try base.gpa.create(Client);
    errdefer base.gpa.destroy(self);

    self.gpu = initialize: {
        const instance = try Gpu.Instance.init(
            config.validation,
            config.application_name,
            config.application_version,
            exts.items,
        );
        errdefer instance.deinit();

        self.main_window = try Window._beginPreinit(instance, &config.main_window);
        errdefer self.main_window._destroyPreinit(instance);

        const device = try Gpu.Device.init(instance, self.main_window.surface);
        errdefer device.deinit();

        break :initialize try Gpu.init(device);
    };
    errdefer self.gpu.deinit();

    try self.main_window._finalizePreinit(self.gpu);
    errdefer self.main_window.deinit();

    return self;
}

pub fn deinit(self: *Client) void {
    const device = self.gpu.device;
    const instance = device.instance;

    self.main_window.deinit();
    self.gpu.deinit();

    device.deinit();
    instance.deinit();

    glfw.deinit();
}

pub fn pollEvents(_: *Client) void {
    base.temp_arena.reset();
    glfw.pollEvents();
}

pub const Window = @import("Window.zig");

const glfw = @import("glfw.zig");
const linalg = @import("linalg.zig");
const base = @import("base.zig");
const mem = base.mem;
const log = base.log.scoped(.client);
const Gpu = @import("Gpu.zig");
