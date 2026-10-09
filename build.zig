var is_windows: bool = undefined;
var target: Build.ResolvedTarget = undefined;
var wasm_target: Build.ResolvedTarget = undefined;
var optimize: base.zig_builtin.Optimize = undefined;

var zon_version: base.SemanticVersion = undefined;

var translate_c_dep: *Build.Dependency = undefined;
var vulkan_headers: *Build.Dependency = undefined;
var vulkan_dep: *Build.Dependency = undefined;
var vma_dep: *Build.Dependency = undefined;
var wasmtime_dep: *Build.Dependency = undefined;

var glfw_lib: *Build.Step.Compile = undefined;
var vma_lib: *Build.Step.Compile = undefined;
var spv_patcher: *Build.Step.Compile = undefined;
var wasmtime_lib_path: Build.LazyPath = undefined;
var static_config: *Build.Step.Options = undefined;

pub fn build(b: *Build) !void {
    const check_step = b.step("check", "Run semantic analysis");
    const test_step = b.step("test", "Run unit tests");

    target = b.standardTargetOptions(.{});
    wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .cpu_features_add = base.Target.wasm.featureSet(&.{.simd128}),
    });
    optimize = b.standardOptimizeOption(.{});

    is_windows = target.result.os.tag == .windows;

    var zon_diag = zon.parse.Diagnostics{};
    const zon_data = zon.parse.fromSliceAlloc(
        struct { version: [:0]const u8 },
        b.allocator,
        zon_text,
        &zon_diag,
        .{ .ignore_unknown_fields = true },
    ) catch {
        debug.panic(
            "Failed to parse build.zig.zon:{f}\n",
            .{zon_diag},
        );
    };

    zon_version = base.SemanticVersion.parse(zon_data.version) catch |err| {
        debug.panic(
            "Failed to parse build.zig.zon version: {s}\n",
            .{@errorName(err)},
        );
    };

    translate_c_dep = b.dependency("translate_c", .{});
    vulkan_headers = b.dependency("vulkan_headers", .{});
    vulkan_dep = b.dependency("vulkan", .{
        .target = b.graph.host,
        .optimize = .safe,
    });
    vma_dep = b.dependency("vma", .{});
    wasmtime_dep = try if (is_windows)
        b.dependencyLazy("wasmtime_mingw", .{})
    else
        b.dependencyLazy("wasmtime_linux", .{});

    glfw_lib = buildGlfw(b);
    vma_lib = buildVk(b);
    spv_patcher = buildSpvPatcher(b);
    wasmtime_lib_path = buildWasmtime(b);
    static_config = buildStaticConfig(b);

    const kiwi_mod = createModule(b, "kiwi", b.path("src/module/kiwi.zig"));
    const driver_mod = createModule(b, null, b.path("src/driver.zig"));
    const runtime_test_mod = createModule(b, null, b.path("src/runtime_test.zig"));

    const kiwi_test = b.addTest(.{
        .root_module = kiwi_mod,
        .use_lld = true,
        .use_llvm = true,
    });
    check_step.dependOn(&kiwi_test.step);
    const kiwi_test_run = b.addRunArtifact(kiwi_test);
    test_step.dependOn(&kiwi_test_run.step);

    // NOTE: there is a bug on linux where static linking wasmtime fails under self hosted linker; must use lld for now

    const driver_exe = b.addExecutable(.{
        .name = "driver",
        .root_module = driver_mod,
        .use_lld = true,
        .use_llvm = true,
    });
    check_step.dependOn(&driver_exe.step);
    test_step.dependOn(&driver_exe.step);
    b.installArtifact(driver_exe);

    const driver_run = b.addRunArtifact(driver_exe);
    const run_driver_step = b.step("run-driver", "Run the driver");
    run_driver_step.dependOn(&driver_run.step);

    const runtime_test = b.addTest(.{
        .root_module = runtime_test_mod,
        .use_lld = true,
        .use_llvm = true,
    });
    check_step.dependOn(&runtime_test.step);
    const runtime_test_run = b.addRunArtifact(runtime_test);
    test_step.dependOn(&runtime_test_run.step);

    const runtime_test_bench = b.addExecutable(.{
        .name = "runtime_test",
        .root_module = runtime_test_mod,
        .use_lld = true,
        .use_llvm = true,
    });
    check_step.dependOn(&runtime_test_bench.step);
    test_step.dependOn(&runtime_test_bench.step);
    b.installArtifact(runtime_test_bench);

    const bench_run = b.addRunArtifact(runtime_test_bench);
    const run_bench_step = b.step("run-bench", "Run the runtime benchmark");
    run_bench_step.dependOn(&bench_run.step);
}

