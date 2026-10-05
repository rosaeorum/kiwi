//! General namespace for frame lifetime and timing related utilities.

const frame = @This();

pub const delta_dur = Io.Duration.fromNanoseconds(@round(delta_ms * base.time.ns_per_ms));
pub const delta_ms = 16.666666666666666;
pub const delta_s = delta_ms / 1000.0;
pub const max_in_flight = 2;
pub const Id = math.IntFittingRange(0, max_in_flight);

pub fn InFlightArray(comptime T: type) type {
    return [max_in_flight]T;
}

pub fn idFromIndex(frame_index: u64) Id {
    return @intCast(frame_index % max_in_flight);
}

const base = @import("base.zig");
const math = base.math;
const Io = base.Io;
