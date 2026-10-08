const memswap_proof_of_concept = @This();

const std = @import("std");
const builtin = @import("builtin");
const c = @import("module/wasm.zig");

const guest_wasm: []const u8 = @embedFile("guest.wasm");

const log_errs = !@import("builtin").is_test;

const log = std.log.scoped(.wasm);

const wasm_page_size: usize = 64 * 1024;
const wasm_region_size: usize = 1 << 32;
const swap_zone_size: usize = wasm_page_size * 16;
const swap_zone_base_offset: usize = wasm_region_size - swap_zone_size;

pub const guest_src: []const u8 =
    std.fmt.comptimePrint(
        \\const std = @import("std");
        \\pub const ZONE_ADDR: usize = 0x{x};
        \\pub const ZONE_LEN: usize = 0x{x};
    , .{ swap_zone_base_offset, swap_zone_size }) ++
    // the host swap zone, as the guest sees it: one fixed []u8 window
    \\pub fn zoneBytes() []u8 {
    \\    const p: [*]u8 = @ptrFromInt(ZONE_ADDR);
    \\    return p[0..ZONE_LEN];
    \\}
    // stand-in for an ecs system, operates on swapped zone data as bytes
    \\export fn add() void {
    \\    const z = zoneBytes();
    \\    const lhs = std.mem.readInt(i32, z[0..4], .little);
    \\    const rhs = std.mem.readInt(i32, z[4..8], .little);
    \\    std.mem.writeInt(i32, z[0..4], lhs + rhs, .little);
    \\}
    // read an i32 from anywhere in guest memory
    // the host uses this to verify its out-of-band writes through the identity backing are guest-visible
    \\export fn echo(addr: u32) i32 {
    \\    const p: *align(1) i32 = @ptrFromInt(@as(usize, addr));
    \\    return p.*;
    \\}
    // write an i32 anywhere in guest memory
    // the host verifies it out-of-band
    \\export fn poke(addr: u32, val: i32) void {
    \\    const p: *align(1) i32 = @ptrFromInt(@as(usize, addr));
    \\    p.* = val;
    \\}
    // grow linear memory by `pages` pages;
    // 0 on success, -1 (per wasm spec) if the host refuses; e.g. growing into the swap zone
    \\export fn grow(pages: u32) i32 {
    \\    if (@wasmMemoryGrow(0, pages) != -1) return 0;
    \\    return -1;
    \\}
    // tests guest's own data section
    \\export var scratch: [3]i32 = .{ 0, 0, 0 };
    \\export fn scratchAddr(idx: u32) u32 {
    \\    return @intCast(@intFromPtr(&scratch[idx]));
    \\}
    // zone reachability via BOTH addressing forms, so a wasmtime config or
    // regression that reintroduces current-size bounds checks fails the suite
    \\export fn zoneLoadStatic() i32 { // folds to: i32.load offset=0xFFFF0000
    \\    const p: *align(1) i32 = @ptrFromInt(ZONE_ADDR);
    \\    return p.*;
    \\}
    // test runtime pointer in the index register
    \\export fn zonePokeDynamic(base: u32, val: i32) void {
    \\    const p: *align(1) i32 = @ptrFromInt(@as(usize, base));
    \\    p.* = val;
    \\}
    // returns memory.size exactly as the JIT sees it
    \\export fn memPages() u32 {
    \\    return @wasmMemorySize(0);
    \\}
    ;

fn i32At(base: [*]u8, off: usize) *align(1) i32 {
    return @ptrCast(base + off);
}

/// host alias of the swap zone inside the guest's linear-memory reservation;
/// whatever blob is swapped in is directly reachable through this view
fn zoneView(base: [*]u8) []u8 {
    return (base + swap_zone_base_offset)[0..swap_zone_size];
}

/// typed access only through byte views; wasm linear memory is little-endian
fn getI32(view: []const u8, idx: usize) i32 {
    return std.mem.readInt(i32, view[idx * 4 ..][0..4], .little);
}

fn putI32(view: []u8, idx: usize, val: i32) void {
    std.mem.writeInt(i32, view[idx * 4 ..][0..4], val, .little);
}

