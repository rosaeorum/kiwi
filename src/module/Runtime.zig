const Runtime = @This();

alloc: base.Allocator,
engine: *c.wasm_engine_t,
store: *c.wasmtime_store_t,
modules: base.ArrayList(*c.wasmtime_module_t) = .empty,
instances: base.ArrayList(Instance) = .empty,
memories: base.ArrayList(*Memory) = .empty,
memory_creator: c.wasmtime_memory_creator_t,

pub const c = @import("wasm.zig");
pub const Memory = @import("Runtime/Memory.zig");
pub const Instance = @import("Runtime/Instance.zig");

pub const max_call_args: usize = Memory.max_binding_slots + 8;
pub const max_call_results: usize = 8;

pub fn init(alloc: base.Allocator) !*Runtime {
    Memory.setup_platform();

    const self = try alloc.create(Runtime);
    errdefer alloc.destroy(self);
    self.* = .{
        .alloc = alloc,
        .engine = undefined,
        .store = undefined,
        .memory_creator = .{
            .env = @ptrCast(self),
            .new_memory = @ptrCast(&hostNewMemory),
            .finalizer = null,
        },
    };

    const config = c.wasm_config_new() orelse return error.ConfigNewFailed;
    c.wasmtime_config_host_memory_creator_set(config, &self.memory_creator);
    c.wasmtime_config_memory_init_cow_set(config, false);
    c.wasmtime_config_memory_reservation_set(config, Memory.wasm_region_size);
    c.wasmtime_config_memory_guard_size_set(config, Memory.wasm_region_size);
    c.wasmtime_config_memory_may_move_set(config, false);
    c.wasmtime_config_wasm_simd_set(config, true);

    const engine = c.wasm_engine_new_with_config(config) orelse return error.EngineNewFailed;
    self.engine = engine;
    errdefer c.wasm_engine_delete(self.engine);

    const store = c.wasmtime_store_new(engine, null, null) orelse return error.StoreNewFailed;
    self.store = store;
    errdefer c.wasmtime_store_delete(self.store);

    return self;
}

pub fn deinit(self: *Runtime) void {
    for (self.modules.items) |m| c.wasmtime_module_delete(m);
    c.wasmtime_store_delete(self.store);
    c.wasm_engine_delete(self.engine);
    for (self.memories.items) |m| m.deinit();
    self.modules.deinit(self.alloc);
    self.instances.deinit(self.alloc);
    self.memories.deinit(self.alloc);
    const alloc = self.alloc;
    alloc.destroy(self);
}

pub fn addModule(self: *Runtime, wasm: []const u8) !*c.wasmtime_module_t {
    var module: ?*c.wasmtime_module_t = null;
    if (c.wasmtime_module_new(self.engine, wasm.ptr, wasm.len, &module)) |e| return dieError(e);
    errdefer c.wasmtime_module_delete(module.?);
    const m = module orelse return error.ModuleNewFailed;
    try self.modules.append(self.alloc, m);
    return m;
}

/// instantiate `module`, binding `imports` (in the module's declared import order); pass other instance's `export(...)` items to link modules
pub fn instantiate(self: *Runtime, module: *c.wasmtime_module_t, imports: []const c.wasmtime_extern_t) !Instance {
    const mem_before = self.memories.items.len;
    var trap: ?*c.wasm_trap_t = null;
    var handle: c.wasmtime_instance_t = undefined;
    if (c.wasmtime_instance_new(self.context(), module, imports.ptr, imports.len, &handle, &trap)) |e| return dieError(e);
    if (trap) |t| return dieTrap(t);
    if (self.memories.items.len != mem_before + 1) {
        log.err("instantiate: expected exactly one host memory per instance", .{});
        return error.MemoryCountMismatch;
    }
    const inst = Instance{ .runtime = self, .handle = handle, .memory = self.memories.items[mem_before] };
    try self.instances.append(self.alloc, inst);
    return inst;
}

pub fn context(self: *Runtime) *c.wasmtime_context_t {
    return c.wasmtime_store_context(self.store) orelse @panic("wasmtime_store_context returned null");
}

threadlocal var argv: [max_call_args]c.wasmtime_val_t = undefined;

