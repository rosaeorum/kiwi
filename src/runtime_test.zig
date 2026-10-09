const runtime_test = @This();

pub const std_options = base.StdOptions{
    .log_level = .debug,
};

const Position = extern struct { x: f32, y: f32 };
const Velocity = extern struct { x: f32, y: f32 };
const Health = extern struct { current: i32 };

const ComponentColumn = struct {
    blob: Memory.Blob,
    element_size: usize,
    count: usize,
    total_bytes: usize,

    fn init(element_size: usize, count: usize) ?ComponentColumn {
        const raw_total = element_size * count;
        const total_bytes = base.mem.alignForward(usize, raw_total, Memory.binding_slot_size);
        const blob = Memory.Blob.init(total_bytes) orelse return null;
        return .{
            .blob = blob,
            .element_size = element_size,
            .count = count,
            .total_bytes = total_bytes,
        };
    }

    fn deinit(col: *ComponentColumn) void {
        col.blob.deinit();
    }

    fn map(col: *ComponentColumn) ?[]u8 {
        return col.blob.map();
    }

    fn unmap(view: []u8) void {
        Memory.Blob.unmap(view);
    }

    fn pageCount(col: *const ComponentColumn) usize {
        return col.total_bytes / Memory.binding_slot_size;
    }

    fn bindSlot(col: *const ComponentColumn, m: *Memory, slot: usize, page_idx: usize) bool {
        return m.swapBlob(slot, col.blob, page_idx * Memory.binding_slot_size);
    }
};

fn nativeParticleSystem(
    positions: [*]Position,
    velocities: [*]Velocity,
    healths: ?[*]Health,
    count: usize,
) void {
    var i: usize = 0;
    while (i < count) : (i += 1) {
        positions[i].x += velocities[i].x;
        positions[i].y += velocities[i].y;
        if (healths) |h| {
            if (h[i].current > 0) h[i].current -= 1;
        }
    }
}

fn call1(inst: Instance, name: []const u8, a: i32) !i32 {
    var r: [1]i32 = undefined;
    try inst.call(name, &.{a}, &r);
    return r[0];
}

fn expectTrap(inst: Instance, name: []const u8, arg: i32) !void {
    _ = call1(inst, name, arg) catch return;
    return error.ExpectedTrap;
}

pub const guest_a_src: []const u8 =
    base.fmt.comptimePrint(
        \\const std = @import("std");
        \\pub const ZONE_ADDR: usize = 0x{x};
        \\pub const ZONE_LEN: usize = 0x{x};
    , .{ Memory.swap_zone_base_offset, Memory.swap_zone_size }) ++
    \\pub fn zoneBytes() []u8 {
    \\    const p: [*]u8 = @ptrFromInt(ZONE_ADDR);
    \\    return p[0..ZONE_LEN];
    \\}
    \\export fn add() void {
    \\    const z = zoneBytes();
    \\    const lhs = std.mem.readInt(i32, z[0..4], .little);
    \\    const rhs = std.mem.readInt(i32, z[4..8], .little);
    \\    std.mem.writeInt(i32, z[0..4], lhs + rhs, .little);
    \\}
    \\export fn echo(addr: u32) i32 {
    \\    const p: *align(1) i32 = @ptrFromInt(@as(usize, addr));
    \\    return p.*;
    \\}
    \\export fn poke(addr: u32, val: i32) void {
    \\    const p: *align(1) i32 = @ptrFromInt(@as(usize, addr));
    \\    p.* = val;
    \\}
    \\export fn grow(pages: u32) i32 {
    \\    if (@wasmMemoryGrow(0, pages) != -1) return 0;
    \\    return -1;
    \\}
    \\export var scratch: [3]i32 = .{ 0, 0, 0 };
    \\export fn scratchAddr(idx: u32) u32 {
    \\    return @intCast(@intFromPtr(&scratch[idx]));
    \\}
    \\export fn mul2(v: i32) i32 {
    \\    // observable side effect: lets the host prove that cross-instance
    \\    // calls into this module actually land in this instance's memory
    \\    scratch[2] += 1;
    \\    return v * 2;
    \\}
    \\export fn zoneLoadStatic() i32 {
    \\    const p: *align(1) i32 = @ptrFromInt(ZONE_ADDR);
    \\    return p.*;
    \\}
    \\export fn zonePokeDynamic(base: u32, val: i32) void {
    \\    const p: *align(1) i32 = @ptrFromInt(@as(usize, base));
    \\    p.* = val;
    \\}
    \\export fn memPages() u32 {
    \\    return @wasmMemorySize(0);
    \\}
    \\pub const Position = extern struct { x: f32, y: f32 };
    \\pub const Velocity = extern struct { x: f32, y: f32 };
    \\pub const Health = extern struct { current: i32 };
    \\export fn particle_system(
    \\    pos_addr: i32,
    \\    vel_addr: i32,
    \\    health_addr: i32,
    \\    count: i32,
    \\    flags: i32,
    \\) void {
    \\    const positions: [*]Position = @ptrFromInt(@as(usize, @bitCast(pos_addr)));
    \\    const velocities: [*]Velocity = @ptrFromInt(@as(usize, @bitCast(vel_addr)));
    \\    var i: usize = 0;
    \\    while (i < @as(usize, @intCast(count))) : (i += 1) {
    \\        positions[i].x += velocities[i].x;
    \\        positions[i].y += velocities[i].y;
    \\        if ((flags & 1) != 0) {
    \\            const healths: [*]Health = @ptrFromInt(@as(usize, @bitCast(health_addr)));
    \\            if (healths[i].current > 0) healths[i].current -= 1;
    \\        }
    \\    }
    \\}
    ;

