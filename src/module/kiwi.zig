pub const kiwi = @This();

pub const base = @import("base.zig");
pub const vk = @import("vulkan.zig");
pub const vma = @import("vma.zig");
pub const glfw = @import("glfw.zig");

pub const Gpu = @import("Gpu.zig");
pub const Client = @import("Client.zig");
pub const Window = @import("Window.zig");
pub const Image = @import("Image.zig");
pub const frame = @import("frame.zig");
pub const linalg = @import("linalg.zig");

export fn rust_eh_personality() callconv(.c) void {
    // This is a dead stub. If it's ever hit due to an internal Rust engine panic (wasmtime),
    // we explicitly trap to stop execution safely.
    @trap();
}

test {
    _ = base;
    _ = vk;
    _ = vma;
    _ = glfw;
    _ = Gpu;
    _ = Client;
    _ = Window;
    _ = Image;
    _ = frame;
    _ = linalg;
}
