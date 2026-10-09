const Instance = @This();

runtime: *Runtime,
handle: c.wasmtime_instance_t,
memory: *Memory,

pub fn @"export"(self: Instance, name: []const u8) !c.wasmtime_extern_t {
    var item: c.wasmtime_extern_t = undefined;
    if (!c.wasmtime_instance_export_get(self.runtime.context(), &self.handle, name.ptr, name.len, &item)) {
        log.debug("missing export \"{s}\"", .{name});
        return error.MissingExport;
    }
    return item;
}

pub fn func(self: Instance, name: []const u8) !c.wasmtime_func_t {
    const item = try self.@"export"(name);
    if (item.kind != c.WASMTIME_EXTERN_FUNC) {
        log.debug("export \"{s}\" is not a function", .{name});
        return error.ExportNotAFunction;
    }
    return item.of.func;
}

pub fn call(self: Instance, name: []const u8, args: []const i32, results: []i32) !void {
    const f = try self.func(name);
    try self.runtime.call(f, args, results);
}

const c = @import("../wasm.zig");
const base = @import("../base.zig");
const Runtime = @import("../Runtime.zig");
const Memory = @import("Memory.zig");

const log = base.log.scoped(.Runtime);
