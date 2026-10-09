const Memory = @This();

alloc: base.Allocator,
base_ptr: ?[*]u8 = null,
size: usize = 0,
capacity: usize = 0,
guard: usize = 0,
plat: Platform.State = .{},

pub const wasm_page_size: usize = 64 * 1024; // 64kb
pub const wasm_region_size: usize = 1 << 32; // 4gb

pub const binding_slot_size: usize = wasm_page_size * 16; // 1mb
pub const max_binding_slots: usize = 1024;
pub const total_binding_region: usize = binding_slot_size * max_binding_slots;
pub const binding_region_base: usize = wasm_region_size - total_binding_region;
pub const swap_zone_base_offset: usize = binding_region_base + (max_binding_slots - 1) * binding_slot_size;
pub const swap_zone_size: usize = binding_slot_size;
pub const swap_zone_slot: usize = max_binding_slots - 1;

var platform_ready: bool = false;

pub fn setup_platform() void {
    if (platform_ready) return;
    platform_ready = true;
    Platform.init();
}

const Platform = switch (base.build_info.os.tag) {
    .windows => struct {
        const HANDLE = ?*anyopaque;
        const BOOL = i32;
        const DWORD = u32;

        const INVALID_HANDLE_VALUE: HANDLE = @ptrFromInt(math.maxInt(usize));

        const MEM_RESERVE: DWORD = 0x00002000;
        const MEM_RELEASE: DWORD = 0x00008000;
        const MEM_RESERVE_PLACEHOLDER: DWORD = 0x00040000;
        const MEM_PRESERVE_PLACEHOLDER: DWORD = 0x00000002;
        const MEM_REPLACE_PLACEHOLDER: DWORD = 0x00004000;
        const MEM_COALESCE_PLACEHOLDERS: DWORD = 0x00000001;
        const PAGE_NOACCESS: DWORD = 0x01;
        const PAGE_READWRITE: DWORD = 0x04;
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
                base.fatal("windows: memory placeholders required but unavailable (VirtualAlloc2/MapViewOfFile3/UnmapViewOfFileEx); need win10 1803+ or wine >= 8.10", .{});
            log.debug("[windows] swap path: placeholders (VirtualAlloc2/MapViewOfFile3/UnmapViewOfFileEx)", .{});
        }

        const max_tracked_commits: usize = 16;
        const Commit = struct { off: usize, len: usize };

        pub const State = struct {
            guest_section: HANDLE = null,
            zero_section: HANDLE = null,
            // every mapped guest-page range, tracked so teardown can
            // restore the span to pure placeholder memory and release it
            commits: [max_tracked_commits]Commit = undefined,
            n_commits: usize = 0,
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

            if (VirtualAlloc2.?(GetCurrentProcess(), null, span, MEM_RESERVE | MEM_RESERVE_PLACEHOLDER, PAGE_NOACCESS, null, 0)) |base_ptr|
                return @ptrCast(base_ptr);
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
            if (!mapSectionView(st.guest_section.?, at, guest_off, len)) return false;
            if (st.n_commits < st.commits.len) {
                st.commits[st.n_commits] = .{ .off = guest_off, .len = len };
                st.n_commits += 1;
            } else {
                log.err("windows: guest commit tracking overflow; span will leak at teardown", .{});
            }
            return true;
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

        /// Best-effort full teardown: restore every mapped view back to
        /// placeholder, coalesce the fragments bottom-to-top, release the
        /// whole span, then drop the sections. Failures only leak VA.
        pub fn releaseSpan(st: *State, base_ptr: [*]u8, span: usize, guest_size: usize) void {
            var i: usize = st.n_commits;
            while (i > 0) {
                i -= 1;
                const cm = st.commits[i];
                _ = UnmapViewOfFileEx.?(@ptrCast(base_ptr + cm.off), MEM_PRESERVE_PLACEHOLDER);
            }
            var s: usize = 0;
            while (s < max_binding_slots) : (s += 1) {
                _ = UnmapViewOfFileEx.?(@ptrCast(base_ptr + binding_region_base + s * binding_slot_size), MEM_PRESERVE_PLACEHOLDER);
            }

            var acc_base: [*]u8 = base_ptr + binding_region_base + total_binding_region;
            var acc_size: usize = span - (binding_region_base + total_binding_region);
            s = max_binding_slots;
            while (s > 0) {
                s -= 1;
                _ = VirtualFree(@ptrCast(acc_base), acc_size + binding_slot_size, MEM_RELEASE | MEM_COALESCE_PLACEHOLDERS);
                acc_size += binding_slot_size;
                acc_base = base_ptr + binding_region_base + s * binding_slot_size;
            }
            if (guest_size < binding_region_base) {
                _ = VirtualFree(@ptrCast(acc_base), acc_size + (binding_region_base - guest_size), MEM_RELEASE | MEM_COALESCE_PLACEHOLDERS);
                acc_size += binding_region_base - guest_size;
            }
            acc_base = base_ptr + guest_size;
            i = st.n_commits;
            while (i > 0) {
                i -= 1;
                const cm = st.commits[i];
                _ = VirtualFree(@ptrCast(acc_base), acc_size + cm.len, MEM_RELEASE | MEM_COALESCE_PLACEHOLDERS);
                acc_size += cm.len;
                acc_base = base_ptr + cm.off;
            }

            _ = VirtualFree(@ptrCast(base_ptr), span, MEM_RELEASE);
            if (st.guest_section) |h| _ = CloseHandle(h);
            if (st.zero_section) |h| _ = CloseHandle(h);
        }

        const Win = @This();
        pub const Blob = struct { section: HANDLE, len: usize, offset: usize = 0 };

        pub fn blobCreate(len: usize) ?Win.Blob {
            const section = CreateFileMappingW(INVALID_HANDLE_VALUE, null, PAGE_READWRITE, @truncate(len >> 32), @truncate(len), null) orelse return null;
            return .{ .section = section, .len = len, .offset = 0 };
        }

        pub fn blobDestroy(blob: Win.Blob) void {
            _ = CloseHandle(blob.section);
        }

        pub fn blobMap(blob: Win.Blob) ?[]u8 {
            const v = MapViewOfFile(blob.section, FILE_MAP_ALL_ACCESS, @truncate(blob.offset >> 32), @truncate(blob.offset), blob.len) orelse return null;
            const p: [*]u8 = @ptrCast(v);
            return p[0..blob.len];
        }

        pub fn blobUnmap(view: []u8) void {
            _ = UnmapViewOfFile(@ptrCast(view.ptr));
        }

        pub fn blobSwapIn(slot: []u8, blob: Win.Blob) bool {
            debug.assert(blob.len <= slot.len);
            _ = UnmapViewOfFileEx.?(@ptrCast(slot.ptr), MEM_PRESERVE_PLACEHOLDER);
            return mapSectionView(blob.section, slot.ptr, blob.offset, blob.len);
        }

        pub fn parkView(slot: []u8) bool {
            _ = UnmapViewOfFileEx.?(@ptrCast(slot.ptr), MEM_PRESERVE_PLACEHOLDER);
            return true;
        }

        pub fn unparkView(st: *State, slot: []u8) bool {
            _ = UnmapViewOfFileEx.?(@ptrCast(slot.ptr), MEM_PRESERVE_PLACEHOLDER);
            return mapSectionView(st.zero_section.?, slot.ptr, 0, slot.len);
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
        extern "c" fn close(fd: c_int) c_int;

        fn mmapOk(addr: ?*anyopaque, len: usize, prot: c_int, flags: c_int, fd: c_int, off: i64) ?*anyopaque {
            const p = mmap(addr, len, prot, flags, fd, off) orelse return null;
            if (@intFromPtr(p) == math.maxInt(usize)) return null;
            return p;
        }

        pub const State = struct { fd: c_int = -1 };

        pub fn init() void {}

        pub fn reserveSpan(st: *State, span: usize) ?[*]u8 {
            const base_ptr = mmapOk(null, span, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0) orelse return null;
            const fd = memfd_create("wzs-guest", 0);
            if (fd < 0) return null;
            if (ftruncate(fd, @intCast(binding_region_base)) != 0) {
                _ = close(fd);
                return null;
            }
            st.* = .{ .fd = fd };
            return @ptrCast(base_ptr);
        }

        pub fn commitGuestPages(st: *State, at: [*]u8, guest_off: usize, len: usize) bool {
            return mmapOk(@ptrCast(at), len, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, st.fd, @intCast(guest_off)) != null;
        }

        pub fn commitBindingRegion(st: *State, region: []u8) bool {
            _ = st;
            return mmapOk(@ptrCast(region.ptr), region.len, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }

        pub fn releaseSpan(st: *State, base_ptr: [*]u8, span: usize, guest_size: usize) void {
            _ = guest_size; // one munmap over the range clears every mapping inside it
            _ = munmap(@ptrCast(base_ptr), span);
            if (st.fd >= 0) _ = close(st.fd);
        }

        const Unix = @This();
        pub const Blob = struct { fd: c_int, len: usize, offset: usize = 0 };

        pub fn blobCreate(len: usize) ?Unix.Blob {
            const fd = memfd_create("wzs-blob", 0);
            if (fd < 0) return null;
            if (ftruncate(fd, @intCast(len)) != 0) {
                _ = close(fd);
                return null;
            }
            return .{ .fd = fd, .len = len, .offset = 0 };
        }

        pub fn blobDestroy(blob: Unix.Blob) void {
            _ = close(blob.fd);
        }

        pub fn blobMap(blob: Unix.Blob) ?[]u8 {
            const p = mmapOk(null, blob.len, PROT_READ | PROT_WRITE, MAP_SHARED, blob.fd, @intCast(blob.offset)) orelse return null;
            const q: [*]u8 = @ptrCast(p);
            return q[0..blob.len];
        }

        pub fn blobUnmap(view: []u8) void {
            _ = munmap(@ptrCast(view.ptr), view.len);
        }

        pub fn blobSwapIn(slot: []u8, blob: Unix.Blob) bool {
            debug.assert(blob.len <= slot.len);
            if (mmapOk(@ptrCast(slot.ptr), blob.len, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FIXED, blob.fd, @intCast(blob.offset)) == null) return false;
            if (blob.len == slot.len) return true;
            return mmapOk(@ptrCast(slot.ptr + blob.len), slot.len - blob.len, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }

        pub fn parkView(slot: []u8) bool {
            return mmapOk(@ptrCast(slot.ptr), slot.len, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }

        pub fn unparkView(_: *State, slot: []u8) bool {
            return mmapOk(@ptrCast(slot.ptr), slot.len, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != null;
        }
    },
};

/// Host-side backing store that can be swapped into a binding slot.
pub const Blob = struct {
    plat: Platform.Blob,

    pub fn init(len: usize) ?Blob {
        const plat = Platform.blobCreate(len) orelse return null;
        return .{ .plat = plat };
    }

    pub fn deinit(blob: *Blob) void {
        Platform.blobDestroy(blob.plat);
        blob.* = undefined;
    }

    pub fn map(blob: *const Blob) ?[]u8 {
        return Platform.blobMap(blob.plat);
    }

    pub fn unmap(view: []u8) void {
        Platform.blobUnmap(view);
    }

    pub fn size(blob: *const Blob) usize {
        return blob.plat.len;
    }
};

pub fn init(alloc: base.Allocator, minimum: usize, reservation: usize, guard: usize) ?*Memory {
    const m = alloc.create(Memory) catch return null;
    errdefer alloc.destroy(m);
    m.* = .{ .alloc = alloc, .guard = guard };

    const span = reservation + guard;
    const base_ptr = Platform.reserveSpan(&m.plat, span) orelse {
        log.err("host memory: span reservation failed", .{});
        return null;
    };
    if (!Platform.commitGuestPages(&m.plat, base_ptr, 0, minimum)) {
        log.err("host memory: guest pages commit failed", .{});
        Platform.releaseSpan(&m.plat, base_ptr, span, minimum);
        return null;
    }
    if (!Platform.commitBindingRegion(&m.plat, bindingSlice(base_ptr))) {
        log.err("host memory: binding region commit failed", .{});
        Platform.releaseSpan(&m.plat, base_ptr, span, minimum);
        return null;
    }

    m.base_ptr = base_ptr;
    m.size = minimum;
    m.capacity = binding_region_base;
    return m;
}

pub fn deinit(m: *Memory) void {
    if (m.base_ptr) |b| Platform.releaseSpan(&m.plat, b, wasm_region_size + m.guard, m.size);
    m.alloc.destroy(m);
}

pub fn growTo(m: *Memory, new_size: usize) bool {
    return Platform.commitGuestPages(&m.plat, m.base_ptr.? + m.size, m.size, new_size - m.size);
}

pub fn bindingSlice(base_ptr: [*]u8) []u8 {
    return (base_ptr + binding_region_base)[0..total_binding_region];
}

/// direct host view of the live guest region (zero-copy)
pub fn guestView(m: *const Memory) []u8 {
    return m.base_ptr.?[0..m.size];
}

pub fn slotView(m: *Memory, slot: usize) []u8 {
    debug.assert(slot < max_binding_slots);
    const b = m.base_ptr.?;
    return (b + binding_region_base + slot * binding_slot_size)[0..binding_slot_size];
}

/// guest-visible address of a binding slot (same in every memory)
pub fn slotAddr(slot: usize) i32 {
    debug.assert(slot < max_binding_slots);
    return @bitCast(@as(u32, @intCast(binding_region_base + slot * binding_slot_size)));
}

pub fn peek32(m: *const Memory, off: usize) i32 {
    debug.assert(off + 4 <= m.size);
    return i32At(m.base_ptr.?, off).*;
}

pub fn poke32(m: *const Memory, off: usize, val: i32) void {
    debug.assert(off + 4 <= m.size);
    i32At(m.base_ptr.?, off).* = val;
}

pub fn i32At(base_ptr: [*]u8, off: usize) *align(1) i32 {
    return @ptrCast(base_ptr + off);
}

pub fn getI32(view: []const u8, idx: usize) i32 {
    return base.mem.readInt(i32, view[idx * 4 ..][0..4], .little);
}

pub fn putI32(view: []u8, idx: usize, val: i32) void {
    base.mem.writeInt(i32, view[idx * 4 ..][0..4], val, .little);
}

/// map one binding-slot-sized page of `blob` (at `byte_offset`) into `slot`
pub fn swapBlob(m: *Memory, slot: usize, blob: Blob, byte_offset: usize) bool {
    debug.assert(byte_offset % binding_slot_size == 0);
    debug.assert(byte_offset + binding_slot_size <= blob.plat.len);
    var page = blob.plat;
    page.offset = byte_offset;
    page.len = binding_slot_size;
    return Platform.blobSwapIn(m.slotView(slot), page);
}

pub fn parkSlot(m: *Memory, slot: usize) bool {
    return Platform.parkView(m.slotView(slot));
}

pub fn unparkSlot(m: *Memory, slot: usize) bool {
    return Platform.unparkView(&m.plat, m.slotView(slot));
}

pub fn hostGetMemory(m: *Memory, byte_size: [*c]usize, byte_capacity: [*c]usize) callconv(.c) [*c]u8 {
    byte_size.* = m.size;
    byte_capacity.* = m.capacity;
    return @ptrCast(m.base_ptr.?);
}

pub fn hostGrowMemory(m: *Memory, new_size: usize) callconv(.c) ?*c.wasmtime_error_t {
    if (new_size > m.capacity)
        return c.wasmtime_error_new("host memory: grow exceeds in-place capacity");
    if (new_size > m.size and !m.growTo(new_size))
        return c.wasmtime_error_new("host memory: commit during grow failed");
    m.size = new_size;
    return null;
}

const c = @import("../wasm.zig");
const base = @import("../base.zig");
const mem = base.mem;
const math = base.math;
const debug = base.debug;

const log = base.log.scoped(.Runtime);