pub const guest_b_src: []const u8 =
    \\extern fn mul2(v: i32) i32;
    \\export fn mul2Plus(v: i32) i32 {
    \\    return mul2(v) + 100;
    \\}
    \\pub const Position = extern struct { x: f32, y: f32 };
    \\pub const Velocity = extern struct { x: f32, y: f32 };
    \\pub const Health = extern struct { current: i32 };
    \\export fn particle_system(
    \\    pos_addr: i32,
    \\    vel_addr: i32,
    \\    health_addr: i32,
    \\    count: i32,
    \\    flags: i32,
    \\) void {
    \\    const positions: [*]Position = @ptrFromInt(@as(usize, @bitCast(pos_addr)));
    \\    const velocities: [*]Velocity = @ptrFromInt(@as(usize, @bitCast(vel_addr)));
    \\    var i: usize = 0;
    \\    while (i < @as(usize, @intCast(count))) : (i += 1) {
    \\        positions[i].x += velocities[i].x;
    \\        positions[i].y += velocities[i].y;
    \\        if ((flags & 1) != 0) {
    \\            const healths: [*]Health = @ptrFromInt(@as(usize, @bitCast(health_addr)));
    \\            if (healths[i].current > 0) healths[i].current -= 1;
    \\        }
    \\    }
    \\}
;

