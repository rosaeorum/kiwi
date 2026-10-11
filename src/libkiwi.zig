pub const libkiwi = @This();

pub const api = @import("api.zig");
pub const base = @import("base.zig");
pub const linalg = @import("linalg.zig");

pub const vk = @import("libkiwi/external/vulkan.zig");
pub const vma = @import("libkiwi/external/vma.zig");
pub const glfw = @import("libkiwi/external/glfw.zig");
pub const wasm = @import("libkiwi/external/wasm.zig");

pub const frame = @import("libkiwi/frame.zig");
pub const Runtime = @import("libkiwi/Runtime.zig");
pub const Gpu = @import("libkiwi/Gpu.zig");
pub const Client = @import("libkiwi/Client.zig");
pub const Window = @import("libkiwi/Window.zig");
pub const Image = @import("libkiwi/external/Image.zig");

test {
    _ = vk;
    _ = vma;
    _ = glfw;
    _ = wasm;

    _ = api;
    _ = base;
    _ = linalg;

    _ = frame;
    _ = Runtime;
    _ = Gpu;
    _ = Client;
    _ = Window;
    _ = Image;
}
