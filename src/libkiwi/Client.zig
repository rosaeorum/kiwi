//! The main entry point for realtime clients, containing the `Gpu` handle and the primary `Window`.

const Client = @This();

gpu: *Gpu,
main_window: *Window,

pub fn init(config: *const api.Config) !*Client {
    var exts: base.ArrayList(Gpu.Extension) = try .initCapacity(base.temp, Gpu.vk_extension_names.len);

    if (config.render_doc_compat and base.build_info.os.tag == .linux) {
        c.glfwInitHint(c.GLFW_PLATFORM, c.GLFW_PLATFORM_X11);
    }

    if (c.glfwInit() != c.GLFW_TRUE) {
        @branchHint(.cold);
        return error.FailedToInitializeGLFW;
    }

    var glfw_ext_count: u32 = 0;

    const glfw_exts = c.glfwGetRequiredInstanceExtensions(&glfw_ext_count);

    for (0..glfw_ext_count) |i| {
        const ext_name = mem.span(glfw_exts[i]);
        if (Gpu.getExtensionByName(ext_name)) |ext| {
            exts.appendAssumeCapacity(ext);
        } else |err| {
            log.err("Could not resolve GLFW requested extension: {s}", .{@errorName(err)});
        }
    }
    errdefer c.glfwTerminate();

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

    c.glfwTerminate();
}

pub fn pollEvents(_: *Client) void {
    base.temp_arena.reset();
    c.glfwPollEvents();
}

pub const Window = @import("Window.zig");

const c = @import("external/glfw.zig");
const api = @import("../api.zig");
const linalg = @import("../linalg.zig");
const base = @import("../base.zig");
const mem = base.mem;
const log = base.log.scoped(.client);
const Gpu = @import("Gpu.zig");
