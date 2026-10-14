extern "provider" fn mul2(v: i32) i32;
export fn mul2Plus(v: i32) i32 {
    return mul2(v) + 100;
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