/// hot-path call on a cached func handle; `results.len` must match the function's result count
pub fn call(self: *Runtime, f: c.wasmtime_func_t, args: []const i32, results: []i32) !void {
    debug.assert(args.len <= max_call_args and results.len <= max_call_results);
    for (args, 0..) |a, i| {
        argv[i] = .{ .kind = c.WASMTIME_I32, .of = .{ .i32 = a } };
    }
    var retv: [max_call_results]c.wasmtime_val_t = undefined;
    var trap: ?*c.wasm_trap_t = null;
    if (c.wasmtime_func_call(self.context(), &f, &argv, args.len, &retv, results.len, &trap)) |e| return dieError(e);
    if (trap) |t| return dieTrap(t);
    for (results, 0..) |*r, i| {
        if (retv[i].kind != c.WASMTIME_I32) return error.UnexpectedResultType;
        r.* = retv[i].of.i32;
    }
}

pub fn hostNewMemory(
    eng: *Runtime,
    ty: ?*const c.wasm_memorytype_t,
    minimum: usize,
    maximum: usize,
    reserved_size_in_bytes: usize,
    guard_size_in_bytes: usize,
    memory_ret: [*c]c.wasmtime_linear_memory_t,
) callconv(.c) ?*c.wasmtime_error_t {
    _ = ty;

    const reservation: usize = if (reserved_size_in_bytes != 0) reserved_size_in_bytes else Memory.wasm_region_size;
    const guard: usize = guard_size_in_bytes;

    if (reservation < Memory.wasm_region_size)
        return c.wasmtime_error_new("host memory: reservation below 4gb; the fixed swap-zone ABI requires the full 4gb (check wasmtime memory_reservation config)");
    if (reservation + guard <= Memory.wasm_region_size)
        return c.wasmtime_error_new("host memory: reservation+guard not above 4gb; bounds-check elision is off and the swap zone would be unreachable (check memory_reservation/memory_guard_size config)");
    if (minimum > Memory.binding_region_base)
        return c.wasmtime_error_new("host memory: module memory larger than the guest region below the binding region");
    const no_max = maximum == math.maxInt(usize);
    if (!no_max and maximum == minimum)
        return c.wasmtime_error_new("host memory: min == max makes this a static heap; declare a dynamic memory so the 4gb reservation (and the zone at 0xFFFF0000) is actually honored");

    if (no_max) {
        log.debug("[host memory] minimum={d} maximum=<none> reserved={d} guard={d}", .{ minimum, reservation, guard });
    } else {
        log.debug("[host memory] minimum={d} maximum={d} reserved={d} guard={d}", .{ minimum, maximum, reservation, guard });
    }

    const m = Memory.init(eng.alloc, minimum, reservation, guard) orelse
        return c.wasmtime_error_new("host memory: platform setup failed");
    eng.memories.append(eng.alloc, m) catch {
        m.deinit();
        return c.wasmtime_error_new("host memory: registry append failed");
    };

    memory_ret.* = .{
        .env = @ptrCast(m),
        .get_memory = @ptrCast(&Memory.hostGetMemory),
        .grow_memory = @ptrCast(&Memory.hostGrowMemory),
        .finalizer = null,
    };

    return null;
}

fn dieError(e: *c.wasmtime_error_t) error{RuntimeFailure} {
    @branchHint(.cold);
    var msg: c.wasm_name_t = undefined;
    c.wasmtime_error_message(e, &msg);
    if (!base.build_info.is_test or base.testing.log_level == .debug) log.err("wasm error: {s}\n", .{msg.data[0..msg.size]});
    c.wasm_byte_vec_delete(&msg);
    c.wasmtime_error_delete(e);
    return error.RuntimeFailure;
}

fn dieTrap(t: *c.wasm_trap_t) error{RuntimeFailure} {
    @branchHint(.cold);
    var msg: c.wasm_message_t = undefined;
    c.wasm_trap_message(t, &msg);
    if (!base.build_info.is_test or base.testing.log_level == .debug) log.err("wasm trap: {s}\n", .{msg.data[0..msg.size]});
    c.wasm_byte_vec_delete(&msg);
    c.wasm_trap_delete(t);
    return error.RuntimeFailure;
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

const base = @import("base.zig");

const mem = base.mem;
const math = base.math;
const debug = base.debug;

const log = base.log.scoped(.Runtime);
