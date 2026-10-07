// Static ABI with the host:
// * The linear memory is a *dynamic* memory
//   never declare min == max; the host must reject static heaps because with min==max the JIT bounds-checks against the static size and the zone below would be unreachable
// * The swap zone is the final 64kb of the 4gb linear-memory region: [0xFFFF0000, 0x1_0000_0000). Same fixed offset in every module.
// * Guest stack, globals, data and heap live at the bottom of memory and may grow up to 0xFFFF0000 — no placement directives needed anywhere.
// * Guest code reaches the zone pointer-style: address in the index register, tiny static offsets.
//   The 4gb reservation + guard covers every address an unchecked access can compute,
//   so the JIT elides bounds checks and the zone is reachable from the first instruction regardless of what memory.size reports.

const std = @import("std");

pub const ZONE_ADDR: usize = 0xFFFF_0000;
pub const ZONE_LEN: usize = 64 * 1024;

pub const BlobHead = extern struct { lhs: i32, rhs: i32 };

// IMPORTANT: this is deliberately a mutable global, NOT a comptime constant
//
// with a comptime address, Zig/LLVM would fold the whole thing into `i32.load offset=0xFFFF0000`;
// the JIT must then explicitly bounds-check large static offsets against the *current* memory size,
// the reservation+guard window cannot prove them safe, and the access would trap
//
// a mutable global lives in linear memory, so its value is loaded at runtime,
// and the zone address lands in the index register, where full bounds-check elision applies
var zone_base: usize = ZONE_ADDR;

inline fn zone() *align(1) BlobHead {
    return @ptrFromInt(zone_base);
}

/// swap zone layout: { lhs: i32, rhs: i32 } - lhs += rhs.
export fn add() void {
    const h = zone();
    h.lhs = h.lhs + h.rhs;
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
var scratch: [3]i32 = .{ 0, 0, 0 };

export fn scratchAddr(idx: u32) u32 {
    return @intCast(@intFromPtr(&scratch[idx]));
}