fn createModule(b: *Build, pub_name: ?[]const u8, root_src_file: Build.LazyPath) *Build.Module {
    const mod = b.createModule(.{
        .root_source_file = root_src_file,
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });

    if (pub_name) |name| {
        const graph = b.graph;
        const arena = graph.arena;
        const gop = b.modules.getOrPutValue(
            arena,
            graph.dupeString(name),
            mod,
        ) catch @panic("OOM");
        base.debug.assert(!gop.found_existing);
    }

    mod.linkLibrary(glfw_lib);
    mod.linkLibrary(vma_lib);
    mod.addLibraryPath(wasmtime_lib_path);
    mod.linkSystemLibrary("wasmtime", .{ .preferred_link_mode = .static });
    if (is_windows) {
        const win_deps: []const []const u8 = &.{ "ws2_32", "advapi32", "userenv", "ntdll", "shell32", "ole32", "bcrypt" };
        for (win_deps) |win_dep| {
            mod.linkSystemLibrary(win_dep, .{});
        }
    } else {
        const nix_deps: []const []const u8 = &.{ "m", "dl", "pthread" };
        for (nix_deps) |nix_dep| {
            mod.linkSystemLibrary(nix_dep, .{});
        }
    }

    mod.addOptions("static_config", static_config);

    mod.addImport("c_builtins", translate_c_dep.module("c_builtins"));
    mod.addImport("helpers", translate_c_dep.module("helpers"));

    const runtime_guest_src_write = mod.owner.addWriteFiles();
    const runtime_guest_a_src = runtime_guest_src_write.add("runtime_test_guest_a.zig", runtime_test_src.guest_a_src);
    const runtime_guest_a_wasm = addZigScript(mod.owner, "runtime_test_guest_a", runtime_guest_a_src);
    mod.addAnonymousImport("guest_a.wasm", .{ .root_source_file = runtime_guest_a_wasm });

    const runtime_guest_b_src = runtime_guest_src_write.add("runtime_test_guest_b.zig", runtime_test_src.guest_b_src);
    const runtime_guest_b_wasm = addZigScript(mod.owner, "runtime_test_guest_b", runtime_guest_b_src);
    mod.addAnonymousImport("guest_b.wasm", .{ .root_source_file = runtime_guest_b_wasm });

    mod.addAnonymousImport("vert.spv", .{
        .root_source_file = addZigShader(mod.owner, "vert", mod.owner.path("static/shader/min.zig"), false),
        //compileGlsl(mod.owner, mod.owner.path("static/shader/min.vert")),
    });

    mod.addAnonymousImport("frag.spv", .{
        .root_source_file = addZigShader(mod.owner, "frag", mod.owner.path("static/shader/min.zig"), true),
        //compileGlsl(mod.owner, mod.owner.path("static/shader/min.frag")),
    });

    mod.addAnonymousImport("image.png", .{
        .root_source_file = mod.owner.path("static/image/zig-mark.png"),
    });

    return mod;
}

