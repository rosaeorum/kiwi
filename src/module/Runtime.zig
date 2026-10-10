const Runtime = @This();

alloc: base.Allocator,
arena: base.Arena,
engine: *c.wasm_engine_t,
store: *c.wasmtime_store_t,
modules: base.ArrayList(*c.wasmtime_module_t) = .empty,
instances: base.StringArrayMap(*Instance) = .empty,
memories: base.ArrayList(*Memory) = .empty,
memory_creator: c.wasmtime_memory_creator_t,

pub const c = @import("wasm.zig");
pub const Memory = @import("Runtime/Memory.zig");
pub const Instance = @import("Runtime/Instance.zig");

pub const max_call_args: usize = Memory.max_binding_slots + 8;
pub const max_call_results: usize = 8;

pub fn init(alloc: base.Allocator) !*Runtime {
    Memory.setup_platform();

    var arena = base.Arena.init(alloc);
    errdefer arena.deinit();

    const self = try arena.allocator().create(Runtime);
    self.* = .{
        .alloc = alloc,
        .arena = arena,
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
    var arena = self.arena;
    arena.deinit();
}

pub fn addModule(self: *Runtime, wasm: []const u8) !*c.wasmtime_module_t {
    var module: ?*c.wasmtime_module_t = null;
    if (c.wasmtime_module_new(
        self.engine,
        wasm.ptr,
        wasm.len,
        &module,
    )) |e|
        return dieError(e);
    errdefer c.wasmtime_module_delete(module.?);
    const m = module orelse return error.ModuleNewFailed;
    try self.modules.append(self.alloc, m);
    return m;
}

pub fn instantiate(self: *Runtime, module_name: []const u8, module: *c.wasmtime_module_t) !*Instance {
    const gop = try self.instances.getOrPut(self.alloc, module_name);
    if (gop.found_existing) {
        return error.ModuleNameAlreadyRegistered;
    }
    errdefer _ = self.instances.swapRemove(module_name);

    gop.key_ptr.* = try self.arena.allocator().dupe(u8, module_name);

    var imports: c.wasm_importtype_vec_t = undefined;
    c.wasmtime_module_imports(module, &imports);
    defer imports.wasm_importtype_vec_delete();

    var args = base.ArrayList(c.wasmtime_extern_t).empty;
    defer args.deinit(self.alloc);

    args: for (0..imports.size) |imp_index| {
        const imp = imports.data[imp_index];
        const imported_mod_bvec = c.wasm_importtype_module(imp);
        const imported_sym_bvec = c.wasm_importtype_name(imp);
        const imported_ty = c.wasm_importtype_type(imp).?;

        const imported_mod = imported_mod_bvec.*.data[0..imported_mod_bvec.*.size];
        const imported_sym = imported_sym_bvec.*.data[0..imported_sym_bvec.*.size];

        if (mem.eql(u8, "env", imported_mod)) {
            base.todo(noreturn);
        } else if (self.instances.get(imported_mod)) |existing_instance| {
            var exports: c.wasm_exporttype_vec_t = undefined;
            c.wasmtime_module_exports(existing_instance.module, &exports);
            defer exports.wasm_exporttype_vec_delete();

            for (0..exports.size) |exp_index| {
                const exp = exports.data[exp_index];
                const exported_sym_bvec = c.wasm_exporttype_name(exp);
                const exported_sym = exported_sym_bvec.*.data[0..exported_sym_bvec.*.size];

                if (mem.eql(u8, imported_sym, exported_sym)) {
                    const exported_ty = c.wasm_exporttype_type(exp).?;

                    if (!externtypeSame(imported_ty, exported_ty)) {
                        if (!base.build_info.is_test or base.testing.log_level == .debug)
                            log.err(
                                "cannot link module `{s}`: type mismatch for imported symbol '{s}' from module '{s}'",
                                .{ module_name, imported_sym, imported_mod },
                            );
                        return error.TypeMismatch;
                    }

                    const value = existing_instance.@"export"(imported_sym) catch unreachable;
                    try args.append(self.alloc, value);
                    continue :args;
                }
            }

            if (!base.build_info.is_test or base.testing.log_level == .debug)
                log.err(
                    "cannot link module `{s}`: imported module `{s}` does not export a symbol `{s}`",
                    .{ module_name, imported_mod, imported_sym },
                );
            return error.MissingImport;
        } else {
            if (!base.build_info.is_test or base.testing.log_level == .debug)
                log.err(
                    "cannot link module `{s}`: imported module `{s}` does not exist",
                    .{ module_name, imported_mod },
                );
            return error.MissingImport;
        }
    }

    const inst = try self.arena.allocator().create(Instance);
    gop.value_ptr.* = inst;

    const mem_before = self.memories.items.len;
    var trap: ?*c.wasm_trap_t = null;
    var handle: c.wasmtime_instance_t = undefined;

    if (c.wasmtime_instance_new(
        self.context(),
        module,
        args.items.ptr,
        args.items.len,
        &handle,
        &trap,
    )) |e|
        return dieError(e);

    if (trap) |t|
        return dieTrap(t);

    if (self.memories.items.len != mem_before + 1) {
        log.err("instantiate: expected exactly one host memory per instance", .{});
        return error.MemoryCountMismatch;
    }

    inst.* = Instance{
        .runtime = self,
        .module = module,
        .handle = handle,
        .memory = self.memories.items[mem_before],
    };

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

fn call1(inst: *Instance, name: []const u8, a: i32) !i32 {
    var r: [1]i32 = undefined;
    try inst.call(name, &.{a}, &r);
    return r[0];
}

fn expectTrap(inst: *Instance, name: []const u8, arg: i32) !void {
    _ = call1(inst, name, arg) catch return;
    return error.ExpectedTrap;
}

fn externtypeSame(a: *const c.wasm_externtype_t, b: *const c.wasm_externtype_t) bool {
    const kind_a = c.wasm_externtype_kind(a);
    const kind_b = c.wasm_externtype_kind(b);
    if (kind_a != kind_b) return false;

    switch (kind_a) {
        c.WASM_EXTERN_FUNC => {
            const func_a = c.wasm_externtype_as_functype_const(a).?;
            const func_b = c.wasm_externtype_as_functype_const(b).?;

            const params_a = c.wasm_functype_params(func_a).*;
            const params_b = c.wasm_functype_params(func_b).*;
            if (!valtypeVecSame(params_a, params_b)) return false;

            const results_a = c.wasm_functype_results(func_a).*;
            const results_b = c.wasm_functype_results(func_b).*;
            return valtypeVecSame(results_a, results_b);
        },
        c.WASM_EXTERN_GLOBAL => {
            const glob_a = c.wasm_externtype_as_globaltype_const(a).?;
            const glob_b = c.wasm_externtype_as_globaltype_const(b).?;

            if (c.wasm_globaltype_mutability(glob_a) != c.wasm_globaltype_mutability(glob_b)) return false;

            const ty_a = c.wasm_globaltype_content(glob_a);
            const ty_b = c.wasm_globaltype_content(glob_b);
            return c.wasm_valtype_kind(ty_a) == c.wasm_valtype_kind(ty_b);
        },
        c.WASM_EXTERN_TABLE => {
            const tab_a = c.wasm_externtype_as_tabletype_const(a).?;
            const tab_b = c.wasm_externtype_as_tabletype_const(b).?;

            const el_a = c.wasm_tabletype_element(tab_a);
            const el_b = c.wasm_tabletype_element(tab_b);
            if (c.wasm_valtype_kind(el_a) != c.wasm_valtype_kind(el_b)) return false;

            const lim_a = c.wasm_tabletype_limits(tab_a).*;
            const lim_b = c.wasm_tabletype_limits(tab_b).*;
            return lim_a.min == lim_b.min and lim_a.max == lim_b.max;
        },
        c.WASM_EXTERN_MEMORY => {
            const mem_a = c.wasm_externtype_as_memorytype_const(a).?;
            const mem_b = c.wasm_externtype_as_memorytype_const(b).?;

            const lim_a = c.wasm_memorytype_limits(mem_a).*;
            const lim_b = c.wasm_memorytype_limits(mem_b).*;
            return lim_a.min == lim_b.min and lim_a.max == lim_b.max;
        },
        else => return false,
    }
}

fn valtypeVecSame(a: c.wasm_valtype_vec_t, b: c.wasm_valtype_vec_t) bool {
    if (a.size != b.size) return false;
    for (0..a.size) |i| {
        if (c.wasm_valtype_kind(a.data[i]) != c.wasm_valtype_kind(b.data[i])) {
            return false;
        }
    }
    return true;
}

const base = @import("base.zig");

const mem = base.mem;
const math = base.math;
const debug = base.debug;

const log = base.log.scoped(.Runtime);
