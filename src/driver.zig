// public domain

//! Basic demo of the graphics api.

const Vertex = extern struct {
    pos: [2]f32,
    uv: [2]f32,
    color: [3]f32,
    image: u32,
    sampler: u32,
};

const DynamicData = extern struct {
    offset: [2]f32,
    time: f32,
};

const PushConstants = extern struct {
    vbo_address: Gpu.DeviceAddress,
    dyn_data_address: Gpu.DeviceAddress,
};

// zig fmt: off
const vertex_data = [6]struct { [2]f32, [2]f32, [3]f32 }{
    .{ .{ -0.5, -0.5 }, .{ 0, 0 }, .{ 1.0, 0.0, 0.0 } },
    .{ .{ -0.5,  0.5 }, .{ 0, 1 }, .{ 0.0, 1.0, 0.0 } },
    .{ .{  0.5, -0.5 }, .{ 1, 0 }, .{ 0.0, 0.0, 1.0 } },
    .{ .{  0.5, -0.5 }, .{ 1, 0 }, .{ 0.0, 0.0, 1.0 } },
    .{ .{ -0.5,  0.5 }, .{ 0, 1 }, .{ 0.0, 1.0, 0.0 } },
    .{ .{  0.5,  0.5 }, .{ 1, 1 }, .{ 1.0, 0.0, 0.0 } },
};
// zig fmt: on

const c = @import("module/wasm.zig");

pub fn main() anyerror!void {
    debug.print("Initializing Wasmtime Engine...\n", .{});
    const engine = c.wasm_engine_new() orelse {
        return error.WasmEngineCreationFailed;
    };
    defer c.wasm_engine_delete(engine);

    // Create a new store
    const store = c.wasmtime_store_new(engine, null, null) orelse {
        return error.WasmStoreCreationFailed;
    };
    defer c.wasmtime_store_delete(store);
    const context = c.wasmtime_store_context(store);

    debug.print("Compiling Wasm module...\n", .{});
    var module: ?*c.wasmtime_module_t = null;
    if (c.wasmtime_module_new(engine, @"add.wasm".ptr, @"add.wasm".len, &module)) |err| {
        defer c.wasmtime_error_delete(err);
        return error.WasmCompilationFailed;
    }
    defer c.wasmtime_module_delete(module);

    debug.print("Instantiating Wasm module...\n", .{});
    var instance: c.wasmtime_instance_t = undefined;
    var trap: ?*c.wasm_trap_t = null;

    // Pass null/0 since our basic module doesn't import from the host
    if (c.wasmtime_instance_new(context, module, null, 0, &instance, &trap)) |err| {
        defer c.wasmtime_error_delete(err);
        return error.WasmInstantiationFailed;
    }
    if (trap) |t| {
        defer c.wasm_trap_delete(t);
        return error.WasmInstantiationTrapped;
    }

    // Look up the exported "add" function
    const func_name = "add";
    var func_obj: c.wasmtime_extern_t = undefined;
    if (!c.wasmtime_instance_export_get(context, &instance, func_name.ptr, func_name.len, &func_obj)) {
        return error.WasmExportNotFound;
    }
    const func = func_obj.of.func;

    // Prepare arguments and result buffers
    const args = [_]c.wasmtime_val_t{
        .{ .kind = c.WASMTIME_I32, .of = .{ .i32 = 40 } },
        .{ .kind = c.WASMTIME_I32, .of = .{ .i32 = 2 } },
    };
    var results: c.wasmtime_val_t = undefined;

    debug.print("Invoking exported function '{s}'(40, 2)...\n", .{func_name});
    if (c.wasmtime_func_call(context, &func, &args, args.len, &results, 1, &trap)) |err| {
        defer c.wasmtime_error_delete(err);
        return error.WasmCallFailed;
    }
    if (trap) |t| {
        defer c.wasm_trap_delete(t);
        return error.WasmCallTrapped;
    }

    // Display result
    if (results.kind == c.WASMTIME_I32) {
        debug.print("Result: {}\n", .{results.of.i32});
    } else {
        debug.print("Unexpected return type\n", .{});
    }
}