fn LazyPathMap(comptime V: type) type {
    return base.CustomArrayMap(
        Build.LazyPath,
        V,
        struct {
            pub fn eql(_: @This(), a: Build.LazyPath, b: Build.LazyPath, _: u64) bool {
                if (meta.activeTag(a) != b) return false;
                switch (a) {
                    .src_path => |a_sp| {
                        const b_sp = b.src_path;
                        if (a_sp.owner != b_sp.owner) return false;
                        if (mem.eql(u8, a_sp.sub_path, b_sp.sub_path)) return false;
                    },
                    .generated => |*a_gen| {
                        const b_gen = &b.generated;
                        if (a_gen.index != b_gen.index) return false;
                        if (a_gen.up != b_gen.up) return false;
                        if (mem.eql(u8, a_gen.sub_path, b_gen.sub_path)) return false;
                    },
                    .cwd_relative => |a_rel_path| {
                        const b_rel_path = b.cwd_relative;
                        if (!mem.eql(u8, a_rel_path, b_rel_path)) return false;
                    },
                    .relative => |a_relative| return a_relative.eql(b.relative),
                    .dependency => |a_dep| {
                        const b_dep = b.dependency;
                        if (a_dep.dependency != b_dep.dependency) return false;
                        if (!mem.eql(u8, a_dep.sub_path, b_dep.sub_path)) return false;
                    },
                }
                return true;
            }

            pub fn hash(_: @This(), lp: Build.LazyPath) u32 {
                var hasher: base.Wyhash = .init(0);

                switch (lp) {
                    .src_path => |sp| {
                        hasher.update(sp.owner.pkg_hash);
                        hasher.update(sp.sub_path);
                    },
                    .generated => |gen| {
                        hasher.update(@ptrCast(&gen.index));
                        hasher.update(@ptrCast(&gen.up));
                        hasher.update(gen.sub_path);
                    },
                    .cwd_relative => |rel_path| {
                        hasher.update(rel_path);
                    },
                    .relative => |r| {
                        hasher.update(@ptrCast(&r.base));
                        hasher.update(@ptrCast(&r.sub_path));
                    },
                    .dependency => |dep| {
                        hasher.update(dep.dependency.builder.pkg_hash);
                        hasher.update(dep.sub_path);
                    },
                }

                return @truncate(hasher.final());
            }
        },
        true,
    );
}

var zig_script_cache: LazyPathMap(Build.LazyPath) = .empty;

fn addZigScript(
    b: *Build,
    name: []const u8,
    script_source: Build.LazyPath,
) Build.LazyPath {
    const gop = zig_script_cache.getOrPut(b.allocator, script_source) catch @panic("OOM");

    if (!gop.found_existing) {
        const shader_mod = b.createModule(.{
            .root_source_file = script_source,
            .target = wasm_target,
            .optimize = .fast,
        });

        const script_obj = b.addExecutable(.{
            .name = name,
            .root_module = shader_mod,
            .use_llvm = true,
            .use_lld = true,
        });

        script_obj.entry = .disabled;
        script_obj.rdynamic = true;

        b.installArtifact(script_obj);

        gop.value_ptr.* = script_obj.getEmittedBin();
    }

    return gop.value_ptr.*;
}

var zig_shader_cache: LazyPathMap(struct { frag: ?Build.LazyPath, vert: ?Build.LazyPath }) = .empty;

fn buildSpvPatcher(
    b: *Build,
) *Build.Step.Compile {
    return b.addExecutable(.{
        .name = "spv_patch",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/spv_patch.zig"),
            .target = b.graph.host,
            .optimize = .debug,
        }),
    });
}

fn addZigShader(
    b: *Build,
    name: []const u8,
    shader_source: Build.LazyPath,
    is_fragment: bool,
) Build.LazyPath {
    const gop = zig_shader_cache.getOrPut(b.allocator, shader_source) catch @panic("OOM");

    if (!gop.found_existing) {
        gop.value_ptr.* = .{ .frag = null, .vert = null };
    }

    if (is_fragment and gop.value_ptr.frag != null) return gop.value_ptr.frag.?;
    if (!is_fragment and gop.value_ptr.vert != null) return gop.value_ptr.vert.?;

    const options = b.addOptions();
    options.addOption(bool, "is_fragment", is_fragment);

    const shader_mod = b.createModule(.{
        .root_source_file = shader_source,
        .target = b.resolveTargetQuery(base.Target.Query.parse(.{
            .arch_os_abi = "spirv64-vulkan-none",
            .cpu_features = "baseline+runtime_descriptor_array",
        }) catch |err| base.debug.panic("failed to configure spirv target: {s}", .{@errorName(err)})),
        .optimize = .fast,
    });

    shader_mod.addOptions("config", options);

    const shader_obj = b.addExecutable(.{
        .name = name,
        .root_module = shader_mod,
        .use_llvm = false,
        .use_lld = false,
    });

    const patch_run = b.addRunArtifact(spv_patcher);
    patch_run.addArtifactArg2(shader_obj, .{});
    const patched_spv = patch_run.addOutputFileArg(b.fmt("{s}_patched.spv", .{name}));

    if (is_fragment) {
        gop.value_ptr.frag = patched_spv;
    } else {
        gop.value_ptr.vert = patched_spv;
    }

    return patched_spv;
}

