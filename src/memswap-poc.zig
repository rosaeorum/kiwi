const memswap_proof_of_concept = @This();

const std = @import("std");
const builtin = @import("builtin");
const c = @import("module/wasm.zig");

const guest_wasm: []const u8 = @embedFile("guest.wasm");

const log_errs = !@import("builtin").is_test;

const log = std.log.scoped(.wasm);

const wasm_page_size: usize = 64 * 1024;
const wasm_region_size: usize = 1 << 32;

const binding_slot_size: usize = 1 << 20; // 1 MiB
const max_binding_slots: usize = 8;
const total_binding_region: usize = binding_slot_size * max_binding_slots; // 8 MiB
const binding_region_base: usize = wasm_region_size - total_binding_region; // 0xFF800000
const swap_zone_base_offset: usize = binding_region_base + (max_binding_slots - 1) * binding_slot_size;
const swap_zone_size: usize = binding_slot_size;

const Position = extern struct { x: f32, y: f32 };
const Velocity = extern struct { x: f32, y: f32 };
const Health = extern struct { current: i32 };

pub const guest_src: []const u8 =
    std.fmt.comptimePrint(
        \\const std = @import("std");
        \\pub const ZONE_ADDR: usize = 0x{x};
        \\pub const ZONE_LEN: usize = 0x{x};
    , .{ swap_zone_base_offset, swap_zone_size }) ++
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

fn i32At(base: [*]u8, off: usize) *align(1) i32 {
    return @ptrCast(base + off);
}

fn zoneView(base: [*]u8) []u8 {
    return (base + swap_zone_base_offset)[0..swap_zone_size];
}

fn bindingView(base: [*]u8) []u8 {
    return (base + binding_region_base)[0..total_binding_region];
}

fn slotView(base: [*]u8, slot: usize) []u8 {
    std.debug.assert(slot < max_binding_slots);
    return (base + binding_region_base + slot * binding_slot_size)[0..binding_slot_size];
}