test {
    const runtime = try Runtime.init(base.testing.allocator);
    defer runtime.deinit();

    const mod_a = try runtime.addModule(guest_a_wasm);
    const mod_b = try runtime.addModule(guest_b_wasm);

    const inst_a = try runtime.instantiate(mod_a, &.{});
    const inst_b = try runtime.instantiate(mod_b, &.{try inst_a.@"export"("mul2")});

    const mem = inst_a.memory;
    const mem_b = inst_b.memory;
    const mem_b_size_before = mem_b.size;

    // one private memory per instance
    if (mem == mem_b) return error.MemoriesNotDistinct;
    if (mem.base_ptr.? == mem_b.base_ptr.?) return error.MemorySpansOverlap;

    log.debug("guest memory A: base=0x{x} size={d} capacity={d} guard={d}", .{ @intFromPtr(mem.base_ptr.?), mem.size, mem.capacity, mem.guard });
    log.debug("guest memory B: base=0x{x} size={d} capacity={d} guard={d}", .{ @intFromPtr(mem_b.base_ptr.?), mem_b.size, mem_b.capacity, mem_b.guard });
    log.debug("binding region: [0x{x}, 0x{x}) : {d} slots : {d} KiB", .{ Memory.binding_region_base, Memory.wasm_region_size, Memory.max_binding_slots, Memory.binding_slot_size / 1024 });
    log.debug("swap zone (slot {d}): [0x{x}, 0x{x})", .{ Memory.swap_zone_slot, Memory.swap_zone_base_offset, Memory.swap_zone_base_offset + Memory.swap_zone_size });

    // memory export base pointer matches host reservation (both instances)
    {
        const item = try inst_a.@"export"("memory");
        if (item.kind != c.WASMTIME_EXTERN_MEMORY) return error.MemoryExportNotMemory;
        if (c.wasmtime_memory_data(runtime.context(), &item.of.memory) != @as([*c]u8, @ptrCast(mem.base_ptr.?))) return error.BasePointerMismatch;
    }
    {
        const item = try inst_b.@"export"("memory");
        if (item.kind != c.WASMTIME_EXTERN_MEMORY) return error.MemoryExportNotMemory;
        if (c.wasmtime_memory_data(runtime.context(), &item.of.memory) != @as([*c]u8, @ptrCast(mem_b.base_ptr.?))) return error.BasePointerMismatch;
    }

    // modules can see each other B's import resolves into A's
    // instance, proven both by the returned value and by mul2's side effect
    // (a call counter in A's own scratch space)
    {
        const scr2 = try call1(inst_a, "scratchAddr", 2);
        const counter_before = mem.peek32(@intCast(scr2));

        var r: [1]i32 = undefined;
        try inst_b.call("mul2Plus", &.{21}, &r);
        if (r[0] != 142) return error.CrossModuleValueFailed; // 21 * 2 (in A) + 100 (in B)
        if (mem.peek32(@intCast(scr2)) != counter_before + 1) return error.CrossModuleSideEffectFailed;
        log.debug("[link] B.mul2Plus(21) = {d}; A.mul2 executed {d} time(s); instances are linked", .{ r[0], mem.peek32(@intCast(scr2)) });
    }

    // host<->guest access agrees (the host shares the guest VA span)
    const scr0 = try call1(inst_a, "scratchAddr", 0);
    const scr1 = try call1(inst_a, "scratchAddr", 1);

    const val_a: i32 = 0xC0FFEE;
    mem.poke32(@intCast(scr0), val_a);
    const echoed = try call1(inst_a, "echo", scr0);
    log.debug("[oob] host poked {d} @ guest 0x{x}; guest echo read {d}", .{ val_a, scr0, echoed });
    if (echoed != val_a) return error.OobHostToGuestFailed;

    const val_b: i32 = @bitCast(@as(u32, 0xFEEDFACE));
    try inst_a.call("poke", &.{ scr1, val_b }, &.{});
    const seen_b = mem.peek32(@intCast(scr1));
    log.debug("[oob] guest poked {d} @ guest 0x{x}; host peeked {d}", .{ val_b, scr1, seen_b });
    if (seen_b != val_b) return error.OobGuestToHostFailed;

    // memory growth works and fresh pages are identity-backed
    const size_before = mem.size;
    const grow_addr: i32 = @intCast(size_before + 0x40);
    if (try call1(inst_a, "grow", 2) != 0) return error.GrowFailed;
    if (mem.size != size_before + 2 * Memory.wasm_page_size) return error.GrowSizeWrong;
    mem.poke32(@intCast(grow_addr), 0x5151);
    if (try call1(inst_a, "echo", grow_addr) != 0x5151) return error.GrowCommitInvisible;
    log.debug("[grow] +2 pages -> size={d}; fresh pages are identity-backed", .{mem.size});

    if (try call1(inst_a, "grow", 0x10000) != -1) return error.GrowShouldHaveFailed;
    log.debug("[grow] refused to grow past the binding region (returned -1, no trap)", .{});

    // growth is per-memory; instance B's memory is untouched
    if (mem_b.size != mem_b_size_before) return error.GrowBledAcrossMemories;

    // single-slot blob swap roundtrip
    var blob_a = Memory.Blob.init(Memory.swap_zone_size) orelse base.fatal("blobCreate(A)", .{});
    var blob_b = Memory.Blob.init(Memory.swap_zone_size) orelse base.fatal("blobCreate(B)", .{});
    defer blob_a.deinit();
    defer blob_b.deinit();
    {
        const a = blob_a.map() orelse base.fatal("blobMap(A)", .{});
        defer Memory.Blob.unmap(a);
        putI32(a, 0, 10);
        putI32(a, 1, 32);
        const b = blob_b.map() orelse base.fatal("blobMap(B)", .{});
        defer Memory.Blob.unmap(b);
        putI32(b, 0, 7);
        putI32(b, 1, 5);
    }

    if (!mem.swapBlob(Memory.swap_zone_slot, blob_a, 0)) base.fatal("swapBlob(A)", .{});
    try inst_a.call("add", &.{}, &.{});
    {
        const sum = getI32(mem.slotView(Memory.swap_zone_slot), 0);
        const a = blob_a.map() orelse base.fatal("blobMap(A)", .{});
        defer Memory.Blob.unmap(a);
        log.debug("[A] {{10,32}} in -> add() -> zone[0]={d} (host VA); blob A via map: {{{d}, {d}}}", .{ sum, getI32(a, 0), getI32(a, 1) });
        if (sum != 42 or getI32(a, 0) != 42 or getI32(a, 1) != 32) return error.RoundtripAFailed;
    }

    if (!mem.swapBlob(Memory.swap_zone_slot, blob_b, 0)) base.fatal("swapBlob(B)", .{});
    try inst_a.call("add", &.{}, &.{});
    {
        const sum = getI32(mem.slotView(Memory.swap_zone_slot), 0);
        const b = blob_b.map() orelse base.fatal("blobMap(B)", .{});
        defer Memory.Blob.unmap(b);
        log.debug("[B] {{7,5}} in   -> add() -> zone[0]={d} (host VA); blob B via map: {{{d}, {d}}}", .{ sum, getI32(b, 0), getI32(b, 1) });
        if (sum != 12 or getI32(b, 0) != 12 or getI32(b, 1) != 5) return error.RoundtripBFailed;
    }

    // swapped-out blob and guest data are intact
    {
        const a = blob_a.map() orelse base.fatal("blobMap(A post-swap)", .{});
        defer Memory.Blob.unmap(a);
        if (getI32(a, 0) != 42 or getI32(a, 1) != 32) return error.SwappedOutBlobMutated;
        log.debug("blob A (swapped out) still {{{d}, {d}}} via host view; guest data intact at 0x{x}, 0x{x}, 0x{x}", .{ getI32(a, 0), getI32(a, 1), scr0, scr1, grow_addr });
    }
    if (mem.peek32(@intCast(scr0)) != val_a) return error.GuestRegionMutated;
    if (mem.peek32(@intCast(scr1)) != val_b) return error.GuestRegionMutated;
    if (mem.peek32(@intCast(grow_addr)) != 0x5151) return error.GuestRegionMutated;

    log.debug("OK: zero-copy roundtrip complete", .{});

    // out-of-bounds and parked-zone traps
    try expectTrap(inst_a, "echo", @intCast(mem.size + 0x1000));
    try expectTrap(inst_a, "echo", 0x7FFF_FFFC);
    try expectTrap(inst_a, "echo", @bitCast(@as(u32, @intCast(Memory.swap_zone_base_offset - 4))));

    if (!mem.parkSlot(Memory.swap_zone_slot)) return error.ZoneParkFailed;
    try expectTrap(inst_a, "echo", @bitCast(@as(u32, @intCast(Memory.swap_zone_base_offset))));
    {
        var trapped = false;
        _ = inst_a.call("add", &.{}, &.{}) catch {
            trapped = true;
        };
        if (!trapped) return error.ParkedZoneDidNotTrap;
    }

    if (!mem.unparkSlot(Memory.swap_zone_slot)) return error.ZoneUnparkFailed;

    {
        var r: [1]i32 = undefined;
        try inst_a.call("memPages", &.{}, &r);
        if (r[0] != @as(i32, @intCast(mem.size / Memory.wasm_page_size))) return error.MemSizeMismatch;
    }

    // static-offset and dynamic-index zone addressing
    var blob_test = Memory.Blob.init(Memory.swap_zone_size) orelse base.fatal("blobCreate(test)", .{});
    defer blob_test.deinit();
    {
        const v = blob_test.map() orelse base.fatal("blobMap(test)", .{});
        defer Memory.Blob.unmap(v);
        putI32(v, 0, 100);
        putI32(v, 1, 200);
    }
    if (!mem.swapBlob(Memory.swap_zone_slot, blob_test, 0)) base.fatal("swapBlob(test)", .{});

    {
        var r: [1]i32 = undefined;
        try inst_a.call("zoneLoadStatic", &.{}, &r);
        if (r[0] != 100) return error.ZoneStaticReadFailed;
    }

    try inst_a.call("zonePokeDynamic", &.{ @bitCast(@as(u32, @intCast(Memory.swap_zone_base_offset))), 999 }, &.{});

    {
        const v = blob_test.map() orelse base.fatal("blobMap(test post)", .{});
        defer Memory.Blob.unmap(v);
        if (getI32(v, 0) != 999) return error.ZoneDynamicWriteFailed;
    }

    log.debug("OK: both static-offset and dynamic-index zone addressing behave as expected.", .{});

    const entity_count: usize = 1000;

    var col_pos = ComponentColumn.init(@sizeOf(Position), entity_count) orelse base.fatal("col_pos init", .{});
    var col_vel = ComponentColumn.init(@sizeOf(Velocity), entity_count) orelse base.fatal("col_vel init", .{});
    var col_health = ComponentColumn.init(@sizeOf(Health), entity_count) orelse base.fatal("col_health init", .{});
    defer col_pos.deinit();
    defer col_vel.deinit();
    defer col_health.deinit();

    log.debug("[multi-bind] {d} entities, {d} pages/col (pos={}, vel={}, health={})", .{
        entity_count,
        col_pos.pageCount(),
        col_pos.total_bytes,
        col_vel.total_bytes,
        col_health.total_bytes,
    });

    // initialise test data
    {
        const pv = col_pos.map() orelse base.fatal("col_pos map", .{});
        defer ComponentColumn.unmap(pv);
        const vv = col_vel.map() orelse base.fatal("col_vel map", .{});
        defer ComponentColumn.unmap(vv);
        const hv = col_health.map() orelse base.fatal("col_health map", .{});
        defer ComponentColumn.unmap(hv);

        const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
        const velocities: [*]Velocity = @ptrCast(@alignCast(vv.ptr));
        const healths: [*]Health = @ptrCast(@alignCast(hv.ptr));

        for (0..entity_count) |i| {
            positions[i] = .{ .x = 0, .y = 0 };
            velocities[i] = .{ .x = 1, .y = 2 };
            healths[i] = .{ .current = 10 };
        }
    }

    // dispatch with all three components (flags = 1, health present)
    log.debug("[multi-bind] dispatch archetype [Pos, Vel, Health]; flags=1", .{});
    {
        if (!col_pos.bindSlot(mem, 0, 0)) base.fatal("bind pos slot 0", .{});
        if (!col_vel.bindSlot(mem, 1, 0)) base.fatal("bind vel slot 1", .{});
        if (!col_health.bindSlot(mem, 2, 0)) base.fatal("bind health slot 2", .{});

        try inst_a.call("particle_system", &.{ Memory.slotAddr(0), Memory.slotAddr(1), Memory.slotAddr(2), @as(i32, @intCast(entity_count)), 1 }, &.{});
    }

    // verify results
    {
        const pv = col_pos.map() orelse base.fatal("col_pos map (verify)", .{});
        defer ComponentColumn.unmap(pv);
        const hv = col_health.map() orelse base.fatal("col_health map (verify)", .{});
        defer ComponentColumn.unmap(hv);

        const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
        const healths: [*]Health = @ptrCast(@alignCast(hv.ptr));

        var ok = true;
        for (0..entity_count) |i| {
            if (positions[i].x != 1 or positions[i].y != 2) {
                ok = false;
                log.err("pos[{d}] = {{{d},{d}}}, expected {{1,2}}", .{ i, positions[i].x, positions[i].y });
                break;
            }
            if (healths[i].current != 9) {
                ok = false;
                log.err("health[{d}] = {d}, expected 9", .{ i, healths[i].current });
                break;
            }
        }
        if (!ok) return error.MultiBindWithHealthFailed;
        log.debug("[multi-bind] OK: pos={{1,2}} health=9 for all {d} entities", .{entity_count});
    }

    // dispatch without health (flags = 0, health slot parked)
    log.debug("[multi-bind] dispatch archetype [Pos, Vel]; flags=0, health slot parked", .{});

    // reset positions
    {
        const pv = col_pos.map() orelse base.fatal("col_pos map (reset)", .{});
        defer ComponentColumn.unmap(pv);
        const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
        for (0..entity_count) |i| {
            positions[i] = .{ .x = 0, .y = 0 };
        }
    }

    {
        if (!col_pos.bindSlot(mem, 0, 0)) base.fatal("rebind pos slot 0", .{});
        if (!col_vel.bindSlot(mem, 1, 0)) base.fatal("rebind vel slot 1", .{});
        // park slot 2; health is optional, not present in this archetype
        if (!mem.parkSlot(2)) base.fatal("park slot 2", .{});

        // health_addr = 0 means "not bound"; flags = 0 means no health branch
        try inst_a.call("particle_system", &.{ Memory.slotAddr(0), Memory.slotAddr(1), 0, @as(i32, @intCast(entity_count)), 0 }, &.{});
    }

    // verify positions updated, health unchanged
    {
        const pv = col_pos.map() orelse base.fatal("col_pos map (verify no-health)", .{});
        defer ComponentColumn.unmap(pv);
        const hv = col_health.map() orelse base.fatal("col_health map (verify no-health)", .{});
        defer ComponentColumn.unmap(hv);

        const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
        const healths: [*]Health = @ptrCast(@alignCast(hv.ptr));

        var ok = true;
        for (0..entity_count) |i| {
            if (positions[i].x != 1 or positions[i].y != 2) {
                ok = false;
                log.err("pos[{d}] = {{{d},{d}}}, expected {{1,2}}", .{ i, positions[i].x, positions[i].y });
                break;
            }
            if (healths[i].current != 9) {
                ok = false;
                log.err("health[{d}] = {d}, expected 9 (unchanged)", .{ i, healths[i].current });
                break;
            }
        }
        if (!ok) return error.MultiBindNoHealthFailed;
        log.debug("[multi-bind] OK: pos={{1,2}} health unchanged=9 (optional component skipped)", .{});
    }

    // verify unbound slot traps on access
    try expectTrap(inst_a, "echo", @bitCast(@as(u32, @intCast(Memory.binding_region_base + 2 * Memory.binding_slot_size))));

    // restore slot 2 for cleanliness
    _ = mem.unparkSlot(2);

    // multi-page column iteration test
    {
        const big_count: usize = @divFloor(Memory.binding_slot_size, @sizeOf(Position)) + 500;
        var col_big = ComponentColumn.init(@sizeOf(Position), big_count) orelse base.fatal("col_big init", .{});
        defer col_big.deinit();

        const pages = col_big.pageCount();
        log.debug("[multi-bind] big column: {d} entities, {d} bytes, {d} pages", .{ big_count, col_big.total_bytes, pages });
        if (pages < 2) return error.BigColumnShouldSpanMultiplePages;

        var col_big_vel = ComponentColumn.init(@sizeOf(Velocity), big_count) orelse base.fatal("col_big_vel init", .{});
        defer col_big_vel.deinit();

        {
            const pv = col_big.map() orelse base.fatal("col_big map", .{});
            defer ComponentColumn.unmap(pv);
            const vv = col_big_vel.map() orelse base.fatal("col_big_vel map", .{});
            defer ComponentColumn.unmap(vv);

            const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
            const velocities: [*]Velocity = @ptrCast(@alignCast(vv.ptr));

            for (0..big_count) |i| {
                positions[i] = .{ .x = 0, .y = 0 };
                velocities[i] = .{ .x = 3, .y = 4 };
            }
        }

        const ents_per_page = @divFloor(Memory.binding_slot_size, @sizeOf(Position));
        for (0..pages) |page_idx| {
            const page_start = page_idx * ents_per_page;
            const page_end = @min(page_start + ents_per_page, big_count);
            const page_count = page_end - page_start;

            if (!col_big.bindSlot(mem, 0, page_idx)) base.fatal("bind big pos page {d}", .{page_idx});
            if (!col_big_vel.bindSlot(mem, 1, page_idx)) base.fatal("bind big vel page {d}", .{page_idx});

            try inst_a.call("particle_system", &.{ Memory.slotAddr(0), Memory.slotAddr(1), 0, @as(i32, @intCast(page_count)), 0 }, &.{});
        }

        {
            const pv = col_big.map() orelse base.fatal("col_big map (verify)", .{});
            defer ComponentColumn.unmap(pv);
            const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));

            var ok = true;
            for (0..big_count) |i| {
                if (positions[i].x != 3 or positions[i].y != 4) {
                    ok = false;
                    log.err("big pos[{d}] = {{{d},{d}}}, expected {{3,4}}", .{ i, positions[i].x, positions[i].y });
                    break;
                }
            }
            if (!ok) return error.MultiPageIterationFailed;
            log.debug("[multi-bind] OK: paged {d} entities across {d} pages, all positions={{3,4}}", .{ big_count, pages });
        }
    }

    // dispatch B's particle_system over B's memory, using B's own binding slots
    {
        const b_count: usize = 64;
        var col_b_pos = ComponentColumn.init(@sizeOf(Position), b_count) orelse base.fatal("col_b_pos init", .{});
        var col_b_vel = ComponentColumn.init(@sizeOf(Velocity), b_count) orelse base.fatal("col_b_vel init", .{});
        defer col_b_pos.deinit();
        defer col_b_vel.deinit();

        {
            const pv = col_b_pos.map() orelse base.fatal("col_b_pos map", .{});
            defer ComponentColumn.unmap(pv);
            const vv = col_b_vel.map() orelse base.fatal("col_b_vel map", .{});
            defer ComponentColumn.unmap(vv);
            const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
            const velocities: [*]Velocity = @ptrCast(@alignCast(vv.ptr));
            for (0..b_count) |i| {
                positions[i] = .{ .x = 0, .y = 0 };
                velocities[i] = .{ .x = 5, .y = 6 };
            }
        }

        if (!col_b_pos.bindSlot(mem_b, 0, 0)) base.fatal("bind b pos slot 0", .{});
        if (!col_b_vel.bindSlot(mem_b, 1, 0)) base.fatal("bind b vel slot 1", .{});

        try inst_b.call("particle_system", &.{ Memory.slotAddr(0), Memory.slotAddr(1), 0, @as(i32, @intCast(b_count)), 0 }, &.{});

        const pv = col_b_pos.map() orelse base.fatal("col_b_pos map (verify)", .{});
        defer ComponentColumn.unmap(pv);
        const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
        var ok = true;
        for (0..b_count) |i| {
            if (positions[i].x != 5 or positions[i].y != 6) {
                ok = false;
                break;
            }
        }
        if (!ok) return error.SecondModuleSystemFailed;
        log.debug("[multi-module] OK: B's particle_system advanced {d} entities in B's memory via B's slots", .{b_count});
    }

    // guest data still intact after multi-binding
    if (mem.peek32(@intCast(scr0)) != val_a) return error.GuestRegionMutatedAfterMultiBind;
    if (mem.peek32(@intCast(scr1)) != val_b) return error.GuestRegionMutatedAfterMultiBind;
    if (mem.peek32(@intCast(grow_addr)) != 0x5151) return error.GuestRegionMutatedAfterMultiBind;

    log.debug("OK: multi-module, multi-memory dispatch complete; invariants preserved", .{});
}