var glsl_cache: LazyPathMap(Build.LazyPath) = .empty;

fn compileGlsl(b: *Build, source: Build.LazyPath) Build.LazyPath {
    const gop = glsl_cache.getOrPut(b.allocator, source) catch @panic("OOM");

    if (!gop.found_existing) {
        const glslc = b.addSystemCommand(&.{"glslc"});

        glslc.addPrefixedDirectoryArg("-I", b.path("static/shader/include/"));

        glslc.addFileArg(source);

        gop.value_ptr.* = glslc.addPrefixedOutputFileArg(
            "-o",
            b.fmt("{s}.spv", .{path.basename(source.getDisplayName())}),
        );
    }

    return gop.value_ptr.*;
}

fn buildStaticConfig(b: *Build) *Build.Step.Options {
    const conf = b.addOptions();
    conf.addOption(base.SemanticVersion, "engine_version", zon_version);

    inline for (comptime base.meta.declarations(config)) |prop_name| {
        const prop = @field(config, prop_name);

        conf.addOption(
            prop.type,
            prop_name,
            @min(
                @max(
                    b.option(
                        prop.type,
                        prop_name,
                        b.fmt(
                            prop.description ++ "default: {d}, min: {d}, max: {d}",
                            .{ prop.default, prop.min, prop.max },
                        ),
                    ) orelse prop.default,
                    prop.min,
                ),
                prop.max,
            ),
        );
    }

    return conf;
}

fn buildWasmtime(b: *Build) Build.LazyPath {
    const wasmtime_include = wasmtime_dep.path("include");

    const t = Translator.init(translate_c_dep, .{
        .c_source_file = b.addWriteFiles().add(
            "wasm.c",
            \\#include "wasm.h"
            \\#include "wasi.h"
            \\#include "wasmtime.h"
            ,
        ),
        .target = target,
        .optimize = optimize,
    });

    t.defineCMacro("WASM_API_EXTERN", "");
    t.defineCMacro("WASI_API_EXTERN", "");

    t.addIncludePath(wasmtime_include);

    const wasmtime_bindings = t.output_file;

    const write_wasm_bindings_source = b.addUpdateSourceFiles();
    write_wasm_bindings_source.addCopyFileToSource(wasmtime_bindings, "src/module/wasm.zig");

    const wasm_bindgen_step = b.step("gen-wasm", "run translate-c to update src/module/wasmtime.zig");
    wasm_bindgen_step.dependOn(&write_wasm_bindings_source.step);

    return wasmtime_dep.path("lib/");
}

fn buildVk(b: *Build) *Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "vma",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        }),
    });

    lib.root_module.addIncludePath(vulkan_headers.path("include"));

    lib.root_module.addCMacro("VMA_IMPLEMENTATION", "");
    lib.root_module.addCMacro("VMA_STATIC_VULKAN_FUNCTIONS", "0");
    lib.root_module.addCSourceFile(.{
        .file = vma_dep.path("include/vk_mem_alloc.h"),
        .language = .cpp,
    });

    const vulkan_bindgen = vulkan_dep.artifact("vulkan-zig-generator");
    const vulkan_bindgen_run = b.addRunArtifact(vulkan_bindgen);

    vulkan_bindgen_run.addFileArg2(vulkan_headers.path("registry/vk.xml"), .{});
    const vulkan_bindings = vulkan_bindgen_run.addOutputFileArg2("vulkan.zig", .{});

    const write_vulkan_bindings_source = b.addUpdateSourceFiles();
    write_vulkan_bindings_source.addCopyFileToSource(vulkan_bindings, "src/module/vulkan.zig");

    const vk_bindgen_step = b.step("gen-vk", "run vulkan-zig-generator to update src/module/vulkan.zig");
    vk_bindgen_step.dependOn(&write_vulkan_bindings_source.step);

    return lib;
}