const Platform = switch (builtin.os.tag) {
    .windows => struct {
        const HANDLE = ?*anyopaque;
        const BOOL = i32;
        const DWORD = u32;

        const INVALID_HANDLE_VALUE: HANDLE = @ptrFromInt(std.math.maxInt(usize));

        const MEM_RESERVE: DWORD = 0x00002000;
        const MEM_RELEASE: DWORD = 0x00008000;
        const MEM_RESERVE_PLACEHOLDER: DWORD = 0x00040000;
        const MEM_PRESERVE_PLACEHOLDER: DWORD = 0x00000002;
        const MEM_REPLACE_PLACEHOLDER: DWORD = 0x00004000;
        const PAGE_NOACCESS: DWORD = 0x01;
        const PAGE_READWRITE: DWORD = 0x04;
        const FILE_MAP_READ: DWORD = 0x0001;
        const FILE_MAP_ALL_ACCESS: DWORD = 0x000F001F;

        extern "kernel32" fn GetCurrentProcess() callconv(.winapi) HANDLE;
        extern "kernel32" fn CloseHandle(h: HANDLE) callconv(.winapi) BOOL;
        extern "kernel32" fn VirtualFree(addr: ?*anyopaque, size: usize, free_type: DWORD) callconv(.winapi) BOOL;
        extern "kernel32" fn CreateFileMappingW(file: HANDLE, attrs: ?*const anyopaque, protect: DWORD, max_high: DWORD, max_low: DWORD, name: ?[*:0]const u16) callconv(.winapi) HANDLE;
        extern "kernel32" fn MapViewOfFile(section: HANDLE, access: DWORD, off_high: DWORD, off_low: DWORD, bytes: usize) callconv(.winapi) ?*anyopaque;
        extern "kernel32" fn UnmapViewOfFile(base: ?*anyopaque) callconv(.winapi) BOOL;
        extern "kernel32" fn GetModuleHandleW(name: ?[*:0]const u16) callconv(.winapi) HANDLE;
        extern "kernel32" fn GetProcAddress(module: HANDLE, procname: [*:0]const u8) callconv(.winapi) ?*const anyopaque;
        extern "kernel32" fn GetTempPathW(len: DWORD, buf: [*]u16) callconv(.winapi) DWORD;
        extern "kernel32" fn GetTempFileNameW(path: [*]const u16, prefix: [*]const u16, unique: DWORD, out: [*]u16) callconv(.winapi) DWORD;
        extern "kernel32" fn CreateFileW(path: [*]const u16, access: DWORD, share: DWORD, security: ?*const anyopaque, creation: DWORD, flags: DWORD, template: HANDLE) callconv(.winapi) HANDLE;
        extern "kernel32" fn SetFilePointerEx(file: HANDLE, dist: i64, out: ?*i64, method: DWORD) callconv(.winapi) BOOL;
        extern "kernel32" fn SetEndOfFile(file: HANDLE) callconv(.winapi) BOOL;

        const VirtualAlloc2Fn = fn (process: HANDLE, base: ?*anyopaque, size: usize, alloc_type: DWORD, protect: DWORD, ext: ?*const anyopaque, ext_count: DWORD) callconv(.winapi) ?*anyopaque;
        const MapViewOfFile3Fn = fn (section: HANDLE, process: HANDLE, base: ?*anyopaque, offset: u64, view_size: usize, alloc_type: DWORD, protect: DWORD, ext: ?*const anyopaque, ext_count: DWORD) callconv(.winapi) ?*anyopaque;
        const UnmapViewOfFileExFn = fn (base: ?*anyopaque, flags: DWORD) callconv(.winapi) BOOL;

        var VirtualAlloc2: ?*const VirtualAlloc2Fn = null;
        var MapViewOfFile3: ?*const MapViewOfFile3Fn = null;
        var UnmapViewOfFileEx: ?*const UnmapViewOfFileExFn = null;

        const kernel32_name: ["kernel32.dll".len:0]u16 = .{ 'k', 'e', 'r', 'n', 'e', 'l', '3', '2', '.', 'd', 'l', 'l' };
        const kernelbase_name: ["kernelbase.dll".len:0]u16 = .{ 'k', 'e', 'r', 'n', 'e', 'l', 'b', 'a', 's', 'e', '.', 'd', 'l', 'l' };

        fn proc(comptime name: [:0]const u8, comptime Fn: type) ?*const Fn {
            const k32 = GetModuleHandleW(&kernel32_name) orelse return null;
            if (GetProcAddress(k32, name)) |s| return @ptrCast(@alignCast(s));
            if (GetModuleHandleW(&kernelbase_name)) |kb| {
                if (GetProcAddress(kb, name)) |s| return @ptrCast(@alignCast(s));
            }
            return null;
        }

        pub fn init() void {
            VirtualAlloc2 = proc("VirtualAlloc2", VirtualAlloc2Fn);
            MapViewOfFile3 = proc("MapViewOfFile3", MapViewOfFile3Fn);
            UnmapViewOfFileEx = proc("UnmapViewOfFileEx", UnmapViewOfFileExFn);
            if (VirtualAlloc2 == null or MapViewOfFile3 == null or UnmapViewOfFileEx == null)
                fatal("windows: memory placeholders required but unavailable (VirtualAlloc2/MapViewOfFile3/UnmapViewOfFileEx); need win10 1803+ or wine >= 8.10", .{});
            log.debug("[windows] swap path: placeholders (VirtualAlloc2/MapViewOfFile3)", .{});
        }

        pub const State = struct {
            guest_section: HANDLE = null,
            zero_section: HANDLE = null,
        };

        fn makeFileSection(len: usize) ?HANDLE {
            var dir: [260]u16 = undefined;
            var path: [260]u16 = undefined;
            const prefix = [3]u16{ 'w', 'z', 's' };
            const n = GetTempPathW(dir.len, &dir);
            if (n == 0 or n + 14 > dir.len) return null;
            if (GetTempFileNameW(&dir, &prefix, 0, &path) == 0) return null;
            const GENERIC_READ: DWORD = 0x80000000;
            const GENERIC_WRITE: DWORD = 0x40000000;
            const OPEN_EXISTING: DWORD = 3;
            const FILE_ATTRIBUTE_TEMPORARY: DWORD = 0x00000100;
            const FILE_FLAG_DELETE_ON_CLOSE: DWORD = 0x04000000;
            const FILE_BEGIN: DWORD = 0;
            const file = CreateFileW(&path, GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_DELETE_ON_CLOSE, null);
            if (file == null or file == INVALID_HANDLE_VALUE) return null;
            if (SetFilePointerEx(file, @intCast(len), null, FILE_BEGIN) == 0 or SetEndOfFile(file) == 0) {
                _ = CloseHandle(file);
                return null;
            }
            const sec = CreateFileMappingW(file, null, PAGE_READWRITE, @truncate(len >> 32), @truncate(len), null) orelse {
                _ = CloseHandle(file);
                return null;
            };
            _ = CloseHandle(file);
            return sec;
        }

        pub fn reserveSpan(st: *State, span: usize) ?[*]u8 {
            st.guest_section = makeFileSection(swap_zone_base_offset) orelse return null;
            st.zero_section = CreateFileMappingW(INVALID_HANDLE_VALUE, null, PAGE_READWRITE, 0, @truncate(swap_zone_size), null);
            if (st.zero_section == null) {
                _ = CloseHandle(st.guest_section.?);
                st.* = .{};
                return null;
            }

            if (VirtualAlloc2.?(GetCurrentProcess(), null, span, MEM_RESERVE | MEM_RESERVE_PLACEHOLDER, PAGE_NOACCESS, null, 0)) |base|
                return @ptrCast(base);
            _ = CloseHandle(st.zero_section.?);
            _ = CloseHandle(st.guest_section.?);
            st.* = .{};
            return null;
        }

        fn splitPlaceholder(at: [*]u8, len: usize) bool {
            return VirtualFree(@ptrCast(at), len, MEM_RELEASE | MEM_PRESERVE_PLACEHOLDER) != 0;
        }

        fn mapSectionView(section: HANDLE, at: [*]u8, section_off: usize, len: usize) bool {
            const p = MapViewOfFile3.?(section, GetCurrentProcess(), @ptrCast(at), section_off, len, MEM_REPLACE_PLACEHOLDER, PAGE_READWRITE, null, 0);
            return p != null and @intFromPtr(p.?) == @intFromPtr(at);
        }

        pub fn commitGuestPages(st: *State, at: [*]u8, guest_off: usize, len: usize) bool {
            if (!splitPlaceholder(at, len)) return false;
            return mapSectionView(st.guest_section.?, at, guest_off, len);
        }

        pub fn commitSwapZone(st: *State, zone: []u8) bool {
            if (!splitPlaceholder(zone.ptr, zone.len)) return false;
            return mapSectionView(st.zero_section.?, zone.ptr, 0, zone.len);
        }

        pub const Blob = struct { section: HANDLE, len: usize };

        pub fn blobCreate(len: usize) ?Blob {
            const section = CreateFileMappingW(INVALID_HANDLE_VALUE, null, PAGE_READWRITE, @truncate(len >> 32), @truncate(len), null) orelse return null;
            return .{ .section = section, .len = len };
        }

        pub fn blobDestroy(blob: Blob) void {
            _ = CloseHandle(blob.section);
        }

        pub fn blobMap(blob: Blob) ?[]u8 {
            const v = MapViewOfFile(blob.section, FILE_MAP_ALL_ACCESS, 0, 0, 0) orelse return null;
            const p: [*]u8 = @ptrCast(v);
            return p[0..blob.len];
        }

        pub fn blobUnmap(view: []u8) void {
            _ = UnmapViewOfFile(@ptrCast(view.ptr));
        }

        pub fn blobSwapIn(zone: []u8, blob: Blob) bool {
            std.debug.assert(blob.len <= zone.len);
            _ = UnmapViewOfFileEx.?(@ptrCast(zone.ptr), MEM_PRESERVE_PLACEHOLDER);
            return mapSectionView(blob.section, zone.ptr, 0, blob.len);
        }

        fn guestAccess(st: *State, guest_off: usize, write: bool, val: i32) i32 {
            std.debug.assert(guest_off + 4 <= swap_zone_base_offset);
            const map_off = guest_off & ~(wasm_page_size - 1);
            const v = MapViewOfFile(st.guest_section, FILE_MAP_ALL_ACCESS, @truncate(map_off >> 32), @truncate(map_off), (guest_off + 4) - map_off) orelse fatal("MapViewOfFile scratch", .{});
            defer _ = UnmapViewOfFile(v);
            const view: [*]u8 = @ptrCast(v);
            const p: *align(1) i32 = @ptrCast(view + (guest_off - map_off));
            if (write) {
                p.* = val;
                return 0;
            }
            return p.*;
        }

        pub fn guestPeek32(st: *State, guest_off: usize) i32 {
            return guestAccess(st, guest_off, false, 0);
        }

        pub fn guestPoke32(st: *State, guest_off: usize, val: i32) void {
            _ = guestAccess(st, guest_off, true, val);
        }

        pub fn zonePark(zone: []u8) bool {
            return UnmapViewOfFileEx.?(@ptrCast(zone.ptr), MEM_PRESERVE_PLACEHOLDER) != 0;
        }

        pub fn zoneUnpark(st: *State, zone: []u8) bool {
            _ = UnmapViewOfFileEx.?(@ptrCast(zone.ptr), MEM_PRESERVE_PLACEHOLDER);
            return mapSectionView(st.zero_section.?, zone.ptr, 0, zone.len);
        }
    },

    else => struct {
        const PROT_NONE: c_int = 0x0;
        const PROT_READ: c_int = 0x1;
        const PROT_WRITE: c_int = 0x2;
        const MAP_SHARED: c_int = 0x01;
        const MAP_PRIVATE: c_int = 0x02;
        const MAP_FIXED: c_int = 0x10;
        const MAP_ANONYMOUS: c_int = 0x20;
        const MAP_NORESERVE: c_int = 0x4000;

        extern "c" fn mmap(addr: ?*anyopaque, len: usize, prot: c_int, flags: c_int, fd: c_int, off: i64) ?*anyopaque;
        extern "c" fn munmap(addr: ?*anyopaque, len: usize) c_int;
        extern "c" fn memfd_create(name: [*:0]const u8, flags: c_uint) c_int;
        extern "c" fn ftruncate(fd: c_int, len: i64) c_int;
        extern "c" fn pread(fd: c_int, buf: [*]u8, count: usize, off: i64) isize;
        extern "c" fn pwrite(fd: c_int, buf: [*]const u8, count: usize, off: i64) isize;
        extern "c" fn close(fd: c_int) c_int;

        fn mmapOk(addr: ?*anyopaque, len: usize, prot: c_int, flags: c_int, fd: c_int, off: i64) ?*anyopaque {
            const p = mmap(addr, len, prot, flags, fd, off) orelse return null;
            if (@intFromPtr(p) == std.math.maxInt(usize)) return null;
            return p;
        }

        pub const State = struct { fd: c_int = -1 };

        pub fn init() void {}

        pub fn reserveSpan(st: *State, span: usize) ?[*]u8 {
            const base = mmapOk(null, span, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0) orelse return null;
            const fd = memfd_create("wzs-guest", 0);
            if (fd < 0) return null;
            if (ftruncate(fd, @intCast(swap_zone_base_offset)) != 0) {
                _ = close(fd);
                return null;
            }
            st.* = .{ .fd = fd };
            return @ptrCast(base);
        }

        pub fn commitGuestPages(st: *State, at: [*]u8, guest_off: usize, len: usize) bool {
            return mmapOk(@ptrCast(at), len, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, st.fd, @intCast(guest_off)) != null;
        }

        pub fn commitSwapZone(st: *State, zone: []u8) bool {
            _ = st;
            return mmapOk(@ptrCast(zone.ptr), zone.len, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }

        pub const Blob = struct { fd: c_int, len: usize };

        pub fn blobCreate(len: usize) ?Blob {
            const fd = memfd_create("wzs-blob", 0);
            if (fd < 0) return null;
            if (ftruncate(fd, @intCast(len)) != 0) {
                _ = close(fd);
                return null;
            }
            return .{ .fd = fd, .len = len };
        }

        pub fn blobDestroy(blob: Blob) void {
            _ = close(blob.fd);
        }

        pub fn blobMap(blob: Blob) ?[]u8 {
            const p = mmapOk(null, blob.len, PROT_READ | PROT_WRITE, MAP_SHARED, blob.fd, 0) orelse return null;
            const q: [*]u8 = @ptrCast(p);
            return q[0..blob.len];
        }

        pub fn blobUnmap(view: []u8) void {
            _ = munmap(@ptrCast(view.ptr), view.len);
        }

        pub fn blobSwapIn(zone: []u8, blob: Blob) bool {
            std.debug.assert(blob.len <= zone.len);
            if (mmapOk(@ptrCast(zone.ptr), blob.len, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, blob.fd, 0) == null) return false;
            if (blob.len == zone.len) return true;
            return mmapOk(@ptrCast(zone.ptr + blob.len), zone.len - blob.len, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }

        pub fn guestPeek32(st: *State, guest_off: usize) i32 {
            var v: i32 = undefined;
            if (pread(st.fd, @ptrCast(&v), 4, @intCast(guest_off)) != 4) fatal("pread guest", .{});
            return v;
        }

        pub fn guestPoke32(st: *State, guest_off: usize, val: i32) void {
            if (pwrite(st.fd, @ptrCast(&val), 4, @intCast(guest_off)) != 4) fatal("pwrite guest", .{});
        }

        pub fn zonePark(zone: []u8) bool {
            return mmapOk(@ptrCast(zone.ptr), zone.len, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }

        pub fn zoneUnpark(_: *State, zone: []u8) bool {
            return mmapOk(@ptrCast(zone.ptr), zone.len, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }
    },
};

const HostMem = struct {
    base: ?[*]u8 = null,
    size: usize = 0,
    capacity: usize = 0,
    guard: usize = 0,
    plat: Platform.State = .{},
};

var host_mem: HostMem = .{};

fn hostGetMemory(env: ?*anyopaque, byte_size: [*c]usize, byte_capacity: [*c]usize) callconv(.c) [*c]u8 {
    const m: *HostMem = @ptrCast(@alignCast(env.?));
    byte_size.* = m.size;
    byte_capacity.* = m.capacity;
    return @ptrCast(m.base.?);
}

fn hostGrowMemory(env: ?*anyopaque, new_size: usize) callconv(.c) ?*c.wasmtime_error_t {
    const m: *HostMem = @ptrCast(@alignCast(env.?));
    if (new_size > m.capacity)
        return c.wasmtime_error_new("host memory: grow exceeds in-place capacity");
    if (new_size > m.size) {
        if (!Platform.commitGuestPages(&m.plat, m.base.? + m.size, m.size, new_size - m.size))
            return c.wasmtime_error_new("host memory: commit during grow failed");
    }
    m.size = new_size;
    return null;
}

fn hostNewMemory(
    env: ?*anyopaque,
    ty: ?*const c.wasm_memorytype_t,
    minimum: usize,
    maximum: usize,
    reserved_size_in_bytes: usize,
    guard_size_in_bytes: usize,
    memory_ret: [*c]c.wasmtime_linear_memory_t,
) callconv(.c) ?*c.wasmtime_error_t {
    _ = ty;
    if (host_mem.base != null)
        return c.wasmtime_error_new("host memory: MVP is wired for exactly one memory");
    const m: *HostMem = @ptrCast(@alignCast(env.?));

    const reservation: usize = if (reserved_size_in_bytes != 0) reserved_size_in_bytes else wasm_region_size;
    const guard: usize = guard_size_in_bytes;

    if (reservation < wasm_region_size)
        return c.wasmtime_error_new("host memory: reservation below 4gb; the fixed swap-zone ABI requires the full 4gb (check wasmtime memory_reservation config)");
    if (reservation + guard <= wasm_region_size)
        return c.wasmtime_error_new("host memory: reservation+guard not above 4gb; bounds-check elision is off and the swap zone would be unreachable (check memory_reservation/memory_guard_size config)");
    if (minimum > swap_zone_base_offset)
        return c.wasmtime_error_new("host memory: module memory larger than the guest region below the swap zone");
    const no_max = maximum == std.math.maxInt(usize);
    if (!no_max and maximum == minimum)
        return c.wasmtime_error_new("host memory: min == max makes this a static heap; declare a dynamic memory so the 4gb reservation (and the zone at 0xFFFF0000) is actually honored");

    if (no_max) {
        log.debug("[host memory] minimum={d} maximum=<none> reserved={d} guard={d}", .{ minimum, reservation, guard });
    } else {
        log.debug("[host memory] minimum={d} maximum={d} reserved={d} guard={d}", .{ minimum, maximum, reservation, guard });
    }

    const base = Platform.reserveSpan(&m.plat, reservation + guard) orelse
        return c.wasmtime_error_new("host memory: span reservation failed");
    if (!Platform.commitGuestPages(&m.plat, base, 0, minimum))
        return c.wasmtime_error_new("host memory: guest pages commit failed");
    if (!Platform.commitSwapZone(&m.plat, zoneView(base)))
        return c.wasmtime_error_new("host memory: swap zone commit failed");

    m.base = base;
    m.size = minimum;
    m.capacity = swap_zone_base_offset;
    m.guard = guard;

    memory_ret.* = .{
        .env = m,
        .get_memory = &hostGetMemory,
        .grow_memory = &hostGrowMemory,
        .finalizer = null,
    };

    return null;
}

var memory_creator: c.wasmtime_memory_creator_t = .{
    .env = &host_mem,
    .new_memory = &hostNewMemory,
    .finalizer = null,
};

fn getFunc(ctx: *c.wasmtime_context_t, instance: *const c.wasmtime_instance_t, comptime name: []const u8) !c.wasmtime_func_t {
    var item: c.wasmtime_extern_t = undefined;
    if (!c.wasmtime_instance_export_get(ctx, instance, name.ptr, name.len, &item))
        return dieErrorMessage("missing export \"{s}\"", .{name});
    if (item.kind != c.WASMTIME_EXTERN_FUNC)
        return dieErrorMessage("export \"{s}\" is not a function", .{name});
    return item.of.func;
}

fn callRaw(ctx: *c.wasmtime_context_t, f: c.wasmtime_func_t, args: []const i32, results: []i32) !void {
    std.debug.assert(args.len <= 8 and results.len <= 1);
    var argv: [8]c.wasmtime_val_t = undefined;
    for (args, 0..) |a, i| {
        argv[i] = .{ .kind = c.WASMTIME_I32, .of = .{ .i32 = a } };
    }
    var retv: [1]c.wasmtime_val_t = undefined;
    var trap: ?*c.wasm_trap_t = null;
    if (c.wasmtime_func_call(ctx, &f, &argv, args.len, &retv, results.len, &trap)) |e| return dieError(e);
    if (trap) |t| return dieTrap(t);
    for (results, 0..) |*r, i| {
        if (retv[i].kind != c.WASMTIME_I32) return dieErrorMessage("unexpected result type", .{});
        r.* = retv[i].of.i32;
    }
}

fn call0(ctx: *c.wasmtime_context_t, f: c.wasmtime_func_t) !void {
    return callRaw(ctx, f, &[_]i32{}, &[_]i32{});
}

fn call2(ctx: *c.wasmtime_context_t, f: c.wasmtime_func_t, a: i32, b: i32) !void {
    return callRaw(ctx, f, &[_]i32{ a, b }, &[_]i32{});
}

fn call0ret(ctx: *c.wasmtime_context_t, f: c.wasmtime_func_t) !i32 {
    var r: [1]i32 = undefined;
    try callRaw(ctx, f, &.{}, &r);
    return r[0];
}

fn call1ret(ctx: *c.wasmtime_context_t, f: c.wasmtime_func_t, a: i32) !i32 {
    var r: [1]i32 = undefined;
    try callRaw(ctx, f, &[_]i32{a}, &r);
    return r[0];
}

fn dieErrorMessage(comptime msg: []const u8, args: anytype) error{RuntimeFailure} {
    @branchHint(.cold);
    log.err(msg, args);
    return error.RuntimeFailure;
}

fn dieError(e: *c.wasmtime_error_t) error{RuntimeFailure} {
    @branchHint(.cold);
    var msg: c.wasm_name_t = undefined;
    c.wasmtime_error_message(e, &msg);
    if (comptime log_errs) log.err("wasmtime error: {s}\n", .{msg.data[0..msg.size]});
    c.wasm_byte_vec_delete(&msg);
    c.wasmtime_error_delete(e);
    return error.RuntimeFailure;
}

fn dieTrap(t: *c.wasm_trap_t) error{RuntimeFailure} {
    @branchHint(.cold);
    var msg: c.wasm_message_t = undefined;
    c.wasm_trap_message(t, &msg);
    if (comptime log_errs) log.err("trap: {s}\n", .{msg.data[0..msg.size]});
    c.wasm_byte_vec_delete(&msg);
    c.wasm_trap_delete(t);
    return error.RuntimeFailure;
}

fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    @branchHint(.cold);
    if (comptime log_errs) log.err("fatal: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}

fn expectTrap(ctx: *c.wasmtime_context_t, f: c.wasmtime_func_t, a: i32) !void {
    _ = call1ret(ctx, f, a) catch return;
    return error.ExpectedTrap;
}

pub const std_options = std.Options{
    .log_level = .debug,
};

test {
    Platform.init();

    const config = c.wasm_config_new() orelse return error.ConfigNewFailed;
    c.wasmtime_config_host_memory_creator_set(config, &memory_creator);
    c.wasmtime_config_memory_init_cow_set(config, false); // #10740
    c.wasmtime_config_memory_reservation_set(config, wasm_region_size); // defines the maximum size a 32-bit linear memory can grow into
    c.wasmtime_config_memory_guard_size_set(config, wasm_region_size); // allows offsets spanning the entire addressable space to bypass explicit bounds checks
    c.wasmtime_config_memory_may_move_set(config, false); // force wasmtime to treat the reservation as a hard ceiling
    const engine = c.wasm_engine_new_with_config(config) orelse return error.EngineNewFailed;
    defer c.wasm_engine_delete(engine);

    const store = c.wasmtime_store_new(engine, null, null) orelse return error.StoreNewFailed;
    defer c.wasmtime_store_delete(store);
    const ctx = c.wasmtime_store_context(store) orelse return error.StoreContextFailed;

    var module: ?*c.wasmtime_module_t = null;
    if (c.wasmtime_module_new(engine, guest_wasm.ptr, guest_wasm.len, &module)) |e| return dieError(e);
    defer c.wasmtime_module_delete(module);

    var instance: c.wasmtime_instance_t = undefined;
    {
        var trap: ?*c.wasm_trap_t = null;
        var no_imports: [1]c.wasmtime_extern_t = undefined;
        if (c.wasmtime_instance_new(ctx, module, &no_imports, 0, &instance, &trap)) |e| return dieError(e);
        if (trap) |t| return dieTrap(t);
    }

    const f_add = try getFunc(ctx, &instance, "add");
    const f_echo = try getFunc(ctx, &instance, "echo");
    const f_poke = try getFunc(ctx, &instance, "poke");
    const f_grow = try getFunc(ctx, &instance, "grow");
    const f_scratch = try getFunc(ctx, &instance, "scratchAddr");
    const f_zoneLoadStatic = try getFunc(ctx, &instance, "zoneLoadStatic");
    const f_zonePokeDynamic = try getFunc(ctx, &instance, "zonePokeDynamic");
    const f_memPages = try getFunc(ctx, &instance, "memPages");

    const base = host_mem.base orelse return error.HostMemoryNotCreated;
    const st = &host_mem.plat;

    log.debug("guest memory: base=0x{x} size={d} capacity={d} guard={d}", .{ @intFromPtr(base), host_mem.size, host_mem.capacity, host_mem.guard });
    log.debug("swap zone: [0x{x}, 0x{x}) - fixed offset in every module", .{ swap_zone_base_offset, wasm_region_size });

    {
        var item: c.wasmtime_extern_t = undefined;
        if (c.wasmtime_instance_export_get(ctx, &instance, "memory", 6, &item)) {
            if (item.kind != c.WASMTIME_EXTERN_MEMORY) return error.MemoryExportNotMemory;
            if (c.wasmtime_memory_data(ctx, &item.of.memory) != @as([*c]u8, @ptrCast(base))) return error.BasePointerMismatch;
        }
    }

    const scr0 = try call1ret(ctx, f_scratch, 0);
    const scr1 = try call1ret(ctx, f_scratch, 1);

    const val_a: i32 = 0xC0FFEE;
    Platform.guestPoke32(st, @intCast(scr0), val_a);
    const echoed = try call1ret(ctx, f_echo, scr0);
    log.debug("[oob] host poked {d} @ guest 0x{x}; guest echo read {d}", .{ val_a, scr0, echoed });
    if (echoed != val_a) return error.OobHostToGuestFailed;

    const val_b: i32 = @bitCast(@as(u32, 0xFEEDFACE));
    try call2(ctx, f_poke, scr1, val_b);
    const seen_b = Platform.guestPeek32(st, @intCast(scr1));
    log.debug("[oob] guest poked {d} @ guest 0x{x}; host peeked {d}", .{ val_b, scr1, seen_b });
    if (seen_b != val_b) return error.OobGuestToHostFailed;
    if (i32At(base, @intCast(scr1)).* != val_b) return error.OobChannelsDisagree;

    const size_before = host_mem.size;
    const grow_addr: i32 = @intCast(size_before + 0x40);
    if (try call1ret(ctx, f_grow, 2) != 0) return error.GrowFailed;
    if (host_mem.size != size_before + 2 * wasm_page_size) return error.GrowSizeWrong;
    Platform.guestPoke32(st, @intCast(grow_addr), 0x5151);
    if (try call1ret(ctx, f_echo, grow_addr) != 0x5151) return error.GrowCommitInvisible;
    log.debug("[grow] +2 pages -> size={d}; fresh pages are identity-backed and both channels agree", .{host_mem.size});

    if (try call1ret(ctx, f_grow, 0x10000) != -1) return error.GrowShouldHaveFailed;
    log.debug("[grow] refused to grow past the zone (returned -1, no trap)", .{});

    const blob_a = Platform.blobCreate(swap_zone_size) orelse fatal("blobCreate(A)", .{});
    const blob_b = Platform.blobCreate(swap_zone_size) orelse fatal("blobCreate(B)", .{});
    defer Platform.blobDestroy(blob_a);
    defer Platform.blobDestroy(blob_b);
    {
        const a = Platform.blobMap(blob_a) orelse fatal("blobMap(A)", .{});
        defer Platform.blobUnmap(a);
        putI32(a, 0, 10);
        putI32(a, 1, 32);
        const b = Platform.blobMap(blob_b) orelse fatal("blobMap(B)", .{});
        defer Platform.blobUnmap(b);
        putI32(b, 0, 7);
        putI32(b, 1, 5);
    }

    if (!Platform.blobSwapIn(zoneView(base), blob_a)) fatal("blobSwapIn(A)", .{});
    try call0(ctx, f_add);
    {
        const zone = zoneView(base); // host alias of blob A's backing right now
        const sum = getI32(zone, 0);
        const a = Platform.blobMap(blob_a) orelse fatal("blobMap(A)", .{});
        defer Platform.blobUnmap(a);
        log.debug("[A] {{10,32}} in -> add() -> zone[0]={d} (host VA); blob A via map: {{{d}, {d}}}", .{ sum, getI32(a, 0), getI32(a, 1) });
        if (sum != 42 or getI32(a, 0) != 42 or getI32(a, 1) != 32) return error.RoundtripAFailed;
    }

    if (!Platform.blobSwapIn(zoneView(base), blob_b)) fatal("blobSwapIn(B)", .{});
    try call0(ctx, f_add);
    {
        const zone = zoneView(base);
        const sum = getI32(zone, 0);
        const b = Platform.blobMap(blob_b) orelse fatal("blobMap(B)", .{});
        defer Platform.blobUnmap(b);
        log.debug("[B] {{7,5}} in   -> add() -> zone[0]={d} (host VA); blob B via map: {{{d}, {d}}}", .{ sum, getI32(b, 0), getI32(b, 1) });
        if (sum != 12 or getI32(b, 0) != 12 or getI32(b, 1) != 5) return error.RoundtripBFailed;
    }

    {
        const a = Platform.blobMap(blob_a) orelse fatal("blobMap(A post-swap)", .{});
        defer Platform.blobUnmap(a);
        if (getI32(a, 0) != 42 or getI32(a, 1) != 32) return error.SwappedOutBlobMutated;
        log.debug("blob A (swapped out) still {{{d}, {d}}} via host view; guest data intact at 0x{x}, 0x{x}, 0x{x}", .{ getI32(a, 0), getI32(a, 1), scr0, scr1, grow_addr });
    }
    if (Platform.guestPeek32(st, @intCast(scr0)) != val_a) return error.GuestRegionMutated;
    if (Platform.guestPeek32(st, @intCast(scr1)) != val_b) return error.GuestRegionMutated;
    if (Platform.guestPeek32(st, @intCast(grow_addr)) != 0x5151) return error.GuestRegionMutated;

    log.debug("OK: zero-copy roundtrip complete", .{});

    try expectTrap(ctx, f_echo, @intCast(host_mem.size + 0x1000));
    try expectTrap(ctx, f_echo, 0x7FFF_FFFC);
    try expectTrap(ctx, f_echo, @bitCast(@as(u32, @intCast(swap_zone_base_offset - 4))));

    if (!Platform.zonePark(zoneView(base))) return error.ZoneParkFailed;
    try expectTrap(ctx, f_echo, @bitCast(@as(u32, @intCast(swap_zone_base_offset))));
    {
        var trapped = false;
        _ = call0(ctx, f_add) catch {
            trapped = true;
        };
        if (!trapped) return error.ParkedZoneDidNotTrap;
    }

    if (!Platform.zoneUnpark(st, zoneView(base))) return error.ZoneUnparkFailed;

    if (try call0ret(ctx, f_memPages) != host_mem.size / wasm_page_size) return error.MemSizeMismatch;

    const blob_test = Platform.blobCreate(swap_zone_size) orelse fatal("blobCreate(test)", .{});
    defer Platform.blobDestroy(blob_test);
    {
        const v = Platform.blobMap(blob_test) orelse fatal("blobMap(test)", .{});
        defer Platform.blobUnmap(v);
        putI32(v, 0, 100);
        putI32(v, 1, 200);
    }
    if (!Platform.blobSwapIn(zoneView(base), blob_test)) fatal("blobSwapIn(test)", .{});

    const static_val = try call0ret(ctx, f_zoneLoadStatic);
    if (static_val != 100) return error.ZoneStaticReadFailed;

    try call2(ctx, f_zonePokeDynamic, @bitCast(@as(u32, @intCast(swap_zone_base_offset))), 999);

    {
        const v = Platform.blobMap(blob_test) orelse fatal("blobMap(test post)", .{});
        defer Platform.blobUnmap(v);
        if (getI32(v, 0) != 999) return error.ZoneDynamicWriteFailed;
    }

    log.debug("OK: both static-offset and dynamic-index zone addressing behave as expected.", .{});
}
