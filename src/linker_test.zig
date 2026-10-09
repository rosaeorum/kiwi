const linker_test = @This();

// very important note: you cannot import variables, only functions;
// extern variables compile to (i32.const 0)

pub const guest_src =
    \\extern fn foo () i32;
    \\extern "my_library_name" fn bar() i32;
    \\export fn placeholder () i32 {
    \\  return foo() + bar();
    \\}
;

test {
    debug.print("linker_test start\n", .{});
    debug.print("{s}", .{guest_wat});
    defer debug.print("linker_test end\n", .{});

    const rt = try Runtime.init(testing.allocator);
    defer rt.deinit();

    const mod = try rt.addModule(guest_wasm);

    var imports: c.wasm_importtype_vec_t = undefined;
    c.wasmtime_module_imports(mod, &imports);
    debug.print("import count: {}\n", .{imports.size});

    for (0..imports.size) |imp_index| {
        const imp = imports.data[imp_index];
        const imported_mod = c.wasm_importtype_module(imp);
        const imported_sym = c.wasm_importtype_name(imp);

        debug.print("{}: {s}.{s}\n", .{
            imp_index,
            imported_mod.*.data[0..imported_mod.*.size],
            imported_sym.*.data[0..imported_sym.*.size],
        });
    }
}

const kiwi = @import("module/kiwi.zig");
const base = kiwi.base;
const c = Runtime.c;
const Runtime = kiwi.Runtime;
const Memory = Runtime.Memory;
const Blob = Runtime.Memory.Blob;
const Instance = Runtime.Instance;

const debug = base.debug;
const testing = base.testing;

const guest_wat = @embedFile("guest.wat");
const guest_wasm = @embedFile("guest.wasm");

const log = base.log.scoped(.linker_test);