fn slotAddr(slot: usize) i32 {
    std.debug.assert(slot < max_binding_slots);
    return @bitCast(@as(u32, @intCast(binding_region_base + slot * binding_slot_size)));
}

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
            st.guest_section = makeFileSection(binding_region_base) orelse return null;
            st.zero_section = CreateFileMappingW(INVALID_HANDLE_VALUE, null, PAGE_READWRITE, 0, @truncate(binding_slot_size), null);
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

        pub fn commitBindingRegion(st: *State, region: []u8) bool {
            _ = st;
            var i: usize = 0;
            while (i < max_binding_slots) : (i += 1) {
                const slot_ptr = region.ptr + i * binding_slot_size;
                if (!splitPlaceholder(slot_ptr, binding_slot_size)) return false;
            }
            return true;
        }

        pub const Blob = struct { section: HANDLE, len: usize, offset: usize = 0 };

        pub fn blobCreate(len: usize) ?Blob {
            const section = CreateFileMappingW(INVALID_HANDLE_VALUE, null, PAGE_READWRITE, @truncate(len >> 32), @truncate(len), null) orelse return null;
            return .{ .section = section, .len = len, .offset = 0 };
        }

        pub fn blobDestroy(blob: Blob) void {
            _ = CloseHandle(blob.section);
        }

        pub fn blobMap(blob: Blob) ?[]u8 {
            const v = MapViewOfFile(blob.section, FILE_MAP_ALL_ACCESS, @truncate(blob.offset >> 32), @truncate(blob.offset), blob.len) orelse return null;
            const p: [*]u8 = @ptrCast(v);
            return p[0..blob.len];
        }

        pub fn blobUnmap(view: []u8) void {
            _ = UnmapViewOfFile(@ptrCast(view.ptr));
        }

        pub fn blobSwapIn(zone: []u8, blob: Blob) bool {
            std.debug.assert(blob.len <= zone.len);
            _ = UnmapViewOfFileEx.?(@ptrCast(zone.ptr), MEM_PRESERVE_PLACEHOLDER);
            return mapSectionView(blob.section, zone.ptr, blob.offset, blob.len);
        }

        fn guestAccess(st: *State, guest_off: usize, write: bool, val: i32) i32 {
            std.debug.assert(guest_off + 4 <= binding_region_base);
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
            _ = UnmapViewOfFileEx.?(@ptrCast(zone.ptr), MEM_PRESERVE_PLACEHOLDER);
            return true;
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
            if (ftruncate(fd, @intCast(binding_region_base)) != 0) {
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

        pub fn commitBindingRegion(st: *State, region: []u8) bool {
            _ = st;
            return mmapOk(@ptrCast(region.ptr), region.len, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }

        pub const Blob = struct { fd: c_int, len: usize, offset: usize = 0 };

        pub fn blobCreate(len: usize) ?Blob {
            const fd = memfd_create("wzs-blob", 0);
            if (fd < 0) return null;
            if (ftruncate(fd, @intCast(len)) != 0) {
                _ = close(fd);
                return null;
            }
            return .{ .fd = fd, .len = len, .offset = 0 };
        }

        pub fn blobDestroy(blob: Blob) void {
            _ = close(blob.fd);
        }

        pub fn blobMap(blob: Blob) ?[]u8 {
            const p = mmapOk(null, blob.len, PROT_READ | PROT_WRITE, MAP_SHARED, blob.fd, @intCast(blob.offset)) orelse return null;
            const q: [*]u8 = @ptrCast(p);
            return q[0..blob.len];
        }

        pub fn blobUnmap(view: []u8) void {
            _ = munmap(@ptrCast(view.ptr), view.len);
        }

        pub fn blobSwapIn(zone: []u8, blob: Blob) bool {
            std.debug.assert(blob.len <= zone.len);
            if (mmapOk(@ptrCast(zone.ptr), blob.len, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, blob.fd, @intCast(blob.offset)) == null) return false;
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
    if (minimum > binding_region_base)
        return c.wasmtime_error_new("host memory: module memory larger than the guest region below the binding region");
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
    if (!Platform.commitBindingRegion(&m.plat, bindingView(base)))
        return c.wasmtime_error_new("host memory: binding region commit failed");

    m.base = base;
    m.size = minimum;
    m.capacity = binding_region_base;
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

fn call5(ctx: *c.wasmtime_context_t, f: c.wasmtime_func_t, a: i32, b: i32, cc: i32, d: i32, e: i32) !void {
    return callRaw(ctx, f, &[_]i32{ a, b, cc, d, e }, &[_]i32{});
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

const ComponentColumn = struct {
    blob: Platform.Blob,
    element_size: usize,
    count: usize,
    total_bytes: usize,

    fn init(element_size: usize, count: usize) ?ComponentColumn {
        const raw_total = element_size * count;
        const total_bytes = std.mem.alignForward(usize, raw_total, binding_slot_size);
        const blob = Platform.blobCreate(total_bytes) orelse return null;
        return .{
            .blob = blob,
            .element_size = element_size,
            .count = count,
            .total_bytes = total_bytes,
        };
    }

    fn deinit(col: *ComponentColumn) void {
        Platform.blobDestroy(col.blob);
    }

    fn map(col: *ComponentColumn) ?[]u8 {
        return Platform.blobMap(col.blob);
    }

    fn unmap(view: []u8) void {
        Platform.blobUnmap(view);
    }

    fn pageCount(col: *const ComponentColumn) usize {
        return col.total_bytes / binding_slot_size;
    }

    fn pageBlob(col: *const ComponentColumn, page_idx: usize) Platform.Blob {
        const offset = page_idx * binding_slot_size;
        std.debug.assert(offset < col.total_bytes);
        var blob = col.blob;
        blob.offset = offset;
        blob.len = binding_slot_size;
        return blob;
    }

    fn bindSlot(col: *const ComponentColumn, slot: []u8, page_idx: usize) bool {
        return Platform.blobSwapIn(slot, col.pageBlob(page_idx));
    }
};

const Engine = struct {
    engine: *c.wasm_engine_t,
    store: *c.wasmtime_store_t,
    ctx: *c.wasmtime_context_t,
    module: *c.wasmtime_module_t,
    instance: c.wasmtime_instance_t,

    fn create() !Engine {
        const config = c.wasm_config_new() orelse return error.ConfigNewFailed;
        c.wasmtime_config_host_memory_creator_set(config, &memory_creator);
        c.wasmtime_config_memory_init_cow_set(config, false);
        c.wasmtime_config_memory_reservation_set(config, wasm_region_size);
        c.wasmtime_config_memory_guard_size_set(config, wasm_region_size);
        c.wasmtime_config_memory_may_move_set(config, false);
        c.wasmtime_config_wasm_simd_set(config, true);
        const engine = c.wasm_engine_new_with_config(config) orelse return error.EngineNewFailed;
        errdefer c.wasm_engine_delete(engine);

        const store = c.wasmtime_store_new(engine, null, null) orelse return error.StoreNewFailed;
        errdefer c.wasmtime_store_delete(store);
        const ctx = c.wasmtime_store_context(store) orelse return error.StoreContextFailed;

        var module: ?*c.wasmtime_module_t = null;
        if (c.wasmtime_module_new(engine, guest_wasm.ptr, guest_wasm.len, &module)) |e| return dieError(e);
        errdefer c.wasmtime_module_delete(module.?);

        var instance: c.wasmtime_instance_t = undefined;
        {
            var trap: ?*c.wasm_trap_t = null;
            var no_imports: [1]c.wasmtime_extern_t = undefined;
            if (c.wasmtime_instance_new(ctx, module.?, &no_imports, 0, &instance, &trap)) |e| return dieError(e);
            if (trap) |t| return dieTrap(t);
        }

        return .{
            .engine = engine,
            .store = store,
            .ctx = ctx,
            .module = module.?,
            .instance = instance,
        };
    }

    fn destroy(self: *Engine) void {
        c.wasmtime_module_delete(self.module);
        c.wasmtime_store_delete(self.store);
        c.wasm_engine_delete(self.engine);
    }
};

test {
    Platform.init();

    var eng = try Engine.create();
    defer eng.destroy();
    const ctx = eng.ctx;

    const f_add = try getFunc(ctx, &eng.instance, "add");
    const f_echo = try getFunc(ctx, &eng.instance, "echo");
    const f_poke = try getFunc(ctx, &eng.instance, "poke");
    const f_grow = try getFunc(ctx, &eng.instance, "grow");
    const f_scratch = try getFunc(ctx, &eng.instance, "scratchAddr");
    const f_zoneLoadStatic = try getFunc(ctx, &eng.instance, "zoneLoadStatic");
    const f_zonePokeDynamic = try getFunc(ctx, &eng.instance, "zonePokeDynamic");
    const f_memPages = try getFunc(ctx, &eng.instance, "memPages");
    const f_particle = try getFunc(ctx, &eng.instance, "particle_system");

    const base = host_mem.base orelse return error.HostMemoryNotCreated;
    const st = &host_mem.plat;

    log.debug("guest memory: base=0x{x} size={d} capacity={d} guard={d}", .{ @intFromPtr(base), host_mem.size, host_mem.capacity, host_mem.guard });
    log.debug("binding region: [0x{x}, 0x{x}) — {d} slots × {d} KiB", .{ binding_region_base, wasm_region_size, max_binding_slots, binding_slot_size / 1024 });
    log.debug("swap zone (slot {d}): [0x{x}, 0x{x})", .{ max_binding_slots - 1, swap_zone_base_offset, swap_zone_base_offset + swap_zone_size });

    // invariant: memory export base pointer matches host reservation
    {
        var item: c.wasmtime_extern_t = undefined;
        if (c.wasmtime_instance_export_get(ctx, &eng.instance, "memory", 6, &item)) {
            if (item.kind != c.WASMTIME_EXTERN_MEMORY) return error.MemoryExportNotMemory;
            if (c.wasmtime_memory_data(ctx, &item.of.memory) != @as([*c]u8, @ptrCast(base))) return error.BasePointerMismatch;
        }
    }

    // invariant: OOB host->guest and guest->host channels agree
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

    // invariant: memory growth works and fresh pages are identity-backed
    const size_before = host_mem.size;
    const grow_addr: i32 = @intCast(size_before + 0x40);
    if (try call1ret(ctx, f_grow, 2) != 0) return error.GrowFailed;
    if (host_mem.size != size_before + 2 * wasm_page_size) return error.GrowSizeWrong;
    Platform.guestPoke32(st, @intCast(grow_addr), 0x5151);
    if (try call1ret(ctx, f_echo, grow_addr) != 0x5151) return error.GrowCommitInvisible;
    log.debug("[grow] +2 pages -> size={d}; fresh pages are identity-backed and both channels agree", .{host_mem.size});

    if (try call1ret(ctx, f_grow, 0x10000) != -1) return error.GrowShouldHaveFailed;
    log.debug("[grow] refused to grow past the binding region (returned -1, no trap)", .{});

    // invariant: single-zone blob swap roundtrip
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
        const zone = zoneView(base);
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

    // invariant: swapped-out blob and guest data are intact
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

    // invariant: out-of-bounds and parked-zone traps
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

    // invariant: static-offset and dynamic-index zone addressing
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

    const entity_count: usize = 1000;

    var col_pos = ComponentColumn.init(@sizeOf(Position), entity_count) orelse fatal("col_pos init", .{});
    var col_vel = ComponentColumn.init(@sizeOf(Velocity), entity_count) orelse fatal("col_vel init", .{});
    var col_health = ComponentColumn.init(@sizeOf(Health), entity_count) orelse fatal("col_health init", .{});
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
        const pv = col_pos.map() orelse fatal("col_pos map", .{});
        defer ComponentColumn.unmap(pv);
        const vv = col_vel.map() orelse fatal("col_vel map", .{});
        defer ComponentColumn.unmap(vv);
        const hv = col_health.map() orelse fatal("col_health map", .{});
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
    log.debug("[multi-bind] dispatch archetype [Pos, Vel, Health] — flags=1", .{});
    {
        if (!col_pos.bindSlot(slotView(base, 0), 0)) fatal("bind pos slot 0", .{});
        if (!col_vel.bindSlot(slotView(base, 1), 0)) fatal("bind vel slot 1", .{});
        if (!col_health.bindSlot(slotView(base, 2), 0)) fatal("bind health slot 2", .{});

        try call5(ctx, f_particle, slotAddr(0), slotAddr(1), slotAddr(2), @intCast(entity_count), 1);
    }

    // verify results
    {
        const pv = col_pos.map() orelse fatal("col_pos map (verify)", .{});
        defer ComponentColumn.unmap(pv);
        const hv = col_health.map() orelse fatal("col_health map (verify)", .{});
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
    log.debug("[multi-bind] dispatch archetype [Pos, Vel] — flags=0, health slot parked", .{});

    // reset positions
    {
        const pv = col_pos.map() orelse fatal("col_pos map (reset)", .{});
        defer ComponentColumn.unmap(pv);
        const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
        for (0..entity_count) |i| {
            positions[i] = .{ .x = 0, .y = 0 };
        }
    }

    {
        if (!col_pos.bindSlot(slotView(base, 0), 0)) fatal("rebind pos slot 0", .{});
        if (!col_vel.bindSlot(slotView(base, 1), 0)) fatal("rebind vel slot 1", .{});
        // park slot 2 — health is optional, not present in this archetype
        if (!Platform.zonePark(slotView(base, 2))) fatal("park slot 2", .{});

        // health_addr = 0 means "not bound"; flags = 0 means no health branch
        try call5(ctx, f_particle, slotAddr(0), slotAddr(1), 0, @intCast(entity_count), 0);
    }

    // verify positions updated, health unchanged
    {
        const pv = col_pos.map() orelse fatal("col_pos map (verify no-health)", .{});
        defer ComponentColumn.unmap(pv);
        const hv = col_health.map() orelse fatal("col_health map (verify no-health)", .{});
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
    try expectTrap(ctx, f_echo, @bitCast(@as(u32, @intCast(binding_region_base + 2 * binding_slot_size))));

    // restore slot 2 for cleanliness
    _ = Platform.zoneUnpark(st, slotView(base, 2));

    // multi-page column iteration test
    {
        const big_count: usize = @divFloor(binding_slot_size, @sizeOf(Position)) + 500;
        var col_big = ComponentColumn.init(@sizeOf(Position), big_count) orelse fatal("col_big init", .{});
        defer col_big.deinit();

        const pages = col_big.pageCount();
        log.debug("[multi-bind] big column: {d} entities, {d} bytes, {d} pages", .{ big_count, col_big.total_bytes, pages });
        if (pages < 2) return error.BigColumnShouldSpanMultiplePages;

        var col_big_vel = ComponentColumn.init(@sizeOf(Velocity), big_count) orelse fatal("col_big_vel init", .{});
        defer col_big_vel.deinit();

        {
            const pv = col_big.map() orelse fatal("col_big map", .{});
            defer ComponentColumn.unmap(pv);
            const vv = col_big_vel.map() orelse fatal("col_big_vel map", .{});
            defer ComponentColumn.unmap(vv);

            const positions: [*]Position = @ptrCast(@alignCast(pv.ptr));
            const velocities: [*]Velocity = @ptrCast(@alignCast(vv.ptr));

            for (0..big_count) |i| {
                positions[i] = .{ .x = 0, .y = 0 };
                velocities[i] = .{ .x = 3, .y = 4 };
            }
        }

        const ents_per_page = @divFloor(binding_slot_size, @sizeOf(Position));
        for (0..pages) |page_idx| {
            const page_start = page_idx * ents_per_page;
            const page_end = @min(page_start + ents_per_page, big_count);
            const page_count = page_end - page_start;

            if (!col_big.bindSlot(slotView(base, 0), page_idx)) fatal("bind big pos page {d}", .{page_idx});
            if (!col_big_vel.bindSlot(slotView(base, 1), page_idx)) fatal("bind big vel page {d}", .{page_idx});

            try call5(ctx, f_particle, slotAddr(0), slotAddr(1), 0, @intCast(page_count), 0);
        }

        {
            const pv = col_big.map() orelse fatal("col_big map (verify)", .{});
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

    // invariant: guest data still intact after multi-binding
    if (Platform.guestPeek32(st, @intCast(scr0)) != val_a) return error.GuestRegionMutatedAfterMultiBind;
    if (Platform.guestPeek32(st, @intCast(scr1)) != val_b) return error.GuestRegionMutatedAfterMultiBind;
    if (Platform.guestPeek32(st, @intCast(grow_addr)) != 0x5151) return error.GuestRegionMutatedAfterMultiBind;

    log.debug("OK: multi-binding dispatch complete — invariants preserved", .{});
}

pub const std_options = std.Options{
    .log_level = .debug,
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

pub fn main(init: std.process.Init) !void {
    Platform.init();
    const io = init.io;
    const gpa = init.gpa;

    var eng = try Engine.create();
    defer eng.destroy();
    const ctx = eng.ctx;

    const f_particle = try getFunc(ctx, &eng.instance, "particle_system");

    const base = host_mem.base orelse return error.HostMemoryNotCreated;

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

        const start = std.Io.Clock.awake.now(io);
        for (0..bench_iters) |_| {
            nativeParticleSystem(positions.ptr, velocities.ptr, healths.ptr, entity_count);
        }
        const end = std.Io.Clock.awake.now(io);
        const elapsed_ns = start.durationTo(end).nanoseconds;

        const ns_per_iter = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(bench_iters));
        const ns_per_entity = ns_per_iter / @as(f64, @floatFromInt(entity_count));

        log.info("native:           {d:>12.2} ns/iter  ({d:>6.2} ns/entity)", .{ ns_per_iter, ns_per_entity });
    }

    // guest with bind-once (measures call + compute overhead)
    {
        var col_pos = ComponentColumn.init(@sizeOf(Position), entity_count) orelse fatal("bench col_pos", .{});
        var col_vel = ComponentColumn.init(@sizeOf(Velocity), entity_count) orelse fatal("bench col_vel", .{});
        var col_health = ComponentColumn.init(@sizeOf(Health), entity_count) orelse fatal("bench col_health", .{});
        defer col_pos.deinit();
        defer col_vel.deinit();
        defer col_health.deinit();

        {
            const pv = col_pos.map() orelse fatal("bench map pos", .{});
            defer ComponentColumn.unmap(pv);
            const vv = col_vel.map() orelse fatal("bench map vel", .{});
            defer ComponentColumn.unmap(vv);
            const hv = col_health.map() orelse fatal("bench map health", .{});
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

        if (!col_pos.bindSlot(slotView(base, 0), 0)) fatal("bench bind pos", .{});
        if (!col_vel.bindSlot(slotView(base, 1), 0)) fatal("bench bind vel", .{});
        if (!col_health.bindSlot(slotView(base, 2), 0)) fatal("bench bind health", .{});

        const count_i32: i32 = @intCast(entity_count);

        for (0..warmup_iters) |_| {
            try call5(ctx, f_particle, slotAddr(0), slotAddr(1), slotAddr(2), count_i32, 1);
        }

        const start = std.Io.Clock.awake.now(io);
        for (0..bench_iters) |_| {
            try call5(ctx, f_particle, slotAddr(0), slotAddr(1), slotAddr(2), count_i32, 1);
        }
        const end = std.Io.Clock.awake.now(io);
        const elapsed_ns = start.durationTo(end).nanoseconds;

        const ns_per_iter = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(bench_iters));
        const ns_per_entity = ns_per_iter / @as(f64, @floatFromInt(entity_count));

        log.info("guest (bind once): {d:>12.2} ns/iter  ({d:>6.2} ns/entity)", .{ ns_per_iter, ns_per_entity });
    }

    // guest with rebind each iteration (measures full dispatch cost)
    {
        var col_pos = ComponentColumn.init(@sizeOf(Position), entity_count) orelse fatal("bench2 col_pos", .{});
        var col_vel = ComponentColumn.init(@sizeOf(Velocity), entity_count) orelse fatal("bench2 col_vel", .{});
        var col_health = ComponentColumn.init(@sizeOf(Health), entity_count) orelse fatal("bench2 col_health", .{});
        defer col_pos.deinit();
        defer col_vel.deinit();
        defer col_health.deinit();

        {
            const pv = col_pos.map() orelse fatal("bench2 map pos", .{});
            defer ComponentColumn.unmap(pv);
            const vv = col_vel.map() orelse fatal("bench2 map vel", .{});
            defer ComponentColumn.unmap(vv);
            const hv = col_health.map() orelse fatal("bench2 map health", .{});
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

        const sv0 = slotView(base, 0);
        const sv1 = slotView(base, 1);
        const sv2 = slotView(base, 2);
        const count_i32: i32 = @intCast(entity_count);

        for (0..warmup_iters) |_| {
            _ = col_pos.bindSlot(sv0, 0);
            _ = col_vel.bindSlot(sv1, 0);
            _ = col_health.bindSlot(sv2, 0);
            try call5(ctx, f_particle, slotAddr(0), slotAddr(1), slotAddr(2), count_i32, 1);
        }

        const start = std.Io.Clock.awake.now(io);
        for (0..bench_iters) |_| {
            _ = col_pos.bindSlot(sv0, 0);
            _ = col_vel.bindSlot(sv1, 0);
            _ = col_health.bindSlot(sv2, 0);
            try call5(ctx, f_particle, slotAddr(0), slotAddr(1), slotAddr(2), count_i32, 1);
        }
        const end = std.Io.Clock.awake.now(io);
        const elapsed_ns = start.durationTo(end).nanoseconds;

        const ns_per_iter = @as(f64, @floatFromInt(elapsed_ns)) / @as(f64, @floatFromInt(bench_iters));
        const ns_per_entity = ns_per_iter / @as(f64, @floatFromInt(entity_count));

        log.info("guest (rebind):    {d:>12.2} ns/iter  ({d:>6.2} ns/entity)", .{ ns_per_iter, ns_per_entity });
    }

    log.info("benchmark complete.", .{});
}