pub fn main(init: base.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;

    const runtime = try Runtime.init(gpa);
    defer runtime.deinit();

    const module = try runtime.addModule(guest_a_wasm);
    const inst = try runtime.instantiate(module, &.{});
    const f_particle = try inst.func("particle_system");
    const mem = inst.memory;

    const entity_count: usize = 100_000;
    const warmup_iters: usize = 200;
    const bench_iters: usize = 10_000;

    log.info("benchmark: {d} entities, {d} warmup + {d} measured iterations", .{ entity_count, warmup_iters, bench_iters });

    // native baseline
    {
        const positions = try gpa.alloc(Position, entity_count);
        defer gpa.free(positions);
        const velocities = try gpa.alloc(Velocity, entity_count);
        defer gpa.free(velocities);
        const healths = try gpa.alloc(Health, entity_count);
        defer gpa.free(healths);

        for (0..entity_count) |i| {
            positions[i] = .{ .x = 0, .y = 0 };
            velocities[i] = .{ .x = 1, .y = 2 };
            healths[i] = .{ .current = 100 };
        }

        for (0..warmup_iters) |_| {
            nativeParticleSystem(positions.ptr, velocities.ptr, healths.ptr, entity_count);
        }

        const start = base.Io.Clock.awake.now(io);
        for (0..bench_iters) |_| {
            nativeParticleSystem(positions.ptr, velocities.ptr, healths.ptr, entity_count);
        }
        const end = base.Io.Clock.awake.now(io);
        const elapsed_ns = start.durationTo(end).nanoseconds;

        const ns_per_iter = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(bench_iters));
        const ns_per_entity = ns_per_iter / @as(f64, @floatFromInt(entity_count));

        log.info("native:           {d:>12.2} ns/iter  ({d:>6.2} ns/entity)", .{ ns_per_iter, ns_per_entity });
    }

    // guest with bind-once (measures call + compute overhead)
    {
        var col_pos = ComponentColumn.init(@sizeOf(Position), entity_count) orelse base.fatal("bench col_pos", .{});
        var col_vel = ComponentColumn.init(@sizeOf(Velocity), entity_count) orelse base.fatal("bench col_vel", .{});
        var col_health = ComponentColumn.init(@sizeOf(Health), entity_count) orelse base.fatal("bench col_health", .{});
        defer col_pos.deinit();
        defer col_vel.deinit();
        defer col_health.deinit();

        {
            const pv = col_pos.map() orelse base.fatal("bench map pos", .{});
            defer ComponentColumn.unmap(pv);
            const vv = col_vel.map() orelse base.fatal("bench map vel", .{});
            defer ComponentColumn.unmap(vv);
            const hv = col_health.map() orelse base.fatal("bench map health", .{});
            defer ComponentColumn.unmap(hv);

            const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
            const velocities: [*]Velocity = @ptrCast(@alignCast(vv.ptr));
            const healths: [*]Health = @ptrCast(@alignCast(hv.ptr));

            for (0..entity_count) |i| {
                positions[i] = .{ .x = 0, .y = 0 };
                velocities[i] = .{ .x = 1, .y = 2 };
                healths[i] = .{ .current = 100 };
            }
        }

        if (!col_pos.bindSlot(mem, 0, 0)) base.fatal("bench bind pos", .{});
        if (!col_vel.bindSlot(mem, 1, 0)) base.fatal("bench bind vel", .{});
        if (!col_health.bindSlot(mem, 2, 0)) base.fatal("bench bind health", .{});

        const args = [_]i32{ Memory.slotAddr(0), Memory.slotAddr(1), Memory.slotAddr(2), @as(i32, @intCast(entity_count)), 1 };

        for (0..warmup_iters) |_| {
            try runtime.call(f_particle, &args, &.{});
        }

        const start = base.Io.Clock.awake.now(io);
        for (0..bench_iters) |_| {
            try runtime.call(f_particle, &args, &.{});
        }
        const end = base.Io.Clock.awake.now(io);
        const elapsed_ns = start.durationTo(end).nanoseconds;

        const ns_per_iter = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(bench_iters));
        const ns_per_entity = ns_per_iter / @as(f64, @floatFromInt(entity_count));

        log.info("guest (bind once): {d:>12.2} ns/iter  ({d:>6.2} ns/entity)", .{ ns_per_iter, ns_per_entity });
    }

    // guest with rebind each iteration (measures full dispatch cost)
    {
        var col_pos = ComponentColumn.init(@sizeOf(Position), entity_count) orelse base.fatal("bench2 col_pos", .{});
        var col_vel = ComponentColumn.init(@sizeOf(Velocity), entity_count) orelse base.fatal("bench2 col_vel", .{});
        var col_health = ComponentColumn.init(@sizeOf(Health), entity_count) orelse base.fatal("bench2 col_health", .{});
        defer col_pos.deinit();
        defer col_vel.deinit();
        defer col_health.deinit();

        {
            const pv = col_pos.map() orelse base.fatal("bench2 map pos", .{});
            defer ComponentColumn.unmap(pv);
            const vv = col_vel.map() orelse base.fatal("bench2 map vel", .{});
            defer ComponentColumn.unmap(vv);
            const hv = col_health.map() orelse base.fatal("bench2 map health", .{});
            defer ComponentColumn.unmap(hv);

            const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
            const velocities: [*]Velocity = @ptrCast(@alignCast(vv.ptr));
            const healths: [*]Health = @ptrCast(@alignCast(hv.ptr));

            for (0..entity_count) |i| {
                positions[i] = .{ .x = 0, .y = 0 };
                velocities[i] = .{ .x = 1, .y = 2 };
                healths[i] = .{ .current = 100 };
            }
        }

        const args = [_]i32{ Memory.slotAddr(0), Memory.slotAddr(1), Memory.slotAddr(2), @as(i32, @intCast(entity_count)), 1 };

        for (0..warmup_iters) |_| {
            _ = col_pos.bindSlot(mem, 0, 0);
            _ = col_vel.bindSlot(mem, 1, 0);
            _ = col_health.bindSlot(mem, 2, 0);
            try runtime.call(f_particle, &args, &.{});
        }

        const start = base.Io.Clock.awake.now(io);
        for (0..bench_iters) |_| {
            _ = col_pos.bindSlot(mem, 0, 0);
            _ = col_vel.bindSlot(mem, 1, 0);
            _ = col_health.bindSlot(mem, 2, 0);
            try runtime.call(f_particle, &args, &.{});
        }
        const end = base.Io.Clock.awake.now(io);
        const elapsed_ns = start.durationTo(end).nanoseconds;

        const ns_per_iter = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(bench_iters));
        const ns_per_entity = ns_per_iter / @as(f64, @floatFromInt(entity_count));

        log.info("guest (rebind):    {d:>12.2} ns/iter  ({d:>6.2} ns/entity)", .{ ns_per_iter, ns_per_entity });
    }

    log.info("benchmark complete.", .{});
}

const kiwi = @import("module/kiwi.zig");

const guest_a_wasm: []const u8 = @embedFile("guest_a.wasm");
const guest_b_wasm: []const u8 = @embedFile("guest_b.wasm");

const base = kiwi.base;
const Runtime = kiwi.Runtime;
const c = kiwi.Runtime.c;
const Memory = Runtime.Memory;
const Instance = Runtime.Instance;
const getI32 = Memory.getI32;
const putI32 = Memory.putI32;

const log = kiwi.base.log.scoped(.wasm);
