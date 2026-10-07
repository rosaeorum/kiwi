// Layout contract host<->guest ("static ABI")
//
// Every module gets the full 4gb of *virtual* address space for its linear memory
// The swap zone is pinned to the last 64kb of that region; the same fixed offset in every module
// Guests compile against it as a plain variable, and guest code needs no placement directives at all
// (stack, globals, data and heap grow naturally from address 0)
//
//   [0,          0xFFFF0000)  guest memory; grows via memory.grow
//   [0xFFFF0000, 0x100000000) swap zone: remapped per blob by the host
//   [0x100000000, +guard)     guard region, never mapped, catches faults
//
// Because the whole region is reserved up front, wasmtime elides bounds
// checks entirely (faults inside the span are classified as wasm OOB traps),
// so the zone is reachable with ordinary loads/stores at the fixed offset
// from the first instruction, whatever memory.size reports
//
// Growing into the zone is refused as a spec-conformant memory.grow failure
//
// Both platforms back the guest region with *lazy* storage (Linux: a memfd; Windows: a sparse temp file)
// and identity-map guest pages into it (guest byte offset == backing-store offset)
// so the host always has out-of-band read/write access to live guest memory without going through the guest's virtual address
//
// The host could also just read through `base`, it maps the whole span in this process;
// but the backing-store channel is what keeps working when the guest mapping is temporarily torn down,
// and it's what we should hand to another process, a snapshot routine, or a core dumper

const WASM_PAGE: usize = 64 * 1024;
const GUEST_SPAN: usize = 1 << 32; // 4gb per module
const SWAP_ZONE: usize = WASM_PAGE; // swap zone size
const ZONE_OFF: usize = GUEST_SPAN - SWAP_ZONE; // 0xFFFF0000 for the static ABI
const GUEST_LIMIT: usize = ZONE_OFF; // largest size memory.grow may reach

fn i32At(base: [*]u8, off: usize) *align(1) i32 {
    return @ptrCast(base + off);
}

// typed view of SWAP_ZONE; mirrors `BlobHead` in guest.zig
const BlobHead = extern struct { lhs: i32, rhs: i32 };