fn buildGlfw(b: *Build) *Build.Step.Compile {
    const base_sources = [_][]const u8{
        "context.c",
        "egl_context.c",
        "init.c",
        "input.c",
        "monitor.c",
        "null_init.c",
        "null_joystick.c",
        "null_monitor.c",
        "null_window.c",
        "osmesa_context.c",
        "platform.c",
        "vulkan.c",
        "window.c",
    };

    const linux_sources = [_][]const u8{
        "linux_joystick.c",
        "posix_module.c",
        "posix_poll.c",
        "posix_thread.c",
        "posix_time.c",
        "xkb_unicode.c",
    };

    const linux_wl_sources = [_][]const u8{
        "wl_init.c",
        "wl_monitor.c",
        "wl_window.c",
    };

    const linux_x11_sources = [_][]const u8{
        "glx_context.c",
        "x11_init.c",
        "x11_monitor.c",
        "x11_window.c",
    };

    const windows_sources = [_][]const u8{
        "wgl_context.c",
        "win32_init.c",
        "win32_joystick.c",
        "win32_module.c",
        "win32_monitor.c",
        "win32_thread.c",
        "win32_time.c",
        "win32_window.c",
    };

    const glfw_dep = b.dependency("glfw", .{});
    const x11_headers = b.dependency("x11_headers", .{});
    const wayland_headers = b.dependency("wayland_headers", .{});

    const glfw_src = glfw_dep.path("src");
    const glfw_include = glfw_dep.path("include");

    const t = Translator.init(translate_c_dep, .{
        .c_source_file = b.addWriteFiles().add(
            "glfw.c",
            \\#include "GLFW/glfw3.h"
            // \\#include "GLFW/glfw3native.h"
            ,
        ),
        .target = target,
        .optimize = optimize,
    });
    t.defineCMacro("GLFW_INCLUDE_NONE", "");
    // t.defineCMacro("GLFW_INCLUDE_VULKAN", "");
    t.addIncludePath(glfw_include);
    // t.addIncludePath(x11_headers.path("include"));
    // t.addIncludePath(wayland_headers.path("include"));
    // t.addIncludePath(vulkan_headers.path("include"));

    const glfw_bindings = t.output_file;

    const write_glfw_bindings_source = b.addUpdateSourceFiles();
    write_glfw_bindings_source.addCopyFileToSource(glfw_bindings, "src/module/glfw.zig");

    const glfw_bindgen_step = b.step("gen-glfw", "run translate-c to update src/module/glfw.zig");
    glfw_bindgen_step.dependOn(&write_glfw_bindings_source.step);

    const lib = b.addLibrary(.{
        .name = "glfw",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    lib.root_module.addIncludePath(glfw_dep.path("include"));

    lib.root_module.addIncludePath(vulkan_headers.path("include"));

    lib.root_module.addCSourceFiles(.{
        .root = glfw_src,
        .files = &base_sources,
    });

    switch (target.result.os.tag) {
        .windows => {
            lib.root_module.linkSystemLibrary("gdi32", .{});
            lib.root_module.linkSystemLibrary("user32", .{});
            lib.root_module.linkSystemLibrary("shell32", .{});

            lib.root_module.addCMacro("_GLFW_WIN32", "1");
            lib.root_module.addCSourceFiles(.{
                .root = glfw_src,
                .files = &windows_sources,
            });
        },
        else => {
            lib.root_module.addSystemIncludePath(x11_headers.path(""));
            lib.root_module.addSystemIncludePath(wayland_headers.path("wayland"));
            lib.root_module.addSystemIncludePath(wayland_headers.path("wayland-protocols"));

            lib.root_module.addCSourceFiles(.{
                .root = glfw_src,
                .files = &linux_sources,
            });

            lib.root_module.addCMacro("_GLFW_X11", "1");
            lib.root_module.addCSourceFiles(.{
                .root = glfw_src,
                .files = &linux_x11_sources,
            });

            lib.root_module.addCMacro("_GLFW_WAYLAND", "1");

            lib.root_module.addCSourceFiles(.{
                .root = glfw_src,
                .files = &linux_wl_sources,
                .flags = &.{
                    "-Wno-implicit-function-declaration",
                },
            });
        },
    }

    return lib;
}

const runtime_test_src = @import("src/runtime_test.zig");
const Translator = @import("translate_c").Translator;
const base = @import("src/module/base.zig");
const zon = base.zon;
const mem = base.mem;
const meta = base.meta;
const debug = base.debug;
const path = base.path;
const Build = base.Build;
const OptimizeMode = base.zig_builtin.OptimizeMode;
const config = @import("src/config.zig");
const zon_text = @embedFile("build.zig.zon");