pub fn gfx_main() anyerror!void {
    var client = try Client.init(&.{
        .application_name = "🥝 engine example app",
        .application_version = .{ .major = 0, .minor = 0, .patch = 0 },
        .main_window = .{ .title = "🥝" },
    });
    defer client.deinit();

    var ring_buffer = try Gpu.RingBuffer(DynamicData).init(client.gpu);
    defer ring_buffer.deinit(client.gpu);

    const push_constant_range = Gpu.PushConstantRange{
        .stage_flags = .{ .vertex = true },
        .offset = 0,
        .size = @sizeOf(PushConstants),
    };

    var pipeline = make_pipeline: {
        var vert_mod = try Gpu.ShaderModule.init(client.gpu, @"vert.spv");
        defer vert_mod.deinit(client.gpu);

        var frag_mod = try Gpu.ShaderModule.init(client.gpu, @"frag.spv");
        defer frag_mod.deinit(client.gpu);

        break :make_pipeline try Gpu.Pipeline.graphics(
            client.gpu,
            vert_mod,
            frag_mod,
            .@"2d",
            client.main_window.swap_chain.surface_format.format,
            .@"1",
            &.{push_constant_range},
        );
    };
    defer pipeline.deinit(client.gpu);

    var image_cpu = try Image.fromMemory(base.gpa, @"image.png");
    defer image_cpu.deinit(base.gpa);

    try image_cpu.convert(base.gpa, .rgba32);

    const image_gpu = try Gpu.Image.init(client.gpu, @intCast(image_cpu.width), @intCast(image_cpu.height));
    defer image_gpu.deinit(client.gpu);

    const image_index = image_gpu.getIndex();

    const sampler = try Gpu.Sampler.linear(client.gpu);
    const sampler_index = sampler.getIndex();

    var vertices: [vertex_data.len]Vertex = undefined;
    for (&vertex_data, 0..) |data, vertex_index| {
        vertices[vertex_index] = Vertex{
            .pos = data[0],
            .uv = data[1],
            .color = data[2],
            .image = image_index,
            .sampler = sampler_index,
        };
    }

    const vertex_buffer = try Gpu.Buffer.init(
        client.gpu,
        @sizeOf(@TypeOf(vertices)),
    );
    defer vertex_buffer.deinit(client.gpu);

    {
        const cmd = client.gpu.getCommandBuffer(0);
        defer cmd.submit();

        try cmd.syncBuffer(vertex_buffer, mem.asBytes(&vertices));
        try cmd.syncImage(image_gpu, image_cpu.rawBytes());
    }

    client.gpu.waitDeviceIdle();
    defer client.gpu.waitDeviceIdle();

    client.main_window.show();

    var frame_index: u64 = 0;

    while (!client.main_window.shouldClose()) {
        client.pollEvents();

        const frame_id: frame.Id = frame.idFromIndex(frame_index);

        const cmd = client.gpu.getCommandBuffer(frame_id);

        const dyn_data = ring_buffer.getPtr(frame_id);
        dyn_data.offset = .{ 0.0, @sin(@as(f32, @floatFromInt(frame_index)) * 0.0005) * 0.2 };
        dyn_data.time = @as(f32, @floatFromInt(frame_index)) * 0.0016;

        const win_view, const win_extent =
            client.main_window.beginFrame(frame_id, cmd) orelse {
                cmd.submit();
                frame_index += 1;
                continue;
            };

        defer {
            client.main_window.endFrame(cmd);

            cmd.submit();

            _ = client.main_window.present();

            frame_index += 1;
        }

        cmd.beginRendering(
            win_view,
            null,
            .{
                .offset = .{ .x = 0, .y = 0 },
                .extent = .{ .width = win_extent[0], .height = win_extent[1] },
            },
            linalg.vec4{ 0.1, 0.1, 0.1, 1.0 },
            null,
        );
        defer cmd.endRendering();

        cmd.setViewport(.{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(win_extent[0]),
            .height = @floatFromInt(win_extent[1]),
            .min_depth = 0,
            .max_depth = 1,
        });

        cmd.setScissor(.{
            .offset = .{ .x = 0, .y = 0 },
            .extent = .{ .width = win_extent[0], .height = win_extent[1] },
        });

        cmd.bindPipeline(&pipeline);
        defer cmd.unbindPipeline(&pipeline);

        cmd.pushConstants(PushConstants{
            .vbo_address = vertex_buffer.getDeviceAddress(client.gpu),
            .dyn_data_address = ring_buffer.getDeviceAddress(frame_id),
        });

        cmd.draw(vertex_data.len, 1, 0, 0);
    }
}

test {
    _ = base;
    _ = linalg;
    _ = Gpu;
    _ = Client;
    _ = Window;
    _ = main;
}

const @"add.wasm": []const u8 = @embedFile("add.wasm");
const @"vert.spv": []const u32 = @ptrCast(@alignCast(@embedFile("vert.spv")));
const @"frag.spv": []const u32 = @ptrCast(@alignCast(@embedFile("frag.spv")));
const @"image.png": []const u8 = @embedFile("image.png");

const kiwi = @import("module/kiwi.zig");

const Gpu = kiwi.Gpu;
const Client = kiwi.Client;
const Window = kiwi.Window;
const Image = kiwi.Image;
const frame = kiwi.frame;
const linalg = kiwi.linalg;
const base = kiwi.base;
const mem = base.mem;
const debug = base.debug;
const log = base.log.scoped(.driver);