const Platform = switch (builtin.os.tag) {
    .linux => struct {
        const PROT_NONE: c_int = 0x0;
        const PROT_READ: c_int = 0x1;
        const PROT_WRITE: c_int = 0x2;
        const MAP_SHARED: c_int = 0x01;
        const MAP_PRIVATE: c_int = 0x02;
        const MAP_FIXED: c_int = 0x10;
        const MAP_ANONYMOUS: c_int = 0x20;
        const MAP_NORESERVE: c_int = 0x4000;

        extern "c" fn mmap(addr: ?*anyopaque, len: usize, prot: c_int, flags: c_int, fd: c_int, off: i64) ?*anyopaque;
        extern "c" fn memfd_create(name: [*:0]const u8, flags: c_uint) c_int;
        extern "c" fn ftruncate(fd: c_int, len: i64) c_int;
        extern "c" fn pread(fd: c_int, buf: [*]u8, count: usize, off: i64) isize;
        extern "c" fn pwrite(fd: c_int, buf: [*]const u8, count: usize, off: i64) isize;
        extern "c" fn close(fd: c_int) c_int;

        // mmap's error return is MAP_FAILED ((void*)-1), not null, and the
        // raw extern can't express that; normalize it once, here.
        fn mmapOk(addr: ?*anyopaque, len: usize, prot: c_int, flags: c_int, fd: c_int, off: i64) ?*anyopaque {
            const p = mmap(addr, len, prot, flags, fd, off) orelse return null;
            if (@intFromPtr(p) == std.math.maxInt(usize)) return null;
            return p;
        }

        // one memfd backing the whole guest-owned region
        // [0, GUEST_LIMIT). Guest pages are identity-offset MAP_SHARED views
        // of it (guest byte offset == file offset), so the host can always
        // read/write live guest memory out-of-band via pread/pwrite on the
        // fd; coherent with the guest's VA, and it keeps working even when
        // the guest mapping is unmapped or handed to another process.
        pub const State = struct { fd: c_int = -1 };

        pub fn init() void {}

        pub fn reserveSpan(st: *State, span: usize) ?[*]u8 {
            // Whole span as PROT_NONE (virtual only, no commit).
            const base = mmapOk(null, span, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0) orelse return null;
            // Guest backing store: one memfd the size of the growable region.
            // shmem pages materialize on first touch, so the 4gb
            // ftruncate costs nothing until the guest actually grows into it.
            const fd = memfd_create("wzs-guest", 0);
            if (fd < 0) return null;
            if (ftruncate(fd, @intCast(GUEST_LIMIT)) != 0) {
                _ = close(fd);
                return null;
            }
            st.* = .{ .fd = fd };
            return @ptrCast(base);
        }

        pub fn commitGuestPages(st: *State, at: [*]u8, guest_off: usize, len: usize) bool {
            // Identity view of the memfd: file offset == guest offset.
            // Shared, so fd-writes and guest-VA accesses hit the same pages.
            return mmapOk(@ptrCast(at), len, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, st.fd, @intCast(guest_off)) != null;
        }

        pub fn commitSwapZone(st: *State, zone: [*]u8, len: usize) bool {
            _ = st; // the zone's initial zeros need no backing of their own
            // Fresh zero pages (private anon) until the first blob swap.
            return mmapOk(@ptrCast(zone), len, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }

        pub const Blob = struct { fd: c_int, len: usize };

        pub fn blobCreate(len: usize, head: ?BlobHead) ?Blob {
            const fd = memfd_create("wzs-blob", 0);
            if (fd < 0) return null;
            if (ftruncate(fd, @intCast(len)) != 0) {
                _ = close(fd);
                return null;
            }
            if (head) |h| {
                if (pwrite(fd, @ptrCast(&h), @sizeOf(BlobHead), 0) != @sizeOf(BlobHead)) {
                    _ = close(fd);
                    return null;
                }
            }
            return .{ .fd = fd, .len = len };
        }

        pub fn blobSwapIn(zone: [*]u8, blob: Blob) bool {
            // Rebind the zone onto the blob's storage: page-table edit, zero
            // bytes moved. (MVP invariant: blob.len == SWAP_ZONE.)
            return mmapOk(@ptrCast(zone), blob.len, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, blob.fd, 0) != null;
        }

        pub fn blobReadHead(blob: Blob) BlobHead {
            // The blob's storage via its fd, bypassing the guest mapping.
            var h: BlobHead = undefined;
            if (pread(blob.fd, @ptrCast(&h), @sizeOf(BlobHead), 0) != @sizeOf(BlobHead)) fatal("pread", .{});
            return h;
        }

        pub fn blobClose(blob: Blob) void {
            _ = close(blob.fd); // like POSIX close() with a live mmap
        }

        // Out-of-band guest-memory access (identity: fd offset == guest offset).
        pub fn guestPeek32(st: *State, guest_off: usize) i32 {
            var v: i32 = undefined;
            if (pread(st.fd, @ptrCast(&v), 4, @intCast(guest_off)) != 4) fatal("pread guest", .{});
            return v;
        }

        pub fn guestPoke32(st: *State, guest_off: usize, val: i32) void {
            if (pwrite(st.fd, @ptrCast(&val), 4, @intCast(guest_off)) != 4) fatal("pwrite guest", .{});
        }
    },

    .windows => struct {
        const HANDLE = ?*anyopaque;
        const BOOL = i32;
        const DWORD = u32;

        const INVALID_HANDLE_VALUE: HANDLE = @ptrFromInt(std.math.maxInt(usize));

        // VirtualAlloc2 / VirtualFree / MapViewOfFile3 / UnmapViewOfFileEx flags
        const MEM_RESERVE: DWORD = 0x00002000;
        const MEM_RELEASE: DWORD = 0x00008000;
        const MEM_RESERVE_PLACEHOLDER: DWORD = 0x00040000;
        const MEM_PRESERVE_PLACEHOLDER: DWORD = 0x00000002;
        const MEM_REPLACE_PLACEHOLDER: DWORD = 0x00004000;
        const PAGE_NOACCESS: DWORD = 0x01;
        const PAGE_READWRITE: DWORD = 0x04;
        const FILE_MAP_READ: DWORD = 0x0001;
        const FILE_MAP_ALL_ACCESS: DWORD = 0x000F001F;

        // ancient kernel32 exports we can reliably extract
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

        // win10-1803-era placeholder exports, resolved dynamically, because
        // real Windows exports them from kernel32, but Wine only exports
        // them from kernelbase; still no k32 forwards as of wine 10
        //
        // both DLLs are always loaded in any process, so no LoadLibrary needed
        //
        // note that these are required, the fixed-zone layout has no fallback without them
        // thus, supported platforms are: win10+ / Wine >= 8.10
        //
        // a fallback path is possible, but seems complex & i believe would incur some overhead;
        // steam requires windows 10+ and was shipping supporting wine in proton since may 2024, so oh well
        // time traveling gamers not welcome, i guess
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

        // file-backed sections charge *zero* commit regardless of size
        // (pages materialize on first touch, only written pages ever take space)
        // which is what makes 4gb per module survivable here.
        // a pagefile-backed (SEC_COMMIT) section of that size would charge
        // the entire 4gb against commit at creation and OOM the box in a
        // handful of modules; 64kb sections (the blobs, the zeros) are
        // exactly what pagefile backing is for
        pub const State = struct {
            // a section backed by a sparse temp file, sized GUEST_LIMIT. Guest pages are
            // identity-offset views of it (guest byte offset == file offset), so the host
            // reads/writes live guest memory out-of-band via scratch views of the section
            guest_section: HANDLE = null,

            // 64kb pagefile-backed section providing the swap zone's initial zero contents
            zero_section: HANDLE = null,
        };

        // "memfd for windows"
        // extend a temp file to `len` bytes (sparse on NTFS and lazy on whatever filesystem wine sits on; ext4 etc.) then open a section over it
        // FILE_FLAG_DELETE_ON_CLOSE means the file vanishes when the last reference (the section, then its views) dies, even on a crash
        //
        // NOTE: A FAT-family filesystem will eagerly allocate the 4gb; NTFS or wine is fine...
        // if you're still using FAT then clearly you don't care about this sort of thing anyway?
        // TODO: probably would be worth inserting a warning here if we can detect it?
        fn makeFileSection(len: usize) ?HANDLE {
            var dir: [260]u16 = undefined;
            var path: [260]u16 = undefined;
            const prefix = [3]u16{ 'w', 'z', 's' };
            const n = GetTempPathW(dir.len, &dir);
            if (n == 0 or n + 14 > dir.len) return null;
            if (GetTempFileNameW(&dir, &prefix, 0, &path) == 0) return null; // creates the file
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
            _ = CloseHandle(file); // the section holds its own reference
            return sec;
        }

        // allocates the whole span as one placeholder
        //
        // everything else (guest views, the swap zone, blobs) is carved out of it by placeholder splits + view replacements (the guard region thus stays a bare placeholder forever)
        // the wasm page size being the same 64kb as the allocation granularity keeps every split/replacement in this file granularity-aligned for free
        pub fn reserveSpan(st: *State, span: usize) ?[*]u8 {
            st.guest_section = makeFileSection(GUEST_LIMIT) orelse return null;
            st.zero_section = CreateFileMappingW(INVALID_HANDLE_VALUE, null, PAGE_READWRITE, 0, @truncate(SWAP_ZONE), null);
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
            // view must exactly match the placeholder it replaces
            const p = MapViewOfFile3.?(section, GetCurrentProcess(), @ptrCast(at), section_off, len, MEM_REPLACE_PLACEHOLDER, PAGE_READWRITE, null, 0);
            return p != null and @intFromPtr(p.?) == @intFromPtr(at);
        }

        pub fn commitGuestPages(st: *State, at: [*]u8, guest_off: usize, len: usize) bool {
            if (!splitPlaceholder(at, len)) return false;
            // identity view: file offset == guest offset
            return mapSectionView(st.guest_section.?, at, guest_off, len);
        }

        pub fn commitSwapZone(st: *State, zone: [*]u8, len: usize) bool {
            if (!splitPlaceholder(zone, len)) return false;
            // park a zero view of the tiny pagefile-backed section over the zone; every future swap is unmap(preserve) + remap from here
            return mapSectionView(st.zero_section.?, zone, 0, len);
        }

        pub const Blob = struct { section: HANDLE, len: usize };

        pub fn blobCreate(len: usize, head: ?BlobHead) ?Blob {
            // pagefile-backed (default SEC_COMMIT): len is 64kb here, so the commit charge is trivial
            const section = CreateFileMappingW(INVALID_HANDLE_VALUE, null, PAGE_READWRITE, @truncate(len >> 32), @truncate(len), null) orelse return null;
            if (head) |h| {
                const v = MapViewOfFile(section, FILE_MAP_ALL_ACCESS, 0, 0, 0) orelse {
                    _ = CloseHandle(section);
                    return null;
                };
                const hv: *align(1) BlobHead = @ptrCast(v);
                hv.* = h;
                _ = UnmapViewOfFile(v);
            }
            return .{ .section = section, .len = len };
        }

        /// INVARIANT: `blob.len == SWAP_ZONE`, so the restored placeholder matches the incoming view exactly
        pub fn blobSwapIn(zone: [*]u8, blob: Blob) bool {
            // out with the old view (placeholder restored), in with the blob
            if (UnmapViewOfFileEx.?(@ptrCast(zone), MEM_PRESERVE_PLACEHOLDER) == 0) return false;
            return mapSectionView(blob.section, zone, 0, blob.len);
        }

        // a scratch view of the blob's own storage, entirely bypassing the guest's mapping
        pub fn blobReadHead(blob: Blob) BlobHead {
            const v = MapViewOfFile(blob.section, FILE_MAP_READ, 0, 0, 0) orelse fatal("MapViewOfFile", .{});
            defer _ = UnmapViewOfFile(v);
            const hv: *align(1) BlobHead = @ptrCast(v);
            return hv.*;
        }

        pub fn blobClose(blob: Blob) void {
            _ = CloseHandle(blob.section); // views keep the section alive
        }

        // out-of-band guest-memory access: scratch views of the same section the guest's pages are identity-mapped from
        fn guestAccess(st: *State, guest_off: usize, write: bool, val: i32) i32 {
            // MapViewOfFile offsets need 64kb alignment (== the wasm page, happily), so align down and index inside the window
            std.debug.assert(guest_off + 4 <= GUEST_LIMIT);
            const gran: usize = 64 * 1024;
            const map_off = guest_off & ~(gran - 1);
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
    },

    else => @compileError("platform nyi"),
};

const HostMem = struct {
    base: ?[*]u8 = null, // stable for the store's lifetime
    size: usize = 0, // bytes accessible to the guest right now
    capacity: usize = 0, // grows up to this (ZONE_OFF) without moving the base
    guard: usize = 0, // inaccessible span after the reservation the JIT assumes
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
        // commit [size, new_size) as more identity views of the backing store...the swap zone and guard stay intact either way
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
    maximum: usize, // maxInt(usize) means "no maximum" (C API sentinel)
    reserved_size_in_bytes: usize, // 0 means "pick your own" (C API sentinel)
    guard_size_in_bytes: usize,
    memory_ret: [*c]c.wasmtime_linear_memory_t,
) callconv(.c) ?*c.wasmtime_error_t {
    _ = ty; // borrowed for the call; don't delete
    if (host_mem.base != null)
        return c.wasmtime_error_new("host memory: MVP is wired for exactly one memory");
    const m: *HostMem = @ptrCast(@alignCast(env.?));

    const reservation: usize = if (reserved_size_in_bytes != 0) reserved_size_in_bytes else GUEST_SPAN;
    const guard: usize = guard_size_in_bytes;

    // the static-ABI layout needs the full 4gb region
    // and the zone at 0xFFFF0000 is only reachable because the JIT elides bounds checks on the strength of the reservation+guard window covering every address an unchecked access can compute
    // both properties are config-dependent, verifying them here is better than trapping mysteriously later
    if (reservation < GUEST_SPAN)
        return c.wasmtime_error_new("host memory: reservation below 4gb; the fixed swap-zone ABI requires the full 4gb (check wasmtime memory_reservation config)");
    if (reservation + guard <= GUEST_SPAN)
        return c.wasmtime_error_new("host memory: reservation+guard not above 4gb; bounds-check elision is off and the swap zone would be unreachable (check memory_reservation/memory_guard_size config)");
    if (minimum > GUEST_LIMIT)
        return c.wasmtime_error_new("host memory: module memory larger than the guest region below the swap zone");
    const no_max = maximum == std.math.maxInt(usize);
    if (!no_max and maximum == minimum)
        return c.wasmtime_error_new("host memory: min == max makes this a static heap; declare a dynamic memory so the 4gb reservation (and the zone at 0xFFFF0000) is actually honored");

    if (no_max) {
        log.debug("[host memory] minimum={d} maximum=<none> reserved={d} guard={d}", .{ minimum, reservation, guard });
    } else {
        log.debug("[host memory] minimum={d} maximum={d} reserved={d} guard={d}", .{ minimum, maximum, reservation, guard });
    }

    // Reserve the whole span as one inaccessible region, then:
    //   [0, minimum)        guest pages (identity views of the backing store)
    //   [ZONE_OFF, +64kb ) swap zone
    //   the rest            stays reserved: guest grow room, then the guard.
    const base = Platform.reserveSpan(&m.plat, reservation + guard) orelse
        return c.wasmtime_error_new("host memory: span reservation failed");
    if (!Platform.commitGuestPages(&m.plat, base, 0, minimum))
        return c.wasmtime_error_new("host memory: guest pages commit failed");
    if (!Platform.commitSwapZone(&m.plat, base + ZONE_OFF, SWAP_ZONE))
        return c.wasmtime_error_new("host memory: swap zone commit failed");

    m.base = base;
    m.size = minimum;
    m.capacity = GUEST_LIMIT; // grow room ends where the zone begins
    m.guard = guard;

    memory_ret.* = .{ // wasmtime copies this; `env` must outlive the store
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
    std.debug.assert(args.len <= 8 and results.len <= 1); // plenty for this guest
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
    log.err("wasmtime error: {s}\n", .{msg.data[0..msg.size]});
    c.wasm_byte_vec_delete(&msg);
    c.wasmtime_error_delete(e);
    return error.RuntimeFailure;
}

fn dieTrap(t: *c.wasm_trap_t) error{RuntimeFailure} {
    @branchHint(.cold);
    var msg: c.wasm_message_t = undefined;
    c.wasm_trap_message(t, &msg);
    log.err("trap: {s}\n", .{msg.data[0..msg.size]});
    c.wasm_byte_vec_delete(&msg);
    c.wasm_trap_delete(t);
    return error.RuntimeFailure;
}

fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    @branchHint(.cold);
    log.err("fatal: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}

test {
    Platform.init();

    const config = c.wasm_config_new() orelse return error.ConfigNewFailed;
    c.wasmtime_config_host_memory_creator_set(config, &memory_creator);
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

    const base = host_mem.base orelse return error.HostMemoryNotCreated;
    const st = &host_mem.plat;

    log.debug("guest memory: base=0x{x} size={d} capacity={d} guard={d}", .{ @intFromPtr(base), host_mem.size, host_mem.capacity, host_mem.guard });
    log.debug("swap zone: [0x{x}, 0x{x}) - fixed offset in every module", .{ ZONE_OFF, GUEST_SPAN });

    // sanity check: if the guest happens to export its linear memory, make sure the pointer wasmtime would hand out is our base
    {
        var item: c.wasmtime_extern_t = undefined;
        if (c.wasmtime_instance_export_get(ctx, &instance, "memory", 6, &item)) {
            if (item.kind != c.WASMTIME_EXTERN_MEMORY) return error.MemoryExportNotMemory;
            if (c.wasmtime_memory_data(ctx, &item.of.memory) != @as([*c]u8, @ptrCast(base))) return error.BasePointerMismatch;
        }
    }

    // real guest symbols for the out-of-band channel, discovered the way real interop will: exported accessors, not fixed addresses
    const scr0 = try call1ret(ctx, f_scratch, 0);
    const scr1 = try call1ret(ctx, f_scratch, 1);

    // host -> guest through the out-of-band channel
    // poke scratch[0] via the identity backing (fd / scratch view), then have the guest read it back through its own view of the same pages
    const val_a: i32 = 0xC0FFEE;
    Platform.guestPoke32(st, @intCast(scr0), val_a);
    const echoed = try call1ret(ctx, f_echo, scr0);
    log.debug("[oob] host poked {d} @ guest 0x{x}; guest echo read {d}", .{ val_a, scr0, echoed });
    if (echoed != val_a) return error.OobHostToGuestFailed;

    // guest -> host
    const val_b: i32 = @bitCast(@as(u32, 0xFEEDFACE));
    try call2(ctx, f_poke, scr1, val_b);
    const seen_b = Platform.guestPeek32(st, @intCast(scr1));
    log.debug("[oob] guest poked {d} @ guest 0x{x}; host peeked {d}", .{ val_b, scr1, seen_b });
    if (seen_b != val_b) return error.OobGuestToHostFailed;
    if (i32At(base, @intCast(scr1)).* != val_b) return error.OobChannelsDisagree; // both channels see the same pages

    // the module's memory is dynamic, so memory.grow works: the host commits more identity views below the zone
    // freshly grown pages must be identity-backed and coherent on both channels too
    const size_before = host_mem.size;
    const grow_addr: i32 = @intCast(size_before + 0x40); // inside the pages we're about to add
    if (try call1ret(ctx, f_grow, 2) != 0) return error.GrowFailed;
    if (host_mem.size != size_before + 2 * WASM_PAGE) return error.GrowSizeWrong;
    Platform.guestPoke32(st, @intCast(grow_addr), 0x5151);
    if (try call1ret(ctx, f_echo, grow_addr) != 0x5151) return error.GrowCommitInvisible;
    log.debug("[grow] +2 pages -> size={d}; fresh pages are identity-backed and both channels agree", .{host_mem.size});

    // growing past the zone must be refused with spec-conformant failure, no trap; 65536 pages = 4gb, which is past the capacity of 0xFFFF0000
    if (try call1ret(ctx, f_grow, 0x10000) != -1) return error.GrowShouldHaveFailed;
    log.debug("[grow] refused to grow past the zone (returned -1, no trap)", .{});

    // blob roundtrip through the fixed zone
    const blob_a = Platform.blobCreate(SWAP_ZONE, .{ .lhs = 10, .rhs = 32 }) orelse fatal("blobCreate(A)", .{});
    const blob_b = Platform.blobCreate(SWAP_ZONE, .{ .lhs = 7, .rhs = 5 }) orelse fatal("blobCreate(B)", .{});
    defer Platform.blobClose(blob_a);
    defer Platform.blobClose(blob_b);

    if (!Platform.blobSwapIn(base + ZONE_OFF, blob_a)) fatal("blobSwapIn(A)", .{});
    try call0(ctx, f_add);
    {
        const via_va = i32At(base, ZONE_OFF).*;
        const via_fd = Platform.blobReadHead(blob_a);
        log.debug("[A] {{10,32}} in -> add() -> zone[0]={d} (host VA); blob A via fd: {{{d}, {d}}}", .{ via_va, via_fd.lhs, via_fd.rhs });
        if (via_va != 42 or via_fd.lhs != 42 or via_fd.rhs != 32) return error.RoundtripAFailed;
    }

    if (!Platform.blobSwapIn(base + ZONE_OFF, blob_b)) fatal("blobSwapIn(B)", .{});
    try call0(ctx, f_add);
    {
        const via_va = i32At(base, ZONE_OFF).*;
        const via_fd = Platform.blobReadHead(blob_b);
        log.debug("[B] {{7,5}} in   -> add() -> zone[0]={d} (host VA); blob B via fd: {{{d}, {d}}}", .{ via_va, via_fd.lhs, via_fd.rhs });
        if (via_va != 12 or via_fd.lhs != 12 or via_fd.rhs != 5) return error.RoundtripBFailed;
    }

    // swapped-out blob mutated while live is readable out-of-band for debugging & interop and the swaps never touched guest data
    const a = Platform.blobReadHead(blob_a);
    if (a.lhs != 42 or a.rhs != 32) return error.SwappedOutBlobMutated;
    if (Platform.guestPeek32(st, @intCast(scr0)) != val_a) return error.GuestRegionMutated;
    if (Platform.guestPeek32(st, @intCast(scr1)) != val_b) return error.GuestRegionMutated;
    if (Platform.guestPeek32(st, @intCast(grow_addr)) != 0x5151) return error.GuestRegionMutated;
    log.debug("blob A (swapped out) still {{{d}, {d}}} via fd; guest data intact at 0x{x}, 0x{x}, 0x{x}", .{ a.lhs, a.rhs, scr0, scr1, grow_addr });

    log.debug("OK: zero-copy roundtrip complete", .{});
}

const std = @import("std");
const log = std.log.scoped(.wasm);
const builtin = @import("builtin");
const c = @import("module/wasm.zig");
const guest_wasm = @embedFile("guest.wasm");
