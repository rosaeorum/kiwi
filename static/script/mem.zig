const std = @import("std");

pub const ZONE_ADDR: usize = 0xFFFF_0000;
pub const ZONE_LEN: usize = 64 * 1024;

pub const BlobHead = extern struct { lhs: i32, rhs: i32 };

const zone: *align(1) BlobHead = @ptrFromInt(ZONE_ADDR);

/// swap zone layout: { lhs: i32, rhs: i32 } - lhs += rhs.
export fn add() void {
    zone.lhs = zone.lhs + zone.rhs;
}

// read an i32 from anywhere in guest memory. The host uses this to verify its out-of-band writes through the identity backing are guest-visible
export fn echo(addr: u32) i32 {
    const p: *align(1) i32 = @ptrFromInt(@as(usize, addr));
    return p.*;
}

// write an i32 anywhere in guest memory. The host verifies it out-of-band.
export fn poke(addr: u32, val: i32) void {
    const p: *align(1) i32 = @ptrFromInt(@as(usize, addr));
    p.* = val;
}

// grow linear memory by `pages` pages; 0 on success, -1 (per wasm spec) if the host refuses; e.g. growing into the swap zone
export fn grow(pages: u32) i32 {
    if (@wasmMemoryGrow(0, pages) != -1) return 0;
    return -1;
}

// host-interop scratch: real symbols in the guest's own data section whose addresses the host learns through an exported accessor demonstrating the pattern for host/guest symbol interop
export var scratch: [3]i32 = .{ 0, 0, 0 };

export fn scratchAddr(idx: u32) u32 {
    return @intCast(@intFromPtr(&scratch[idx]));
}

// zone reachability via BOTH addressing forms, so a wasmtime config or
// regression that reintroduces current-size bounds checks fails the suite
export fn zoneLhsStatic() i32 { // folds to: i32.load offset=0xFFFF0000
    const h: *align(1) BlobHead = @ptrFromInt(ZONE_ADDR);
    return h.lhs;
}

export fn zonePokeDynamic(base: u32, val: i32) void { // runtime pointer in the index register
    const h: *align(1) BlobHead = @ptrFromInt(@as(usize, base));
    h.lhs = val;
}

export fn memPages() u32 { // memory.size exactly as the JIT sees it
    return @wasmMemorySize(0);
}
