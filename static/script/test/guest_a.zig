const std = @import("std");

pub const wasm_page_size: comptime_int = 64 * 1024;
pub const wasm_region_size: comptime_int = 1 << 32;
pub const binding_slot_size: comptime_int = wasm_page_size * 16;
pub const max_binding_slots: comptime_int = 1024;
pub const total_binding_region: comptime_int = binding_slot_size * max_binding_slots;
pub const binding_region_base: comptime_int = wasm_region_size - total_binding_region;
pub const swap_zone_slot: comptime_int = max_binding_slots - 1;
pub const ZONE_ADDR: usize = binding_region_base + (max_binding_slots - 1) * binding_slot_size;
pub const ZONE_LEN: usize = binding_slot_size;

pub fn zoneBytes() []u8 {
    const p: [*]u8 = @ptrFromInt(ZONE_ADDR);
    return p[0..ZONE_LEN];
}
export fn add() void {
    const z = zoneBytes();
    const lhs = std.mem.readInt(i32, z[0..4], .little);
    const rhs = std.mem.readInt(i32, z[4..8], .little);
    std.mem.writeInt(i32, z[0..4], lhs + rhs, .little);
}
export fn echo(addr: u32) i32 {
    const p: *align(1) i32 = @ptrFromInt(@as(usize, addr));
    return p.*;
}
export fn poke(addr: u32, val: i32) void {
    const p: *align(1) i32 = @ptrFromInt(@as(usize, addr));
    p.* = val;
}
export fn grow(pages: u32) i32 {
    if (@wasmMemoryGrow(0, pages) != -1) return 0;
    return -1;
}
export var scratch: [3]i32 = .{ 0, 0, 0 };
export fn scratchAddr(idx: u32) u32 {
    return @intCast(@intFromPtr(&scratch[idx]));
}
extern fn console_log(v: u32, l: u32) void;
export fn mul2(v: i32) i32 {
    const msg = "hello world";
    console_log(@intCast(@intFromPtr(msg.ptr)), @intCast(msg.len));
    // observable side effect: lets the host prove that cross-instance
    // calls into this module actually land in this instance's memory
    scratch[2] += 1;
    return v * 2;
}
export fn zoneLoadStatic() i32 {
    const p: *align(1) i32 = @ptrFromInt(ZONE_ADDR);
    return p.*;
}
export fn zonePokeDynamic(base: u32, val: i32) void {
    const p: *align(1) i32 = @ptrFromInt(@as(usize, base));
    p.* = val;
}
export fn memPages() u32 {
    return @wasmMemorySize(0);
}
pub const Position = extern struct { x: f32, y: f32 };
pub const Velocity = extern struct { x: f32, y: f32 };
pub const Health = extern struct { current: i32 };
export fn particle_system(
    pos_addr: i32,
    vel_addr: i32,
    health_addr: i32,
    count: i32,
    flags: i32,
) void {
    const positions: [*]Position = @ptrFromInt(@as(usize, @bitCast(pos_addr)));
    const velocities: [*]Velocity = @ptrFromInt(@as(usize, @bitCast(vel_addr)));
    var i: usize = 0;
    while (i < @as(usize, @intCast(count))) : (i += 1) {
        positions[i].x += velocities[i].x;
        positions[i].y += velocities[i].y;
        if ((flags & 1) != 0) {
            const healths: [*]Health = @ptrFromInt(@as(usize, @bitCast(health_addr)));
            if (healths[i].current > 0) healths[i].current -= 1;
        }
    }
}
