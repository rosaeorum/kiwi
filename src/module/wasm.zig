const __root = @This();
pub const __builtin = @import("c_builtins");
pub const __helpers = @import("helpers");

pub const ptrdiff_t = c_long;
pub const wchar_t = c_int;
pub const max_align_t = extern struct {
    __aro_max_align_ll: c_longlong,
    __aro_max_align_ld: c_longdouble,
};
pub const __u_char = u8;
pub const __u_short = c_ushort;
pub const __u_int = c_uint;
pub const __u_long = c_ulong;
pub const __int8_t = i8;
pub const __uint8_t = u8;
pub const __int16_t = c_short;
pub const __uint16_t = c_ushort;
pub const __int32_t = c_int;
pub const __uint32_t = c_uint;
pub const __int64_t = c_long;
pub const __uint64_t = c_ulong;
pub const __int_least8_t = __int8_t;
pub const __uint_least8_t = __uint8_t;
pub const __int_least16_t = __int16_t;
pub const __uint_least16_t = __uint16_t;
pub const __int_least32_t = __int32_t;
pub const __uint_least32_t = __uint32_t;
pub const __int_least64_t = __int64_t;
pub const __uint_least64_t = __uint64_t;
pub const __quad_t = c_long;
pub const __u_quad_t = c_ulong;
pub const __intmax_t = c_long;
pub const __uintmax_t = c_ulong;
pub const __dev_t = c_ulong;
pub const __uid_t = c_uint;
pub const __gid_t = c_uint;
pub const __ino_t = c_ulong;
pub const __ino64_t = c_ulong;
pub const __mode_t = c_uint;
pub const __nlink_t = c_ulong;
pub const __off_t = c_long;
pub const __off64_t = c_long;
pub const __pid_t = c_int;
pub const __fsid_t = extern struct {
    __val: [2]c_int,
};
pub const __clock_t = c_long;
pub const __rlim_t = c_ulong;
pub const __rlim64_t = c_ulong;
pub const __id_t = c_uint;
pub const __time_t = c_long;
pub const __useconds_t = c_uint;
pub const __suseconds_t = c_long;
pub const __suseconds64_t = c_long;
pub const __daddr_t = c_int;
pub const __key_t = c_int;
pub const __clockid_t = c_int;
pub const __timer_t = ?*anyopaque;
pub const __blksize_t = c_long;
pub const __blkcnt_t = c_long;
pub const __blkcnt64_t = c_long;
pub const __fsblkcnt_t = c_ulong;
pub const __fsblkcnt64_t = c_ulong;
pub const __fsfilcnt_t = c_ulong;
pub const __fsfilcnt64_t = c_ulong;
pub const __fsword_t = c_long;
pub const __ssize_t = c_long;
pub const __syscall_slong_t = c_long;
pub const __syscall_ulong_t = c_ulong;
pub const __loff_t = __off64_t;
pub const __caddr_t = [*c]u8;
pub const __intptr_t = c_long;
pub const __socklen_t = c_uint;
pub const __sig_atomic_t = c_int;
pub const int_least8_t = __int_least8_t;
pub const int_least16_t = __int_least16_t;
pub const int_least32_t = __int_least32_t;
pub const int_least64_t = __int_least64_t;
pub const uint_least8_t = __uint_least8_t;
pub const uint_least16_t = __uint_least16_t;
pub const uint_least32_t = __uint_least32_t;
pub const uint_least64_t = __uint_least64_t;
pub const int_fast8_t = i8;
pub const int_fast16_t = c_long;
pub const int_fast32_t = c_long;
pub const int_fast64_t = c_long;
pub const uint_fast8_t = u8;
pub const uint_fast16_t = c_ulong;
pub const uint_fast32_t = c_ulong;
pub const uint_fast64_t = c_ulong;
pub const intmax_t = __intmax_t;
pub const uintmax_t = __uintmax_t;
pub extern fn memcpy(noalias __dest: ?*anyopaque, noalias __src: ?*const anyopaque, __n: usize) ?*anyopaque;
pub extern fn memmove(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: usize) ?*anyopaque;
pub extern fn memccpy(noalias __dest: ?*anyopaque, noalias __src: ?*const anyopaque, __c: c_int, __n: usize) ?*anyopaque;
pub extern fn memset(__s: ?*anyopaque, __c: c_int, __n: usize) ?*anyopaque;
pub extern fn memset_explicit(__s: ?*anyopaque, __c: c_int, __n: usize) ?*anyopaque;
pub extern fn memcmp(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: usize) c_int;
pub extern fn __memcmpeq(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: usize) c_int;
pub extern fn memchr(__s: ?*const anyopaque, __c: c_int, __n: usize) ?*anyopaque;
pub extern fn strcpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8) [*c]u8;
pub extern fn strncpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) [*c]u8;
pub extern fn strcat(noalias __dest: [*c]u8, noalias __src: [*c]const u8) [*c]u8;
pub extern fn strncat(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) [*c]u8;
pub extern fn strcmp(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strncmp(__s1: [*c]const u8, __s2: [*c]const u8, __n: usize) c_int;
pub extern fn strcoll(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strxfrm(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) usize;
pub const struct___locale_data_1 = opaque {};
pub const struct___locale_struct = extern struct {
    __locales: [13]?*struct___locale_data_1,
    __ctype_b: [*c]const c_ushort,
    __ctype_tolower: [*c]const c_int,
    __ctype_toupper: [*c]const c_int,
    __names: [13][*c]const u8,
};
pub const __locale_t = [*c]struct___locale_struct;
pub const locale_t = __locale_t;
pub extern fn strcoll_l(__s1: [*c]const u8, __s2: [*c]const u8, __l: locale_t) c_int;
pub extern fn strxfrm_l(__dest: [*c]u8, __src: [*c]const u8, __n: usize, __l: locale_t) usize;
pub extern fn strdup(__s: [*c]const u8) [*c]u8;
pub extern fn strndup(__string: [*c]const u8, __n: usize) [*c]u8;
pub extern fn strchr(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn strrchr(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn strchrnul(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn strcspn(__s: [*c]const u8, __reject: [*c]const u8) usize;
pub extern fn strspn(__s: [*c]const u8, __accept: [*c]const u8) usize;
pub extern fn strpbrk(__s: [*c]const u8, __accept: [*c]const u8) [*c]u8;
pub extern fn strstr(__haystack: [*c]const u8, __needle: [*c]const u8) [*c]u8;
pub extern fn strtok(noalias __s: [*c]u8, noalias __delim: [*c]const u8) [*c]u8;
pub extern fn __strtok_r(noalias __s: [*c]u8, noalias __delim: [*c]const u8, noalias __save_ptr: [*c][*c]u8) [*c]u8;
pub extern fn strtok_r(noalias __s: [*c]u8, noalias __delim: [*c]const u8, noalias __save_ptr: [*c][*c]u8) [*c]u8;
pub extern fn strcasestr(__haystack: [*c]const u8, __needle: [*c]const u8) [*c]u8;
pub extern fn memmem(__haystack: ?*const anyopaque, __haystacklen: usize, __needle: ?*const anyopaque, __needlelen: usize) ?*anyopaque;
pub extern fn __mempcpy(noalias __dest: ?*anyopaque, noalias __src: ?*const anyopaque, __n: usize) ?*anyopaque;
pub extern fn mempcpy(noalias __dest: ?*anyopaque, noalias __src: ?*const anyopaque, __n: usize) ?*anyopaque;
pub extern fn strlen(__s: [*c]const u8) usize;
pub extern fn strnlen(__string: [*c]const u8, __maxlen: usize) usize;
pub extern fn strerror(__errnum: c_int) [*c]u8;
pub extern fn strerror_r(__errnum: c_int, __buf: [*c]u8, __buflen: usize) c_int;
pub extern fn strerror_l(__errnum: c_int, __l: locale_t) [*c]u8;
pub extern fn bcmp(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: usize) c_int;
pub extern fn bcopy(__src: ?*const anyopaque, __dest: ?*anyopaque, __n: usize) void;
pub extern fn bzero(__s: ?*anyopaque, __n: usize) void;
pub extern fn index(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn rindex(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn ffs(__i: c_int) c_int;
pub extern fn ffsl(__l: c_long) c_int;
pub extern fn ffsll(__ll: c_longlong) c_int;
pub extern fn strcasecmp(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strncasecmp(__s1: [*c]const u8, __s2: [*c]const u8, __n: usize) c_int;
pub extern fn strcasecmp_l(__s1: [*c]const u8, __s2: [*c]const u8, __loc: locale_t) c_int;
pub extern fn strncasecmp_l(__s1: [*c]const u8, __s2: [*c]const u8, __n: usize, __loc: locale_t) c_int;
pub extern fn explicit_bzero(__s: ?*anyopaque, __n: usize) void;
pub extern fn strsep(noalias __stringp: [*c][*c]u8, noalias __delim: [*c]const u8) [*c]u8;
pub extern fn strsignal(__sig: c_int) [*c]u8;
pub extern fn __stpcpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8) [*c]u8;
pub extern fn stpcpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8) [*c]u8;
pub extern fn __stpncpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) [*c]u8;
pub extern fn stpncpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) [*c]u8;
pub extern fn strlcpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) usize;
pub extern fn strlcat(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) usize;
pub extern fn __assert_fail(__assertion: [*c]const u8, __file: [*c]const u8, __line: c_uint, __function: [*c]const u8) noreturn;
pub extern fn __assert_perror_fail(__errnum: c_int, __file: [*c]const u8, __line: c_uint, __function: [*c]const u8) noreturn;
pub extern fn __assert(__assertion: [*c]const u8, __file: [*c]const u8, __line: c_int) noreturn;
pub fn assertions() callconv(.c) void {
    comptime {
        if (!(@sizeOf(f32) == @sizeOf(u32))) @compileError("static assertion failed \"incompatible float type\"");
    }
    comptime {
        if (!(@sizeOf(f64) == @sizeOf(u64))) @compileError("static assertion failed \"incompatible double type\"");
    }
    comptime {
        if (!((@sizeOf(isize) == @sizeOf(u32)) or (@sizeOf(isize) == @sizeOf(u64)))) @compileError("static assertion failed \"incompatible pointer type\"");
    }
}
pub const byte_t = u8;
pub const float32_t = f32;
pub const float64_t = f64;
pub const wasm_byte_t = byte_t;
pub const struct_wasm_byte_vec_t = extern struct {
    size: usize,
    data: [*c]wasm_byte_t,
    pub const wasm_byte_vec_new_empty = __root.wasm_byte_vec_new_empty;
    pub const wasm_byte_vec_new_uninitialized = __root.wasm_byte_vec_new_uninitialized;
    pub const wasm_byte_vec_new = __root.wasm_byte_vec_new;
    pub const wasm_byte_vec_copy = __root.wasm_byte_vec_copy;
    pub const wasm_byte_vec_delete = __root.wasm_byte_vec_delete;
    pub const wasm_name_new_from_string = __root.wasm_name_new_from_string;
    pub const wasm_name_new_from_string_nt = __root.wasm_name_new_from_string_nt;
    pub const wasm_importtype_new = __root.wasm_importtype_new;
    pub const wasm_exporttype_new = __root.wasm_exporttype_new;
    pub const empty = __root.wasm_byte_vec_new_empty;
    pub const uninitialized = __root.wasm_byte_vec_new_uninitialized;
    pub const new = __root.wasm_byte_vec_new;
    pub const copy = __root.wasm_byte_vec_copy;
    pub const delete = __root.wasm_byte_vec_delete;
    pub const string = __root.wasm_name_new_from_string;
    pub const nt = __root.wasm_name_new_from_string_nt;
};
pub const wasm_byte_vec_t = struct_wasm_byte_vec_t;
pub extern fn wasm_byte_vec_new_empty(out: [*c]wasm_byte_vec_t) void;
pub extern fn wasm_byte_vec_new_uninitialized(out: [*c]wasm_byte_vec_t, usize) void;
pub extern fn wasm_byte_vec_new(out: [*c]wasm_byte_vec_t, usize, [*c]const wasm_byte_t) void;
pub extern fn wasm_byte_vec_copy(out: [*c]wasm_byte_vec_t, [*c]const wasm_byte_vec_t) void;
pub extern fn wasm_byte_vec_delete([*c]wasm_byte_vec_t) void;
pub const wasm_name_t = wasm_byte_vec_t;
pub fn wasm_name_new_from_string(arg_out: [*c]wasm_name_t, arg_s: [*c]const u8) callconv(.c) void {
    var out = arg_out;
    _ = &out;
    var s = arg_s;
    _ = &s;
    wasm_byte_vec_new(out, strlen(s), s);
}
pub fn wasm_name_new_from_string_nt(arg_out: [*c]wasm_name_t, arg_s: [*c]const u8) callconv(.c) void {
    var out = arg_out;
    _ = &out;
    var s = arg_s;
    _ = &s;
    wasm_byte_vec_new(out, strlen(s) +% @as(usize, 1), s);
}
pub const struct_wasm_config_t = opaque {
    pub const wasm_config_delete = __root.wasm_config_delete;
    pub const wasm_engine_new_with_config = __root.wasm_engine_new_with_config;
    pub const wasmtime_config_debug_info_set = __root.wasmtime_config_debug_info_set;
    pub const wasmtime_config_consume_fuel_set = __root.wasmtime_config_consume_fuel_set;
    pub const wasmtime_config_epoch_interruption_set = __root.wasmtime_config_epoch_interruption_set;
    pub const wasmtime_config_max_wasm_stack_set = __root.wasmtime_config_max_wasm_stack_set;
    pub const wasmtime_config_wasm_threads_set = __root.wasmtime_config_wasm_threads_set;
    pub const wasmtime_config_shared_memory_set = __root.wasmtime_config_shared_memory_set;
    pub const wasmtime_config_wasm_tail_call_set = __root.wasmtime_config_wasm_tail_call_set;
    pub const wasmtime_config_wasm_reference_types_set = __root.wasmtime_config_wasm_reference_types_set;
    pub const wasmtime_config_wasm_function_references_set = __root.wasmtime_config_wasm_function_references_set;
    pub const wasmtime_config_wasm_gc_set = __root.wasmtime_config_wasm_gc_set;
    pub const wasmtime_config_gc_support_set = __root.wasmtime_config_gc_support_set;
    pub const wasmtime_config_wasm_simd_set = __root.wasmtime_config_wasm_simd_set;
    pub const wasmtime_config_wasm_relaxed_simd_set = __root.wasmtime_config_wasm_relaxed_simd_set;
    pub const wasmtime_config_wasm_relaxed_simd_deterministic_set = __root.wasmtime_config_wasm_relaxed_simd_deterministic_set;
    pub const wasmtime_config_wasm_bulk_memory_set = __root.wasmtime_config_wasm_bulk_memory_set;
    pub const wasmtime_config_wasm_multi_value_set = __root.wasmtime_config_wasm_multi_value_set;
    pub const wasmtime_config_wasm_multi_memory_set = __root.wasmtime_config_wasm_multi_memory_set;
    pub const wasmtime_config_wasm_memory64_set = __root.wasmtime_config_wasm_memory64_set;
    pub const wasmtime_config_wasm_wide_arithmetic_set = __root.wasmtime_config_wasm_wide_arithmetic_set;
    pub const wasmtime_config_wasm_branch_hinting_set = __root.wasmtime_config_wasm_branch_hinting_set;
    pub const wasmtime_config_wasm_exceptions_set = __root.wasmtime_config_wasm_exceptions_set;
    pub const wasmtime_config_wasm_custom_page_sizes_set = __root.wasmtime_config_wasm_custom_page_sizes_set;
    pub const wasmtime_config_wasm_compact_imports_set = __root.wasmtime_config_wasm_compact_imports_set;
    pub const wasmtime_config_wasm_stack_switching_set = __root.wasmtime_config_wasm_stack_switching_set;
    pub const wasmtime_config_strategy_set = __root.wasmtime_config_strategy_set;
    pub const wasmtime_config_parallel_compilation_set = __root.wasmtime_config_parallel_compilation_set;
    pub const wasmtime_config_cranelift_debug_verifier_set = __root.wasmtime_config_cranelift_debug_verifier_set;
    pub const wasmtime_config_cranelift_nan_canonicalization_set = __root.wasmtime_config_cranelift_nan_canonicalization_set;
    pub const wasmtime_config_cranelift_opt_level_set = __root.wasmtime_config_cranelift_opt_level_set;
    pub const wasmtime_config_cranelift_regalloc_algorithm_set = __root.wasmtime_config_cranelift_regalloc_algorithm_set;
    pub const wasmtime_config_profiler_set = __root.wasmtime_config_profiler_set;
    pub const wasmtime_config_memory_may_move_set = __root.wasmtime_config_memory_may_move_set;
    pub const wasmtime_config_memory_reservation_set = __root.wasmtime_config_memory_reservation_set;
    pub const wasmtime_config_memory_guard_size_set = __root.wasmtime_config_memory_guard_size_set;
    pub const wasmtime_config_memory_reservation_for_growth_set = __root.wasmtime_config_memory_reservation_for_growth_set;
    pub const wasmtime_config_native_unwind_info_set = __root.wasmtime_config_native_unwind_info_set;
    pub const wasmtime_config_cache_config_load = __root.wasmtime_config_cache_config_load;
    pub const wasmtime_config_target_set = __root.wasmtime_config_target_set;
    pub const wasmtime_config_cranelift_flag_enable = __root.wasmtime_config_cranelift_flag_enable;
    pub const wasmtime_config_cranelift_flag_set = __root.wasmtime_config_cranelift_flag_set;
    pub const wasmtime_config_macos_use_mach_ports_set = __root.wasmtime_config_macos_use_mach_ports_set;
    pub const wasmtime_config_signals_based_traps_set = __root.wasmtime_config_signals_based_traps_set;
    pub const wasmtime_config_host_memory_creator_set = __root.wasmtime_config_host_memory_creator_set;
    pub const wasmtime_config_memory_init_cow_set = __root.wasmtime_config_memory_init_cow_set;
    pub const wasmtime_pooling_allocation_strategy_set = __root.wasmtime_pooling_allocation_strategy_set;
    pub const wasmtime_config_wasm_component_model_set = __root.wasmtime_config_wasm_component_model_set;
    pub const wasmtime_config_concurrency_support_set = __root.wasmtime_config_concurrency_support_set;
    pub const wasmtime_config_wasm_component_model_map_set = __root.wasmtime_config_wasm_component_model_map_set;
    pub const wasmtime_config_wasm_component_model_implements_set = __root.wasmtime_config_wasm_component_model_implements_set;
    pub const wasmtime_config_wasm_component_model_canonical_names_set = __root.wasmtime_config_wasm_component_model_canonical_names_set;
    pub const wasmtime_config_wasm_component_model_accessors_set = __root.wasmtime_config_wasm_component_model_accessors_set;
    pub const wasmtime_config_wasm_component_model_async_set = __root.wasmtime_config_wasm_component_model_async_set;
    pub const wasmtime_config_wasm_component_model_more_async_builtins_set = __root.wasmtime_config_wasm_component_model_more_async_builtins_set;
    pub const wasmtime_config_wasm_component_model_async_stackful_set = __root.wasmtime_config_wasm_component_model_async_stackful_set;
    pub const wasmtime_config_async_stack_size_set = __root.wasmtime_config_async_stack_size_set;
    pub const wasmtime_config_host_stack_creator_set = __root.wasmtime_config_host_stack_creator_set;
    pub const delete = __root.wasm_config_delete;
    pub const config = __root.wasm_engine_new_with_config;
    pub const set = __root.wasmtime_config_debug_info_set;
    pub const load = __root.wasmtime_config_cache_config_load;
    pub const enable = __root.wasmtime_config_cranelift_flag_enable;
};
pub const wasm_config_t = struct_wasm_config_t;
pub extern fn wasm_config_delete(?*wasm_config_t) void;
pub extern fn wasm_config_new() ?*wasm_config_t;
pub const struct_wasm_engine_t = opaque {
    pub const wasm_engine_delete = __root.wasm_engine_delete;
    pub const wasm_store_new = __root.wasm_store_new;
    pub const wasmtime_struct_type_new = __root.wasmtime_struct_type_new;
    pub const wasmtime_array_type_new = __root.wasmtime_array_type_new;
    pub const wasmtime_exn_type_new = __root.wasmtime_exn_type_new;
    pub const wasmtime_valtype_to_wasm = __root.wasmtime_valtype_to_wasm;
    pub const wasmtime_module_new = __root.wasmtime_module_new;
    pub const wasmtime_module_validate = __root.wasmtime_module_validate;
    pub const wasmtime_module_deserialize = __root.wasmtime_module_deserialize;
    pub const wasmtime_module_deserialize_file = __root.wasmtime_module_deserialize_file;
    pub const wasmtime_sharedmemory_new = __root.wasmtime_sharedmemory_new;
    pub const wasmtime_store_new = __root.wasmtime_store_new;
    pub const wasmtime_linker_new = __root.wasmtime_linker_new;
    pub const wasmtime_component_new = __root.wasmtime_component_new;
    pub const wasmtime_component_deserialize = __root.wasmtime_component_deserialize;
    pub const wasmtime_component_deserialize_file = __root.wasmtime_component_deserialize_file;
    pub const wasmtime_component_linker_new = __root.wasmtime_component_linker_new;
    pub const wasmtime_engine_clone = __root.wasmtime_engine_clone;
    pub const wasmtime_engine_increment_epoch = __root.wasmtime_engine_increment_epoch;
    pub const wasmtime_engine_is_pulley = __root.wasmtime_engine_is_pulley;
    pub const wasmtime_guestprofiler_new = __root.wasmtime_guestprofiler_new;
    pub const delete = __root.wasm_engine_delete;
    pub const new = __root.wasm_store_new;
    pub const wasm = __root.wasmtime_valtype_to_wasm;
    pub const validate = __root.wasmtime_module_validate;
    pub const deserialize = __root.wasmtime_module_deserialize;
    pub const file = __root.wasmtime_module_deserialize_file;
    pub const clone = __root.wasmtime_engine_clone;
    pub const epoch = __root.wasmtime_engine_increment_epoch;
    pub const pulley = __root.wasmtime_engine_is_pulley;
};
pub const wasm_engine_t = struct_wasm_engine_t;
pub extern fn wasm_engine_delete(?*wasm_engine_t) void;
pub extern fn wasm_engine_new() ?*wasm_engine_t;
pub extern fn wasm_engine_new_with_config(?*wasm_config_t) ?*wasm_engine_t;
pub const struct_wasm_store_t = opaque {
    pub const wasm_store_delete = __root.wasm_store_delete;
    pub const wasm_trap_new = __root.wasm_trap_new;
    pub const wasm_foreign_new = __root.wasm_foreign_new;
    pub const wasm_module_obtain = __root.wasm_module_obtain;
    pub const wasm_module_new = __root.wasm_module_new;
    pub const wasm_module_validate = __root.wasm_module_validate;
    pub const wasm_module_deserialize = __root.wasm_module_deserialize;
    pub const wasm_func_new = __root.wasm_func_new;
    pub const wasm_func_new_with_env = __root.wasm_func_new_with_env;
    pub const wasm_global_new = __root.wasm_global_new;
    pub const wasm_table_new = __root.wasm_table_new;
    pub const wasm_memory_new = __root.wasm_memory_new;
    pub const wasm_instance_new = __root.wasm_instance_new;
    pub const delete = __root.wasm_store_delete;
    pub const new = __root.wasm_trap_new;
    pub const obtain = __root.wasm_module_obtain;
    pub const validate = __root.wasm_module_validate;
    pub const deserialize = __root.wasm_module_deserialize;
    pub const env = __root.wasm_func_new_with_env;
};
pub const wasm_store_t = struct_wasm_store_t;
pub extern fn wasm_store_delete(?*wasm_store_t) void;
pub extern fn wasm_store_new(?*wasm_engine_t) ?*wasm_store_t;
pub const wasm_mutability_t = u8;
pub const WASM_CONST: c_int = 0;
pub const WASM_VAR: c_int = 1;
pub const enum_wasm_mutability_enum = c_uint;
pub const struct_wasm_limits_t = extern struct {
    min: u32,
    max: u32,
    pub const wasm_memorytype_new = __root.wasm_memorytype_new;
    pub const new = __root.wasm_memorytype_new;
};
pub const wasm_limits_t = struct_wasm_limits_t;
pub const wasm_limits_max_default: u32 = 4294967295;
pub const struct_wasm_valtype_t = opaque {
    pub const wasm_valtype_delete = __root.wasm_valtype_delete;
    pub const wasm_valtype_copy = __root.wasm_valtype_copy;
    pub const wasm_valtype_kind = __root.wasm_valtype_kind;
    pub const wasm_valtype_is_num = __root.wasm_valtype_is_num;
    pub const wasm_valtype_is_ref = __root.wasm_valtype_is_ref;
    pub const wasm_globaltype_new = __root.wasm_globaltype_new;
    pub const wasm_tabletype_new = __root.wasm_tabletype_new;
    pub const wasm_functype_new_1_0 = __root.wasm_functype_new_1_0;
    pub const wasm_functype_new_2_0 = __root.wasm_functype_new_2_0;
    pub const wasm_functype_new_3_0 = __root.wasm_functype_new_3_0;
    pub const wasm_functype_new_0_1 = __root.wasm_functype_new_0_1;
    pub const wasm_functype_new_1_1 = __root.wasm_functype_new_1_1;
    pub const wasm_functype_new_2_1 = __root.wasm_functype_new_2_1;
    pub const wasm_functype_new_3_1 = __root.wasm_functype_new_3_1;
    pub const wasm_functype_new_0_2 = __root.wasm_functype_new_0_2;
    pub const wasm_functype_new_1_2 = __root.wasm_functype_new_1_2;
    pub const wasm_functype_new_2_2 = __root.wasm_functype_new_2_2;
    pub const wasm_functype_new_3_2 = __root.wasm_functype_new_3_2;
    pub const wasmtime_wasm_valtype_equal = __root.wasmtime_wasm_valtype_equal;
    pub const wasmtime_valtype_new = __root.wasmtime_valtype_new;
    pub const delete = __root.wasm_valtype_delete;
    pub const copy = __root.wasm_valtype_copy;
    pub const kind = __root.wasm_valtype_kind;
    pub const num = __root.wasm_valtype_is_num;
    pub const ref = __root.wasm_valtype_is_ref;
    pub const new = __root.wasm_globaltype_new;
    pub const @"0" = __root.wasm_functype_new_1_0;
    pub const @"1" = __root.wasm_functype_new_0_1;
    pub const @"2" = __root.wasm_functype_new_0_2;
    pub const equal = __root.wasmtime_wasm_valtype_equal;
};
pub const wasm_valtype_t = struct_wasm_valtype_t;
pub extern fn wasm_valtype_delete(?*wasm_valtype_t) void;
pub const struct_wasm_valtype_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_valtype_t,
    pub const wasm_valtype_vec_new_empty = __root.wasm_valtype_vec_new_empty;
    pub const wasm_valtype_vec_new_uninitialized = __root.wasm_valtype_vec_new_uninitialized;
    pub const wasm_valtype_vec_new = __root.wasm_valtype_vec_new;
    pub const wasm_valtype_vec_copy = __root.wasm_valtype_vec_copy;
    pub const wasm_valtype_vec_delete = __root.wasm_valtype_vec_delete;
    pub const wasm_functype_new = __root.wasm_functype_new;
    pub const empty = __root.wasm_valtype_vec_new_empty;
    pub const uninitialized = __root.wasm_valtype_vec_new_uninitialized;
    pub const new = __root.wasm_valtype_vec_new;
    pub const copy = __root.wasm_valtype_vec_copy;
    pub const delete = __root.wasm_valtype_vec_delete;
};
pub const wasm_valtype_vec_t = struct_wasm_valtype_vec_t;
pub extern fn wasm_valtype_vec_new_empty(out: [*c]wasm_valtype_vec_t) void;
pub extern fn wasm_valtype_vec_new_uninitialized(out: [*c]wasm_valtype_vec_t, usize) void;
pub extern fn wasm_valtype_vec_new(out: [*c]wasm_valtype_vec_t, usize, [*c]const ?*wasm_valtype_t) void;
pub extern fn wasm_valtype_vec_copy(out: [*c]wasm_valtype_vec_t, [*c]const wasm_valtype_vec_t) void;
pub extern fn wasm_valtype_vec_delete([*c]wasm_valtype_vec_t) void;
pub extern fn wasm_valtype_copy(?*const wasm_valtype_t) ?*wasm_valtype_t;
pub const wasm_valkind_t = u8;
pub const WASM_I32: c_int = 0;
pub const WASM_I64: c_int = 1;
pub const WASM_F32: c_int = 2;
pub const WASM_F64: c_int = 3;
pub const WASM_EXTERNREF: c_int = 128;
pub const WASM_FUNCREF: c_int = 129;
pub const enum_wasm_valkind_enum = c_uint;
pub extern fn wasm_valtype_new(wasm_valkind_t) ?*wasm_valtype_t;
pub extern fn wasm_valtype_kind(?*const wasm_valtype_t) wasm_valkind_t;
pub fn wasm_valkind_is_num(arg_k: wasm_valkind_t) callconv(.c) bool {
    var k = arg_k;
    _ = &k;
    return @as(c_int, k) < WASM_EXTERNREF;
}
pub fn wasm_valkind_is_ref(arg_k: wasm_valkind_t) callconv(.c) bool {
    var k = arg_k;
    _ = &k;
    return @as(c_int, k) >= WASM_EXTERNREF;
}
pub fn wasm_valtype_is_num(arg_t: ?*const wasm_valtype_t) callconv(.c) bool {
    var t = arg_t;
    _ = &t;
    return wasm_valkind_is_num(wasm_valtype_kind(t));
}
pub fn wasm_valtype_is_ref(arg_t: ?*const wasm_valtype_t) callconv(.c) bool {
    var t = arg_t;
    _ = &t;
    return wasm_valkind_is_ref(wasm_valtype_kind(t));
}
pub const struct_wasm_functype_t = opaque {
    pub const wasm_functype_delete = __root.wasm_functype_delete;
    pub const wasm_functype_copy = __root.wasm_functype_copy;
    pub const wasm_functype_params = __root.wasm_functype_params;
    pub const wasm_functype_results = __root.wasm_functype_results;
    pub const wasm_tagtype_new = __root.wasm_tagtype_new;
    pub const wasm_functype_as_externtype = __root.wasm_functype_as_externtype;
    pub const wasm_functype_as_externtype_const = __root.wasm_functype_as_externtype_const;
    pub const delete = __root.wasm_functype_delete;
    pub const copy = __root.wasm_functype_copy;
    pub const params = __root.wasm_functype_params;
    pub const results = __root.wasm_functype_results;
    pub const new = __root.wasm_tagtype_new;
    pub const externtype = __root.wasm_functype_as_externtype;
    pub const @"const" = __root.wasm_functype_as_externtype_const;
};
pub const wasm_functype_t = struct_wasm_functype_t;
pub extern fn wasm_functype_delete(?*wasm_functype_t) void;
pub const struct_wasm_functype_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_functype_t,
    pub const wasm_functype_vec_new_empty = __root.wasm_functype_vec_new_empty;
    pub const wasm_functype_vec_new_uninitialized = __root.wasm_functype_vec_new_uninitialized;
    pub const wasm_functype_vec_new = __root.wasm_functype_vec_new;
    pub const wasm_functype_vec_copy = __root.wasm_functype_vec_copy;
    pub const wasm_functype_vec_delete = __root.wasm_functype_vec_delete;
    pub const empty = __root.wasm_functype_vec_new_empty;
    pub const uninitialized = __root.wasm_functype_vec_new_uninitialized;
    pub const new = __root.wasm_functype_vec_new;
    pub const copy = __root.wasm_functype_vec_copy;
    pub const delete = __root.wasm_functype_vec_delete;
};
pub const wasm_functype_vec_t = struct_wasm_functype_vec_t;
pub extern fn wasm_functype_vec_new_empty(out: [*c]wasm_functype_vec_t) void;
pub extern fn wasm_functype_vec_new_uninitialized(out: [*c]wasm_functype_vec_t, usize) void;
pub extern fn wasm_functype_vec_new(out: [*c]wasm_functype_vec_t, usize, [*c]const ?*wasm_functype_t) void;
pub extern fn wasm_functype_vec_copy(out: [*c]wasm_functype_vec_t, [*c]const wasm_functype_vec_t) void;
pub extern fn wasm_functype_vec_delete([*c]wasm_functype_vec_t) void;
pub extern fn wasm_functype_copy(?*const wasm_functype_t) ?*wasm_functype_t;
pub extern fn wasm_functype_new(params: [*c]wasm_valtype_vec_t, results: [*c]wasm_valtype_vec_t) ?*wasm_functype_t;
pub extern fn wasm_functype_params(?*const wasm_functype_t) [*c]const wasm_valtype_vec_t;
pub extern fn wasm_functype_results(?*const wasm_functype_t) [*c]const wasm_valtype_vec_t;
pub const struct_wasm_globaltype_t = opaque {
    pub const wasm_globaltype_delete = __root.wasm_globaltype_delete;
    pub const wasm_globaltype_copy = __root.wasm_globaltype_copy;
    pub const wasm_globaltype_content = __root.wasm_globaltype_content;
    pub const wasm_globaltype_mutability = __root.wasm_globaltype_mutability;
    pub const wasm_globaltype_as_externtype = __root.wasm_globaltype_as_externtype;
    pub const wasm_globaltype_as_externtype_const = __root.wasm_globaltype_as_externtype_const;
    pub const delete = __root.wasm_globaltype_delete;
    pub const copy = __root.wasm_globaltype_copy;
    pub const content = __root.wasm_globaltype_content;
    pub const mutability = __root.wasm_globaltype_mutability;
    pub const externtype = __root.wasm_globaltype_as_externtype;
    pub const @"const" = __root.wasm_globaltype_as_externtype_const;
};
pub const wasm_globaltype_t = struct_wasm_globaltype_t;
pub extern fn wasm_globaltype_delete(?*wasm_globaltype_t) void;
pub const struct_wasm_globaltype_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_globaltype_t,
    pub const wasm_globaltype_vec_new_empty = __root.wasm_globaltype_vec_new_empty;
    pub const wasm_globaltype_vec_new_uninitialized = __root.wasm_globaltype_vec_new_uninitialized;
    pub const wasm_globaltype_vec_new = __root.wasm_globaltype_vec_new;
    pub const wasm_globaltype_vec_copy = __root.wasm_globaltype_vec_copy;
    pub const wasm_globaltype_vec_delete = __root.wasm_globaltype_vec_delete;
    pub const empty = __root.wasm_globaltype_vec_new_empty;
    pub const uninitialized = __root.wasm_globaltype_vec_new_uninitialized;
    pub const new = __root.wasm_globaltype_vec_new;
    pub const copy = __root.wasm_globaltype_vec_copy;
    pub const delete = __root.wasm_globaltype_vec_delete;
};
pub const wasm_globaltype_vec_t = struct_wasm_globaltype_vec_t;
pub extern fn wasm_globaltype_vec_new_empty(out: [*c]wasm_globaltype_vec_t) void;
pub extern fn wasm_globaltype_vec_new_uninitialized(out: [*c]wasm_globaltype_vec_t, usize) void;
pub extern fn wasm_globaltype_vec_new(out: [*c]wasm_globaltype_vec_t, usize, [*c]const ?*wasm_globaltype_t) void;
pub extern fn wasm_globaltype_vec_copy(out: [*c]wasm_globaltype_vec_t, [*c]const wasm_globaltype_vec_t) void;
pub extern fn wasm_globaltype_vec_delete([*c]wasm_globaltype_vec_t) void;
pub extern fn wasm_globaltype_copy(?*const wasm_globaltype_t) ?*wasm_globaltype_t;
pub extern fn wasm_globaltype_new(?*wasm_valtype_t, wasm_mutability_t) ?*wasm_globaltype_t;
pub extern fn wasm_globaltype_content(?*const wasm_globaltype_t) ?*const wasm_valtype_t;
pub extern fn wasm_globaltype_mutability(?*const wasm_globaltype_t) wasm_mutability_t;
pub const struct_wasm_tabletype_t = opaque {
    pub const wasm_tabletype_delete = __root.wasm_tabletype_delete;
    pub const wasm_tabletype_copy = __root.wasm_tabletype_copy;
    pub const wasm_tabletype_element = __root.wasm_tabletype_element;
    pub const wasm_tabletype_limits = __root.wasm_tabletype_limits;
    pub const wasm_tabletype_as_externtype = __root.wasm_tabletype_as_externtype;
    pub const wasm_tabletype_as_externtype_const = __root.wasm_tabletype_as_externtype_const;
    pub const delete = __root.wasm_tabletype_delete;
    pub const copy = __root.wasm_tabletype_copy;
    pub const element = __root.wasm_tabletype_element;
    pub const limits = __root.wasm_tabletype_limits;
    pub const externtype = __root.wasm_tabletype_as_externtype;
    pub const @"const" = __root.wasm_tabletype_as_externtype_const;
};
pub const wasm_tabletype_t = struct_wasm_tabletype_t;
pub extern fn wasm_tabletype_delete(?*wasm_tabletype_t) void;
pub const struct_wasm_tabletype_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_tabletype_t,
    pub const wasm_tabletype_vec_new_empty = __root.wasm_tabletype_vec_new_empty;
    pub const wasm_tabletype_vec_new_uninitialized = __root.wasm_tabletype_vec_new_uninitialized;
    pub const wasm_tabletype_vec_new = __root.wasm_tabletype_vec_new;
    pub const wasm_tabletype_vec_copy = __root.wasm_tabletype_vec_copy;
    pub const wasm_tabletype_vec_delete = __root.wasm_tabletype_vec_delete;
    pub const empty = __root.wasm_tabletype_vec_new_empty;
    pub const uninitialized = __root.wasm_tabletype_vec_new_uninitialized;
    pub const new = __root.wasm_tabletype_vec_new;
    pub const copy = __root.wasm_tabletype_vec_copy;
    pub const delete = __root.wasm_tabletype_vec_delete;
};
pub const wasm_tabletype_vec_t = struct_wasm_tabletype_vec_t;
pub extern fn wasm_tabletype_vec_new_empty(out: [*c]wasm_tabletype_vec_t) void;
pub extern fn wasm_tabletype_vec_new_uninitialized(out: [*c]wasm_tabletype_vec_t, usize) void;
pub extern fn wasm_tabletype_vec_new(out: [*c]wasm_tabletype_vec_t, usize, [*c]const ?*wasm_tabletype_t) void;
pub extern fn wasm_tabletype_vec_copy(out: [*c]wasm_tabletype_vec_t, [*c]const wasm_tabletype_vec_t) void;
pub extern fn wasm_tabletype_vec_delete([*c]wasm_tabletype_vec_t) void;
pub extern fn wasm_tabletype_copy(?*const wasm_tabletype_t) ?*wasm_tabletype_t;
pub extern fn wasm_tabletype_new(?*wasm_valtype_t, [*c]const wasm_limits_t) ?*wasm_tabletype_t;
pub extern fn wasm_tabletype_element(?*const wasm_tabletype_t) ?*const wasm_valtype_t;
pub extern fn wasm_tabletype_limits(?*const wasm_tabletype_t) [*c]const wasm_limits_t;
pub const struct_wasm_memorytype_t = opaque {
    pub const wasm_memorytype_delete = __root.wasm_memorytype_delete;
    pub const wasm_memorytype_copy = __root.wasm_memorytype_copy;
    pub const wasm_memorytype_limits = __root.wasm_memorytype_limits;
    pub const wasm_memorytype_as_externtype = __root.wasm_memorytype_as_externtype;
    pub const wasm_memorytype_as_externtype_const = __root.wasm_memorytype_as_externtype_const;
    pub const wasmtime_memorytype_minimum = __root.wasmtime_memorytype_minimum;
    pub const wasmtime_memorytype_maximum = __root.wasmtime_memorytype_maximum;
    pub const wasmtime_memorytype_is64 = __root.wasmtime_memorytype_is64;
    pub const wasmtime_memorytype_isshared = __root.wasmtime_memorytype_isshared;
    pub const wasmtime_memorytype_page_size = __root.wasmtime_memorytype_page_size;
    pub const wasmtime_memorytype_page_size_log2 = __root.wasmtime_memorytype_page_size_log2;
    pub const delete = __root.wasm_memorytype_delete;
    pub const copy = __root.wasm_memorytype_copy;
    pub const limits = __root.wasm_memorytype_limits;
    pub const externtype = __root.wasm_memorytype_as_externtype;
    pub const @"const" = __root.wasm_memorytype_as_externtype_const;
    pub const minimum = __root.wasmtime_memorytype_minimum;
    pub const maximum = __root.wasmtime_memorytype_maximum;
    pub const is64 = __root.wasmtime_memorytype_is64;
    pub const isshared = __root.wasmtime_memorytype_isshared;
    pub const size = __root.wasmtime_memorytype_page_size;
    pub const log2 = __root.wasmtime_memorytype_page_size_log2;
};
pub const wasm_memorytype_t = struct_wasm_memorytype_t;
pub extern fn wasm_memorytype_delete(?*wasm_memorytype_t) void;
pub const struct_wasm_memorytype_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_memorytype_t,
    pub const wasm_memorytype_vec_new_empty = __root.wasm_memorytype_vec_new_empty;
    pub const wasm_memorytype_vec_new_uninitialized = __root.wasm_memorytype_vec_new_uninitialized;
    pub const wasm_memorytype_vec_new = __root.wasm_memorytype_vec_new;
    pub const wasm_memorytype_vec_copy = __root.wasm_memorytype_vec_copy;
    pub const wasm_memorytype_vec_delete = __root.wasm_memorytype_vec_delete;
    pub const empty = __root.wasm_memorytype_vec_new_empty;
    pub const uninitialized = __root.wasm_memorytype_vec_new_uninitialized;
    pub const new = __root.wasm_memorytype_vec_new;
    pub const copy = __root.wasm_memorytype_vec_copy;
    pub const delete = __root.wasm_memorytype_vec_delete;
};
pub const wasm_memorytype_vec_t = struct_wasm_memorytype_vec_t;
pub extern fn wasm_memorytype_vec_new_empty(out: [*c]wasm_memorytype_vec_t) void;
pub extern fn wasm_memorytype_vec_new_uninitialized(out: [*c]wasm_memorytype_vec_t, usize) void;
pub extern fn wasm_memorytype_vec_new(out: [*c]wasm_memorytype_vec_t, usize, [*c]const ?*wasm_memorytype_t) void;
pub extern fn wasm_memorytype_vec_copy(out: [*c]wasm_memorytype_vec_t, [*c]const wasm_memorytype_vec_t) void;
pub extern fn wasm_memorytype_vec_delete([*c]wasm_memorytype_vec_t) void;
pub extern fn wasm_memorytype_copy(?*const wasm_memorytype_t) ?*wasm_memorytype_t;
pub extern fn wasm_memorytype_new([*c]const wasm_limits_t) ?*wasm_memorytype_t;
pub extern fn wasm_memorytype_limits(?*const wasm_memorytype_t) [*c]const wasm_limits_t;
pub const struct_wasm_tagtype_t = opaque {
    pub const wasm_tagtype_delete = __root.wasm_tagtype_delete;
    pub const wasm_tagtype_copy = __root.wasm_tagtype_copy;
    pub const wasm_tagtype_functype = __root.wasm_tagtype_functype;
    pub const wasm_tagtype_as_externtype = __root.wasm_tagtype_as_externtype;
    pub const wasm_tagtype_as_externtype_const = __root.wasm_tagtype_as_externtype_const;
    pub const delete = __root.wasm_tagtype_delete;
    pub const copy = __root.wasm_tagtype_copy;
    pub const functype = __root.wasm_tagtype_functype;
    pub const externtype = __root.wasm_tagtype_as_externtype;
    pub const @"const" = __root.wasm_tagtype_as_externtype_const;
};
pub const wasm_tagtype_t = struct_wasm_tagtype_t;
pub extern fn wasm_tagtype_delete(?*wasm_tagtype_t) void;
pub const struct_wasm_tagtype_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_tagtype_t,
    pub const wasm_tagtype_vec_new_empty = __root.wasm_tagtype_vec_new_empty;
    pub const wasm_tagtype_vec_new_uninitialized = __root.wasm_tagtype_vec_new_uninitialized;
    pub const wasm_tagtype_vec_new = __root.wasm_tagtype_vec_new;
    pub const wasm_tagtype_vec_copy = __root.wasm_tagtype_vec_copy;
    pub const wasm_tagtype_vec_delete = __root.wasm_tagtype_vec_delete;
    pub const empty = __root.wasm_tagtype_vec_new_empty;
    pub const uninitialized = __root.wasm_tagtype_vec_new_uninitialized;
    pub const new = __root.wasm_tagtype_vec_new;
    pub const copy = __root.wasm_tagtype_vec_copy;
    pub const delete = __root.wasm_tagtype_vec_delete;
};
pub const wasm_tagtype_vec_t = struct_wasm_tagtype_vec_t;
pub extern fn wasm_tagtype_vec_new_empty(out: [*c]wasm_tagtype_vec_t) void;
pub extern fn wasm_tagtype_vec_new_uninitialized(out: [*c]wasm_tagtype_vec_t, usize) void;
pub extern fn wasm_tagtype_vec_new(out: [*c]wasm_tagtype_vec_t, usize, [*c]const ?*wasm_tagtype_t) void;
pub extern fn wasm_tagtype_vec_copy(out: [*c]wasm_tagtype_vec_t, [*c]const wasm_tagtype_vec_t) void;
pub extern fn wasm_tagtype_vec_delete([*c]wasm_tagtype_vec_t) void;
pub extern fn wasm_tagtype_copy(?*const wasm_tagtype_t) ?*wasm_tagtype_t;
pub extern fn wasm_tagtype_new(?*wasm_functype_t) ?*wasm_tagtype_t;
pub extern fn wasm_tagtype_functype(?*const wasm_tagtype_t) ?*const wasm_functype_t;
pub const struct_wasm_externtype_t = opaque {
    pub const wasm_externtype_delete = __root.wasm_externtype_delete;
    pub const wasm_externtype_copy = __root.wasm_externtype_copy;
    pub const wasm_externtype_kind = __root.wasm_externtype_kind;
    pub const wasm_externtype_as_functype = __root.wasm_externtype_as_functype;
    pub const wasm_externtype_as_globaltype = __root.wasm_externtype_as_globaltype;
    pub const wasm_externtype_as_tabletype = __root.wasm_externtype_as_tabletype;
    pub const wasm_externtype_as_memorytype = __root.wasm_externtype_as_memorytype;
    pub const wasm_externtype_as_tagtype = __root.wasm_externtype_as_tagtype;
    pub const wasm_externtype_as_functype_const = __root.wasm_externtype_as_functype_const;
    pub const wasm_externtype_as_globaltype_const = __root.wasm_externtype_as_globaltype_const;
    pub const wasm_externtype_as_tabletype_const = __root.wasm_externtype_as_tabletype_const;
    pub const wasm_externtype_as_memorytype_const = __root.wasm_externtype_as_memorytype_const;
    pub const wasm_externtype_as_tagtype_const = __root.wasm_externtype_as_tagtype_const;
    pub const delete = __root.wasm_externtype_delete;
    pub const copy = __root.wasm_externtype_copy;
    pub const kind = __root.wasm_externtype_kind;
    pub const functype = __root.wasm_externtype_as_functype;
    pub const globaltype = __root.wasm_externtype_as_globaltype;
    pub const tabletype = __root.wasm_externtype_as_tabletype;
    pub const memorytype = __root.wasm_externtype_as_memorytype;
    pub const tagtype = __root.wasm_externtype_as_tagtype;
    pub const @"const" = __root.wasm_externtype_as_functype_const;
};
pub const wasm_externtype_t = struct_wasm_externtype_t;
pub extern fn wasm_externtype_delete(?*wasm_externtype_t) void;
pub const struct_wasm_externtype_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_externtype_t,
    pub const wasm_externtype_vec_new_empty = __root.wasm_externtype_vec_new_empty;
    pub const wasm_externtype_vec_new_uninitialized = __root.wasm_externtype_vec_new_uninitialized;
    pub const wasm_externtype_vec_new = __root.wasm_externtype_vec_new;
    pub const wasm_externtype_vec_copy = __root.wasm_externtype_vec_copy;
    pub const wasm_externtype_vec_delete = __root.wasm_externtype_vec_delete;
    pub const empty = __root.wasm_externtype_vec_new_empty;
    pub const uninitialized = __root.wasm_externtype_vec_new_uninitialized;
    pub const new = __root.wasm_externtype_vec_new;
    pub const copy = __root.wasm_externtype_vec_copy;
    pub const delete = __root.wasm_externtype_vec_delete;
};
pub const wasm_externtype_vec_t = struct_wasm_externtype_vec_t;
pub extern fn wasm_externtype_vec_new_empty(out: [*c]wasm_externtype_vec_t) void;
pub extern fn wasm_externtype_vec_new_uninitialized(out: [*c]wasm_externtype_vec_t, usize) void;
pub extern fn wasm_externtype_vec_new(out: [*c]wasm_externtype_vec_t, usize, [*c]const ?*wasm_externtype_t) void;
pub extern fn wasm_externtype_vec_copy(out: [*c]wasm_externtype_vec_t, [*c]const wasm_externtype_vec_t) void;
pub extern fn wasm_externtype_vec_delete([*c]wasm_externtype_vec_t) void;
pub extern fn wasm_externtype_copy(?*const wasm_externtype_t) ?*wasm_externtype_t;
pub const wasm_externkind_t = u8;
pub const WASM_EXTERN_FUNC: c_int = 0;
pub const WASM_EXTERN_GLOBAL: c_int = 1;
pub const WASM_EXTERN_TABLE: c_int = 2;
pub const WASM_EXTERN_MEMORY: c_int = 3;
pub const WASM_EXTERN_TAG: c_int = 4;
pub const enum_wasm_externkind_enum = c_uint;
pub extern fn wasm_externtype_kind(?*const wasm_externtype_t) wasm_externkind_t;
pub extern fn wasm_functype_as_externtype(?*wasm_functype_t) ?*wasm_externtype_t;
pub extern fn wasm_globaltype_as_externtype(?*wasm_globaltype_t) ?*wasm_externtype_t;
pub extern fn wasm_tabletype_as_externtype(?*wasm_tabletype_t) ?*wasm_externtype_t;
pub extern fn wasm_memorytype_as_externtype(?*wasm_memorytype_t) ?*wasm_externtype_t;
pub extern fn wasm_tagtype_as_externtype(?*wasm_tagtype_t) ?*wasm_externtype_t;
pub extern fn wasm_externtype_as_functype(?*wasm_externtype_t) ?*wasm_functype_t;
pub extern fn wasm_externtype_as_globaltype(?*wasm_externtype_t) ?*wasm_globaltype_t;
pub extern fn wasm_externtype_as_tabletype(?*wasm_externtype_t) ?*wasm_tabletype_t;
pub extern fn wasm_externtype_as_memorytype(?*wasm_externtype_t) ?*wasm_memorytype_t;
pub extern fn wasm_externtype_as_tagtype(?*wasm_externtype_t) ?*wasm_tagtype_t;
pub extern fn wasm_functype_as_externtype_const(?*const wasm_functype_t) ?*const wasm_externtype_t;
pub extern fn wasm_globaltype_as_externtype_const(?*const wasm_globaltype_t) ?*const wasm_externtype_t;
pub extern fn wasm_tabletype_as_externtype_const(?*const wasm_tabletype_t) ?*const wasm_externtype_t;
pub extern fn wasm_memorytype_as_externtype_const(?*const wasm_memorytype_t) ?*const wasm_externtype_t;
pub extern fn wasm_tagtype_as_externtype_const(?*const wasm_tagtype_t) ?*const wasm_externtype_t;
pub extern fn wasm_externtype_as_functype_const(?*const wasm_externtype_t) ?*const wasm_functype_t;
pub extern fn wasm_externtype_as_globaltype_const(?*const wasm_externtype_t) ?*const wasm_globaltype_t;
pub extern fn wasm_externtype_as_tabletype_const(?*const wasm_externtype_t) ?*const wasm_tabletype_t;
pub extern fn wasm_externtype_as_memorytype_const(?*const wasm_externtype_t) ?*const wasm_memorytype_t;
pub extern fn wasm_externtype_as_tagtype_const(?*const wasm_externtype_t) ?*const wasm_tagtype_t;
pub const struct_wasm_importtype_t = opaque {
    pub const wasm_importtype_delete = __root.wasm_importtype_delete;
    pub const wasm_importtype_copy = __root.wasm_importtype_copy;
    pub const wasm_importtype_module = __root.wasm_importtype_module;
    pub const wasm_importtype_name = __root.wasm_importtype_name;
    pub const wasm_importtype_type = __root.wasm_importtype_type;
    pub const delete = __root.wasm_importtype_delete;
    pub const copy = __root.wasm_importtype_copy;
    pub const module = __root.wasm_importtype_module;
    pub const name = __root.wasm_importtype_name;
    pub const @"type" = __root.wasm_importtype_type;
};
pub const wasm_importtype_t = struct_wasm_importtype_t;
pub extern fn wasm_importtype_delete(?*wasm_importtype_t) void;
pub const struct_wasm_importtype_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_importtype_t,
    pub const wasm_importtype_vec_new_empty = __root.wasm_importtype_vec_new_empty;
    pub const wasm_importtype_vec_new_uninitialized = __root.wasm_importtype_vec_new_uninitialized;
    pub const wasm_importtype_vec_new = __root.wasm_importtype_vec_new;
    pub const wasm_importtype_vec_copy = __root.wasm_importtype_vec_copy;
    pub const wasm_importtype_vec_delete = __root.wasm_importtype_vec_delete;
    pub const empty = __root.wasm_importtype_vec_new_empty;
    pub const uninitialized = __root.wasm_importtype_vec_new_uninitialized;
    pub const new = __root.wasm_importtype_vec_new;
    pub const copy = __root.wasm_importtype_vec_copy;
    pub const delete = __root.wasm_importtype_vec_delete;
};
pub const wasm_importtype_vec_t = struct_wasm_importtype_vec_t;
pub extern fn wasm_importtype_vec_new_empty(out: [*c]wasm_importtype_vec_t) void;
pub extern fn wasm_importtype_vec_new_uninitialized(out: [*c]wasm_importtype_vec_t, usize) void;
pub extern fn wasm_importtype_vec_new(out: [*c]wasm_importtype_vec_t, usize, [*c]const ?*wasm_importtype_t) void;
pub extern fn wasm_importtype_vec_copy(out: [*c]wasm_importtype_vec_t, [*c]const wasm_importtype_vec_t) void;
pub extern fn wasm_importtype_vec_delete([*c]wasm_importtype_vec_t) void;
pub extern fn wasm_importtype_copy(?*const wasm_importtype_t) ?*wasm_importtype_t;
pub extern fn wasm_importtype_new(module: [*c]wasm_name_t, name: [*c]wasm_name_t, ?*wasm_externtype_t) ?*wasm_importtype_t;
pub extern fn wasm_importtype_module(?*const wasm_importtype_t) [*c]const wasm_name_t;
pub extern fn wasm_importtype_name(?*const wasm_importtype_t) [*c]const wasm_name_t;
pub extern fn wasm_importtype_type(?*const wasm_importtype_t) ?*const wasm_externtype_t;
pub const struct_wasm_exporttype_t = opaque {
    pub const wasm_exporttype_delete = __root.wasm_exporttype_delete;
    pub const wasm_exporttype_copy = __root.wasm_exporttype_copy;
    pub const wasm_exporttype_name = __root.wasm_exporttype_name;
    pub const wasm_exporttype_type = __root.wasm_exporttype_type;
    pub const delete = __root.wasm_exporttype_delete;
    pub const copy = __root.wasm_exporttype_copy;
    pub const name = __root.wasm_exporttype_name;
    pub const @"type" = __root.wasm_exporttype_type;
};
pub const wasm_exporttype_t = struct_wasm_exporttype_t;
pub extern fn wasm_exporttype_delete(?*wasm_exporttype_t) void;
pub const struct_wasm_exporttype_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_exporttype_t,
    pub const wasm_exporttype_vec_new_empty = __root.wasm_exporttype_vec_new_empty;
    pub const wasm_exporttype_vec_new_uninitialized = __root.wasm_exporttype_vec_new_uninitialized;
    pub const wasm_exporttype_vec_new = __root.wasm_exporttype_vec_new;
    pub const wasm_exporttype_vec_copy = __root.wasm_exporttype_vec_copy;
    pub const wasm_exporttype_vec_delete = __root.wasm_exporttype_vec_delete;
    pub const empty = __root.wasm_exporttype_vec_new_empty;
    pub const uninitialized = __root.wasm_exporttype_vec_new_uninitialized;
    pub const new = __root.wasm_exporttype_vec_new;
    pub const copy = __root.wasm_exporttype_vec_copy;
    pub const delete = __root.wasm_exporttype_vec_delete;
};
pub const wasm_exporttype_vec_t = struct_wasm_exporttype_vec_t;
pub extern fn wasm_exporttype_vec_new_empty(out: [*c]wasm_exporttype_vec_t) void;
pub extern fn wasm_exporttype_vec_new_uninitialized(out: [*c]wasm_exporttype_vec_t, usize) void;
pub extern fn wasm_exporttype_vec_new(out: [*c]wasm_exporttype_vec_t, usize, [*c]const ?*wasm_exporttype_t) void;
pub extern fn wasm_exporttype_vec_copy(out: [*c]wasm_exporttype_vec_t, [*c]const wasm_exporttype_vec_t) void;
pub extern fn wasm_exporttype_vec_delete([*c]wasm_exporttype_vec_t) void;
pub extern fn wasm_exporttype_copy(?*const wasm_exporttype_t) ?*wasm_exporttype_t;
pub extern fn wasm_exporttype_new([*c]wasm_name_t, ?*wasm_externtype_t) ?*wasm_exporttype_t;
pub extern fn wasm_exporttype_name(?*const wasm_exporttype_t) [*c]const wasm_name_t;
pub extern fn wasm_exporttype_type(?*const wasm_exporttype_t) ?*const wasm_externtype_t;
pub const struct_wasm_ref_t = opaque {
    pub const wasm_ref_delete = __root.wasm_ref_delete;
    pub const wasm_ref_copy = __root.wasm_ref_copy;
    pub const wasm_ref_same = __root.wasm_ref_same;
    pub const wasm_ref_get_host_info = __root.wasm_ref_get_host_info;
    pub const wasm_ref_set_host_info = __root.wasm_ref_set_host_info;
    pub const wasm_ref_set_host_info_with_finalizer = __root.wasm_ref_set_host_info_with_finalizer;
    pub const wasm_ref_as_trap = __root.wasm_ref_as_trap;
    pub const wasm_ref_as_trap_const = __root.wasm_ref_as_trap_const;
    pub const wasm_ref_as_foreign = __root.wasm_ref_as_foreign;
    pub const wasm_ref_as_foreign_const = __root.wasm_ref_as_foreign_const;
    pub const wasm_ref_as_module = __root.wasm_ref_as_module;
    pub const wasm_ref_as_module_const = __root.wasm_ref_as_module_const;
    pub const wasm_ref_as_func = __root.wasm_ref_as_func;
    pub const wasm_ref_as_func_const = __root.wasm_ref_as_func_const;
    pub const wasm_ref_as_global = __root.wasm_ref_as_global;
    pub const wasm_ref_as_global_const = __root.wasm_ref_as_global_const;
    pub const wasm_ref_as_table = __root.wasm_ref_as_table;
    pub const wasm_ref_as_table_const = __root.wasm_ref_as_table_const;
    pub const wasm_ref_as_memory = __root.wasm_ref_as_memory;
    pub const wasm_ref_as_memory_const = __root.wasm_ref_as_memory_const;
    pub const wasm_ref_as_extern = __root.wasm_ref_as_extern;
    pub const wasm_ref_as_extern_const = __root.wasm_ref_as_extern_const;
    pub const wasm_ref_as_instance = __root.wasm_ref_as_instance;
    pub const wasm_ref_as_instance_const = __root.wasm_ref_as_instance_const;
    pub const delete = __root.wasm_ref_delete;
    pub const copy = __root.wasm_ref_copy;
    pub const same = __root.wasm_ref_same;
    pub const info = __root.wasm_ref_get_host_info;
    pub const finalizer = __root.wasm_ref_set_host_info_with_finalizer;
    pub const trap = __root.wasm_ref_as_trap;
    pub const @"const" = __root.wasm_ref_as_trap_const;
    pub const foreign = __root.wasm_ref_as_foreign;
    pub const module = __root.wasm_ref_as_module;
    pub const func = __root.wasm_ref_as_func;
    pub const global = __root.wasm_ref_as_global;
    pub const table = __root.wasm_ref_as_table;
    pub const memory = __root.wasm_ref_as_memory;
    pub const @"extern" = __root.wasm_ref_as_extern;
    pub const instance = __root.wasm_ref_as_instance;
};
const union_unnamed_2 = extern union {
    i32: i32,
    i64: i64,
    f32: float32_t,
    f64: float64_t,
    ref: ?*struct_wasm_ref_t,
};
pub const struct_wasm_val_t = extern struct {
    kind: wasm_valkind_t,
    of: union_unnamed_2,
    pub const wasm_val_delete = __root.wasm_val_delete;
    pub const wasm_val_copy = __root.wasm_val_copy;
    pub const wasm_val_init_ptr = __root.wasm_val_init_ptr;
    pub const wasm_val_ptr = __root.wasm_val_ptr;
    pub const delete = __root.wasm_val_delete;
    pub const copy = __root.wasm_val_copy;
    pub const ptr = __root.wasm_val_init_ptr;
};
pub const wasm_val_t = struct_wasm_val_t;
pub extern fn wasm_val_delete(v: [*c]wasm_val_t) void;
pub extern fn wasm_val_copy(out: [*c]wasm_val_t, [*c]const wasm_val_t) void;
pub const struct_wasm_val_vec_t = extern struct {
    size: usize,
    data: [*c]wasm_val_t,
    pub const wasm_val_vec_new_empty = __root.wasm_val_vec_new_empty;
    pub const wasm_val_vec_new_uninitialized = __root.wasm_val_vec_new_uninitialized;
    pub const wasm_val_vec_new = __root.wasm_val_vec_new;
    pub const wasm_val_vec_copy = __root.wasm_val_vec_copy;
    pub const wasm_val_vec_delete = __root.wasm_val_vec_delete;
    pub const empty = __root.wasm_val_vec_new_empty;
    pub const uninitialized = __root.wasm_val_vec_new_uninitialized;
    pub const new = __root.wasm_val_vec_new;
    pub const copy = __root.wasm_val_vec_copy;
    pub const delete = __root.wasm_val_vec_delete;
};
pub const wasm_val_vec_t = struct_wasm_val_vec_t;
pub extern fn wasm_val_vec_new_empty(out: [*c]wasm_val_vec_t) void;
pub extern fn wasm_val_vec_new_uninitialized(out: [*c]wasm_val_vec_t, usize) void;
pub extern fn wasm_val_vec_new(out: [*c]wasm_val_vec_t, usize, [*c]const wasm_val_t) void;
pub extern fn wasm_val_vec_copy(out: [*c]wasm_val_vec_t, [*c]const wasm_val_vec_t) void;
pub extern fn wasm_val_vec_delete([*c]wasm_val_vec_t) void;
pub const wasm_ref_t = struct_wasm_ref_t;
pub extern fn wasm_ref_delete(?*wasm_ref_t) void;
pub extern fn wasm_ref_copy(?*const wasm_ref_t) ?*wasm_ref_t;
pub extern fn wasm_ref_same(?*const wasm_ref_t, ?*const wasm_ref_t) bool;
pub extern fn wasm_ref_get_host_info(?*const wasm_ref_t) ?*anyopaque;
pub extern fn wasm_ref_set_host_info(?*wasm_ref_t, ?*anyopaque) void;
pub extern fn wasm_ref_set_host_info_with_finalizer(?*wasm_ref_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub const struct_wasm_frame_t = opaque {
    pub const wasm_frame_delete = __root.wasm_frame_delete;
    pub const wasm_frame_copy = __root.wasm_frame_copy;
    pub const wasm_frame_instance = __root.wasm_frame_instance;
    pub const wasm_frame_func_index = __root.wasm_frame_func_index;
    pub const wasm_frame_func_offset = __root.wasm_frame_func_offset;
    pub const wasm_frame_module_offset = __root.wasm_frame_module_offset;
    pub const wasmtime_frame_func_name = __root.wasmtime_frame_func_name;
    pub const wasmtime_frame_module_name = __root.wasmtime_frame_module_name;
    pub const delete = __root.wasm_frame_delete;
    pub const copy = __root.wasm_frame_copy;
    pub const instance = __root.wasm_frame_instance;
    pub const offset = __root.wasm_frame_func_offset;
    pub const name = __root.wasmtime_frame_func_name;
};
pub const wasm_frame_t = struct_wasm_frame_t;
pub extern fn wasm_frame_delete(?*wasm_frame_t) void;
pub const struct_wasm_frame_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_frame_t,
    pub const wasm_frame_vec_new_empty = __root.wasm_frame_vec_new_empty;
    pub const wasm_frame_vec_new_uninitialized = __root.wasm_frame_vec_new_uninitialized;
    pub const wasm_frame_vec_new = __root.wasm_frame_vec_new;
    pub const wasm_frame_vec_copy = __root.wasm_frame_vec_copy;
    pub const wasm_frame_vec_delete = __root.wasm_frame_vec_delete;
    pub const empty = __root.wasm_frame_vec_new_empty;
    pub const uninitialized = __root.wasm_frame_vec_new_uninitialized;
    pub const new = __root.wasm_frame_vec_new;
    pub const copy = __root.wasm_frame_vec_copy;
    pub const delete = __root.wasm_frame_vec_delete;
};
pub const wasm_frame_vec_t = struct_wasm_frame_vec_t;
pub extern fn wasm_frame_vec_new_empty(out: [*c]wasm_frame_vec_t) void;
pub extern fn wasm_frame_vec_new_uninitialized(out: [*c]wasm_frame_vec_t, usize) void;
pub extern fn wasm_frame_vec_new(out: [*c]wasm_frame_vec_t, usize, [*c]const ?*wasm_frame_t) void;
pub extern fn wasm_frame_vec_copy(out: [*c]wasm_frame_vec_t, [*c]const wasm_frame_vec_t) void;
pub extern fn wasm_frame_vec_delete([*c]wasm_frame_vec_t) void;
pub extern fn wasm_frame_copy(?*const wasm_frame_t) ?*wasm_frame_t;
pub const struct_wasm_instance_t = opaque {
    pub const wasm_instance_delete = __root.wasm_instance_delete;
    pub const wasm_instance_copy = __root.wasm_instance_copy;
    pub const wasm_instance_same = __root.wasm_instance_same;
    pub const wasm_instance_get_host_info = __root.wasm_instance_get_host_info;
    pub const wasm_instance_set_host_info = __root.wasm_instance_set_host_info;
    pub const wasm_instance_set_host_info_with_finalizer = __root.wasm_instance_set_host_info_with_finalizer;
    pub const wasm_instance_as_ref = __root.wasm_instance_as_ref;
    pub const wasm_instance_as_ref_const = __root.wasm_instance_as_ref_const;
    pub const wasm_instance_exports = __root.wasm_instance_exports;
    pub const delete = __root.wasm_instance_delete;
    pub const copy = __root.wasm_instance_copy;
    pub const same = __root.wasm_instance_same;
    pub const info = __root.wasm_instance_get_host_info;
    pub const finalizer = __root.wasm_instance_set_host_info_with_finalizer;
    pub const ref = __root.wasm_instance_as_ref;
    pub const @"const" = __root.wasm_instance_as_ref_const;
    pub const exports = __root.wasm_instance_exports;
};
pub extern fn wasm_frame_instance(?*const wasm_frame_t) ?*struct_wasm_instance_t;
pub extern fn wasm_frame_func_index(?*const wasm_frame_t) u32;
pub extern fn wasm_frame_func_offset(?*const wasm_frame_t) usize;
pub extern fn wasm_frame_module_offset(?*const wasm_frame_t) usize;
pub const wasm_message_t = wasm_name_t;
pub const struct_wasm_trap_t = opaque {
    pub const wasm_trap_delete = __root.wasm_trap_delete;
    pub const wasm_trap_copy = __root.wasm_trap_copy;
    pub const wasm_trap_same = __root.wasm_trap_same;
    pub const wasm_trap_get_host_info = __root.wasm_trap_get_host_info;
    pub const wasm_trap_set_host_info = __root.wasm_trap_set_host_info;
    pub const wasm_trap_set_host_info_with_finalizer = __root.wasm_trap_set_host_info_with_finalizer;
    pub const wasm_trap_as_ref = __root.wasm_trap_as_ref;
    pub const wasm_trap_as_ref_const = __root.wasm_trap_as_ref_const;
    pub const wasm_trap_message = __root.wasm_trap_message;
    pub const wasm_trap_origin = __root.wasm_trap_origin;
    pub const wasm_trap_trace = __root.wasm_trap_trace;
    pub const wasmtime_trap_code = __root.wasmtime_trap_code;
    pub const delete = __root.wasm_trap_delete;
    pub const copy = __root.wasm_trap_copy;
    pub const same = __root.wasm_trap_same;
    pub const info = __root.wasm_trap_get_host_info;
    pub const finalizer = __root.wasm_trap_set_host_info_with_finalizer;
    pub const ref = __root.wasm_trap_as_ref;
    pub const @"const" = __root.wasm_trap_as_ref_const;
    pub const message = __root.wasm_trap_message;
    pub const origin = __root.wasm_trap_origin;
    pub const trace = __root.wasm_trap_trace;
    pub const code = __root.wasmtime_trap_code;
};
pub const wasm_trap_t = struct_wasm_trap_t;
pub extern fn wasm_trap_delete(?*wasm_trap_t) void;
pub extern fn wasm_trap_copy(?*const wasm_trap_t) ?*wasm_trap_t;
pub extern fn wasm_trap_same(?*const wasm_trap_t, ?*const wasm_trap_t) bool;
pub extern fn wasm_trap_get_host_info(?*const wasm_trap_t) ?*anyopaque;
pub extern fn wasm_trap_set_host_info(?*wasm_trap_t, ?*anyopaque) void;
pub extern fn wasm_trap_set_host_info_with_finalizer(?*wasm_trap_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasm_trap_as_ref(?*wasm_trap_t) ?*wasm_ref_t;
pub extern fn wasm_ref_as_trap(?*wasm_ref_t) ?*wasm_trap_t;
pub extern fn wasm_trap_as_ref_const(?*const wasm_trap_t) ?*const wasm_ref_t;
pub extern fn wasm_ref_as_trap_const(?*const wasm_ref_t) ?*const wasm_trap_t;
pub extern fn wasm_trap_new(store: ?*wasm_store_t, [*c]const wasm_message_t) ?*wasm_trap_t;
pub extern fn wasm_trap_message(?*const wasm_trap_t, out: [*c]wasm_message_t) void;
pub extern fn wasm_trap_origin(?*const wasm_trap_t) ?*wasm_frame_t;
pub extern fn wasm_trap_trace(?*const wasm_trap_t, out: [*c]wasm_frame_vec_t) void;
pub const struct_wasm_foreign_t = opaque {
    pub const wasm_foreign_delete = __root.wasm_foreign_delete;
    pub const wasm_foreign_copy = __root.wasm_foreign_copy;
    pub const wasm_foreign_same = __root.wasm_foreign_same;
    pub const wasm_foreign_get_host_info = __root.wasm_foreign_get_host_info;
    pub const wasm_foreign_set_host_info = __root.wasm_foreign_set_host_info;
    pub const wasm_foreign_set_host_info_with_finalizer = __root.wasm_foreign_set_host_info_with_finalizer;
    pub const wasm_foreign_as_ref = __root.wasm_foreign_as_ref;
    pub const wasm_foreign_as_ref_const = __root.wasm_foreign_as_ref_const;
    pub const delete = __root.wasm_foreign_delete;
    pub const copy = __root.wasm_foreign_copy;
    pub const same = __root.wasm_foreign_same;
    pub const info = __root.wasm_foreign_get_host_info;
    pub const finalizer = __root.wasm_foreign_set_host_info_with_finalizer;
    pub const ref = __root.wasm_foreign_as_ref;
    pub const @"const" = __root.wasm_foreign_as_ref_const;
};
pub const wasm_foreign_t = struct_wasm_foreign_t;
pub extern fn wasm_foreign_delete(?*wasm_foreign_t) void;
pub extern fn wasm_foreign_copy(?*const wasm_foreign_t) ?*wasm_foreign_t;
pub extern fn wasm_foreign_same(?*const wasm_foreign_t, ?*const wasm_foreign_t) bool;
pub extern fn wasm_foreign_get_host_info(?*const wasm_foreign_t) ?*anyopaque;
pub extern fn wasm_foreign_set_host_info(?*wasm_foreign_t, ?*anyopaque) void;
pub extern fn wasm_foreign_set_host_info_with_finalizer(?*wasm_foreign_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasm_foreign_as_ref(?*wasm_foreign_t) ?*wasm_ref_t;
pub extern fn wasm_ref_as_foreign(?*wasm_ref_t) ?*wasm_foreign_t;
pub extern fn wasm_foreign_as_ref_const(?*const wasm_foreign_t) ?*const wasm_ref_t;
pub extern fn wasm_ref_as_foreign_const(?*const wasm_ref_t) ?*const wasm_foreign_t;
pub extern fn wasm_foreign_new(?*wasm_store_t) ?*wasm_foreign_t;
pub const struct_wasm_module_t = opaque {
    pub const wasm_module_delete = __root.wasm_module_delete;
    pub const wasm_module_copy = __root.wasm_module_copy;
    pub const wasm_module_same = __root.wasm_module_same;
    pub const wasm_module_get_host_info = __root.wasm_module_get_host_info;
    pub const wasm_module_set_host_info = __root.wasm_module_set_host_info;
    pub const wasm_module_set_host_info_with_finalizer = __root.wasm_module_set_host_info_with_finalizer;
    pub const wasm_module_as_ref = __root.wasm_module_as_ref;
    pub const wasm_module_as_ref_const = __root.wasm_module_as_ref_const;
    pub const wasm_module_share = __root.wasm_module_share;
    pub const wasm_module_imports = __root.wasm_module_imports;
    pub const wasm_module_exports = __root.wasm_module_exports;
    pub const wasm_module_serialize = __root.wasm_module_serialize;
    pub const delete = __root.wasm_module_delete;
    pub const copy = __root.wasm_module_copy;
    pub const same = __root.wasm_module_same;
    pub const info = __root.wasm_module_get_host_info;
    pub const finalizer = __root.wasm_module_set_host_info_with_finalizer;
    pub const ref = __root.wasm_module_as_ref;
    pub const @"const" = __root.wasm_module_as_ref_const;
    pub const share = __root.wasm_module_share;
    pub const imports = __root.wasm_module_imports;
    pub const exports = __root.wasm_module_exports;
    pub const serialize = __root.wasm_module_serialize;
};
pub const wasm_module_t = struct_wasm_module_t;
pub extern fn wasm_module_delete(?*wasm_module_t) void;
pub extern fn wasm_module_copy(?*const wasm_module_t) ?*wasm_module_t;
pub extern fn wasm_module_same(?*const wasm_module_t, ?*const wasm_module_t) bool;
pub extern fn wasm_module_get_host_info(?*const wasm_module_t) ?*anyopaque;
pub extern fn wasm_module_set_host_info(?*wasm_module_t, ?*anyopaque) void;
pub extern fn wasm_module_set_host_info_with_finalizer(?*wasm_module_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasm_module_as_ref(?*wasm_module_t) ?*wasm_ref_t;
pub extern fn wasm_ref_as_module(?*wasm_ref_t) ?*wasm_module_t;
pub extern fn wasm_module_as_ref_const(?*const wasm_module_t) ?*const wasm_ref_t;
pub extern fn wasm_ref_as_module_const(?*const wasm_ref_t) ?*const wasm_module_t;
pub const struct_wasm_shared_module_t = opaque {
    pub const wasm_shared_module_delete = __root.wasm_shared_module_delete;
    pub const delete = __root.wasm_shared_module_delete;
};
pub const wasm_shared_module_t = struct_wasm_shared_module_t;
pub extern fn wasm_shared_module_delete(?*wasm_shared_module_t) void;
pub extern fn wasm_module_share(?*const wasm_module_t) ?*wasm_shared_module_t;
pub extern fn wasm_module_obtain(?*wasm_store_t, ?*const wasm_shared_module_t) ?*wasm_module_t;
pub extern fn wasm_module_new(?*wasm_store_t, binary: [*c]const wasm_byte_vec_t) ?*wasm_module_t;
pub extern fn wasm_module_validate(?*wasm_store_t, binary: [*c]const wasm_byte_vec_t) bool;
pub extern fn wasm_module_imports(?*const wasm_module_t, out: [*c]wasm_importtype_vec_t) void;
pub extern fn wasm_module_exports(?*const wasm_module_t, out: [*c]wasm_exporttype_vec_t) void;
pub extern fn wasm_module_serialize(?*const wasm_module_t, out: [*c]wasm_byte_vec_t) void;
pub extern fn wasm_module_deserialize(?*wasm_store_t, [*c]const wasm_byte_vec_t) ?*wasm_module_t;
pub const struct_wasm_func_t = opaque {
    pub const wasm_func_delete = __root.wasm_func_delete;
    pub const wasm_func_copy = __root.wasm_func_copy;
    pub const wasm_func_same = __root.wasm_func_same;
    pub const wasm_func_get_host_info = __root.wasm_func_get_host_info;
    pub const wasm_func_set_host_info = __root.wasm_func_set_host_info;
    pub const wasm_func_set_host_info_with_finalizer = __root.wasm_func_set_host_info_with_finalizer;
    pub const wasm_func_as_ref = __root.wasm_func_as_ref;
    pub const wasm_func_as_ref_const = __root.wasm_func_as_ref_const;
    pub const wasm_func_type = __root.wasm_func_type;
    pub const wasm_func_param_arity = __root.wasm_func_param_arity;
    pub const wasm_func_result_arity = __root.wasm_func_result_arity;
    pub const wasm_func_call = __root.wasm_func_call;
    pub const wasm_func_as_extern = __root.wasm_func_as_extern;
    pub const wasm_func_as_extern_const = __root.wasm_func_as_extern_const;
    pub const delete = __root.wasm_func_delete;
    pub const copy = __root.wasm_func_copy;
    pub const same = __root.wasm_func_same;
    pub const info = __root.wasm_func_get_host_info;
    pub const finalizer = __root.wasm_func_set_host_info_with_finalizer;
    pub const ref = __root.wasm_func_as_ref;
    pub const @"const" = __root.wasm_func_as_ref_const;
    pub const @"type" = __root.wasm_func_type;
    pub const arity = __root.wasm_func_param_arity;
    pub const call = __root.wasm_func_call;
    pub const @"extern" = __root.wasm_func_as_extern;
};
pub const wasm_func_t = struct_wasm_func_t;
pub extern fn wasm_func_delete(?*wasm_func_t) void;
pub extern fn wasm_func_copy(?*const wasm_func_t) ?*wasm_func_t;
pub extern fn wasm_func_same(?*const wasm_func_t, ?*const wasm_func_t) bool;
pub extern fn wasm_func_get_host_info(?*const wasm_func_t) ?*anyopaque;
pub extern fn wasm_func_set_host_info(?*wasm_func_t, ?*anyopaque) void;
pub extern fn wasm_func_set_host_info_with_finalizer(?*wasm_func_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasm_func_as_ref(?*wasm_func_t) ?*wasm_ref_t;
pub extern fn wasm_ref_as_func(?*wasm_ref_t) ?*wasm_func_t;
pub extern fn wasm_func_as_ref_const(?*const wasm_func_t) ?*const wasm_ref_t;
pub extern fn wasm_ref_as_func_const(?*const wasm_ref_t) ?*const wasm_func_t;
pub const wasm_func_callback_t = ?*const fn (args: [*c]const wasm_val_vec_t, results: [*c]wasm_val_vec_t) callconv(.c) ?*wasm_trap_t;
pub const wasm_func_callback_with_env_t = ?*const fn (env: ?*anyopaque, args: [*c]const wasm_val_vec_t, results: [*c]wasm_val_vec_t) callconv(.c) ?*wasm_trap_t;
pub extern fn wasm_func_new(?*wasm_store_t, ?*const wasm_functype_t, wasm_func_callback_t) ?*wasm_func_t;
pub extern fn wasm_func_new_with_env(?*wasm_store_t, @"type": ?*const wasm_functype_t, wasm_func_callback_with_env_t, env: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) ?*wasm_func_t;
pub extern fn wasm_func_type(?*const wasm_func_t) ?*wasm_functype_t;
pub extern fn wasm_func_param_arity(?*const wasm_func_t) usize;
pub extern fn wasm_func_result_arity(?*const wasm_func_t) usize;
pub extern fn wasm_func_call(?*const wasm_func_t, args: [*c]const wasm_val_vec_t, results: [*c]wasm_val_vec_t) ?*wasm_trap_t;
pub const struct_wasm_global_t = opaque {
    pub const wasm_global_delete = __root.wasm_global_delete;
    pub const wasm_global_copy = __root.wasm_global_copy;
    pub const wasm_global_same = __root.wasm_global_same;
    pub const wasm_global_get_host_info = __root.wasm_global_get_host_info;
    pub const wasm_global_set_host_info = __root.wasm_global_set_host_info;
    pub const wasm_global_set_host_info_with_finalizer = __root.wasm_global_set_host_info_with_finalizer;
    pub const wasm_global_as_ref = __root.wasm_global_as_ref;
    pub const wasm_global_as_ref_const = __root.wasm_global_as_ref_const;
    pub const wasm_global_type = __root.wasm_global_type;
    pub const wasm_global_get = __root.wasm_global_get;
    pub const wasm_global_set = __root.wasm_global_set;
    pub const wasm_global_as_extern = __root.wasm_global_as_extern;
    pub const wasm_global_as_extern_const = __root.wasm_global_as_extern_const;
    pub const delete = __root.wasm_global_delete;
    pub const copy = __root.wasm_global_copy;
    pub const same = __root.wasm_global_same;
    pub const info = __root.wasm_global_get_host_info;
    pub const finalizer = __root.wasm_global_set_host_info_with_finalizer;
    pub const ref = __root.wasm_global_as_ref;
    pub const @"const" = __root.wasm_global_as_ref_const;
    pub const @"type" = __root.wasm_global_type;
    pub const get = __root.wasm_global_get;
    pub const set = __root.wasm_global_set;
    pub const @"extern" = __root.wasm_global_as_extern;
};
pub const wasm_global_t = struct_wasm_global_t;
pub extern fn wasm_global_delete(?*wasm_global_t) void;
pub extern fn wasm_global_copy(?*const wasm_global_t) ?*wasm_global_t;
pub extern fn wasm_global_same(?*const wasm_global_t, ?*const wasm_global_t) bool;
pub extern fn wasm_global_get_host_info(?*const wasm_global_t) ?*anyopaque;
pub extern fn wasm_global_set_host_info(?*wasm_global_t, ?*anyopaque) void;
pub extern fn wasm_global_set_host_info_with_finalizer(?*wasm_global_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasm_global_as_ref(?*wasm_global_t) ?*wasm_ref_t;
pub extern fn wasm_ref_as_global(?*wasm_ref_t) ?*wasm_global_t;
pub extern fn wasm_global_as_ref_const(?*const wasm_global_t) ?*const wasm_ref_t;
pub extern fn wasm_ref_as_global_const(?*const wasm_ref_t) ?*const wasm_global_t;
pub extern fn wasm_global_new(?*wasm_store_t, ?*const wasm_globaltype_t, [*c]const wasm_val_t) ?*wasm_global_t;
pub extern fn wasm_global_type(?*const wasm_global_t) ?*wasm_globaltype_t;
pub extern fn wasm_global_get(?*const wasm_global_t, out: [*c]wasm_val_t) void;
pub extern fn wasm_global_set(?*wasm_global_t, [*c]const wasm_val_t) void;
pub const struct_wasm_table_t = opaque {
    pub const wasm_table_delete = __root.wasm_table_delete;
    pub const wasm_table_copy = __root.wasm_table_copy;
    pub const wasm_table_same = __root.wasm_table_same;
    pub const wasm_table_get_host_info = __root.wasm_table_get_host_info;
    pub const wasm_table_set_host_info = __root.wasm_table_set_host_info;
    pub const wasm_table_set_host_info_with_finalizer = __root.wasm_table_set_host_info_with_finalizer;
    pub const wasm_table_as_ref = __root.wasm_table_as_ref;
    pub const wasm_table_as_ref_const = __root.wasm_table_as_ref_const;
    pub const wasm_table_type = __root.wasm_table_type;
    pub const wasm_table_get = __root.wasm_table_get;
    pub const wasm_table_set = __root.wasm_table_set;
    pub const wasm_table_size = __root.wasm_table_size;
    pub const wasm_table_grow = __root.wasm_table_grow;
    pub const wasm_table_as_extern = __root.wasm_table_as_extern;
    pub const wasm_table_as_extern_const = __root.wasm_table_as_extern_const;
    pub const delete = __root.wasm_table_delete;
    pub const copy = __root.wasm_table_copy;
    pub const same = __root.wasm_table_same;
    pub const info = __root.wasm_table_get_host_info;
    pub const finalizer = __root.wasm_table_set_host_info_with_finalizer;
    pub const ref = __root.wasm_table_as_ref;
    pub const @"const" = __root.wasm_table_as_ref_const;
    pub const @"type" = __root.wasm_table_type;
    pub const get = __root.wasm_table_get;
    pub const set = __root.wasm_table_set;
    pub const size = __root.wasm_table_size;
    pub const grow = __root.wasm_table_grow;
    pub const @"extern" = __root.wasm_table_as_extern;
};
pub const wasm_table_t = struct_wasm_table_t;
pub extern fn wasm_table_delete(?*wasm_table_t) void;
pub extern fn wasm_table_copy(?*const wasm_table_t) ?*wasm_table_t;
pub extern fn wasm_table_same(?*const wasm_table_t, ?*const wasm_table_t) bool;
pub extern fn wasm_table_get_host_info(?*const wasm_table_t) ?*anyopaque;
pub extern fn wasm_table_set_host_info(?*wasm_table_t, ?*anyopaque) void;
pub extern fn wasm_table_set_host_info_with_finalizer(?*wasm_table_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasm_table_as_ref(?*wasm_table_t) ?*wasm_ref_t;
pub extern fn wasm_ref_as_table(?*wasm_ref_t) ?*wasm_table_t;
pub extern fn wasm_table_as_ref_const(?*const wasm_table_t) ?*const wasm_ref_t;
pub extern fn wasm_ref_as_table_const(?*const wasm_ref_t) ?*const wasm_table_t;
pub const wasm_table_size_t = u32;
pub extern fn wasm_table_new(?*wasm_store_t, ?*const wasm_tabletype_t, init: ?*wasm_ref_t) ?*wasm_table_t;
pub extern fn wasm_table_type(?*const wasm_table_t) ?*wasm_tabletype_t;
pub extern fn wasm_table_get(?*const wasm_table_t, index: wasm_table_size_t) ?*wasm_ref_t;
pub extern fn wasm_table_set(?*wasm_table_t, index: wasm_table_size_t, ?*wasm_ref_t) bool;
pub extern fn wasm_table_size(?*const wasm_table_t) wasm_table_size_t;
pub extern fn wasm_table_grow(?*wasm_table_t, delta: wasm_table_size_t, init: ?*wasm_ref_t) bool;
pub const struct_wasm_memory_t = opaque {
    pub const wasm_memory_delete = __root.wasm_memory_delete;
    pub const wasm_memory_copy = __root.wasm_memory_copy;
    pub const wasm_memory_same = __root.wasm_memory_same;
    pub const wasm_memory_get_host_info = __root.wasm_memory_get_host_info;
    pub const wasm_memory_set_host_info = __root.wasm_memory_set_host_info;
    pub const wasm_memory_set_host_info_with_finalizer = __root.wasm_memory_set_host_info_with_finalizer;
    pub const wasm_memory_as_ref = __root.wasm_memory_as_ref;
    pub const wasm_memory_as_ref_const = __root.wasm_memory_as_ref_const;
    pub const wasm_memory_type = __root.wasm_memory_type;
    pub const wasm_memory_data = __root.wasm_memory_data;
    pub const wasm_memory_data_size = __root.wasm_memory_data_size;
    pub const wasm_memory_size = __root.wasm_memory_size;
    pub const wasm_memory_grow = __root.wasm_memory_grow;
    pub const wasm_memory_as_extern = __root.wasm_memory_as_extern;
    pub const wasm_memory_as_extern_const = __root.wasm_memory_as_extern_const;
    pub const delete = __root.wasm_memory_delete;
    pub const copy = __root.wasm_memory_copy;
    pub const same = __root.wasm_memory_same;
    pub const info = __root.wasm_memory_get_host_info;
    pub const finalizer = __root.wasm_memory_set_host_info_with_finalizer;
    pub const ref = __root.wasm_memory_as_ref;
    pub const @"const" = __root.wasm_memory_as_ref_const;
    pub const @"type" = __root.wasm_memory_type;
    pub const data = __root.wasm_memory_data;
    pub const size = __root.wasm_memory_data_size;
    pub const grow = __root.wasm_memory_grow;
    pub const @"extern" = __root.wasm_memory_as_extern;
};
pub const wasm_memory_t = struct_wasm_memory_t;
pub extern fn wasm_memory_delete(?*wasm_memory_t) void;
pub extern fn wasm_memory_copy(?*const wasm_memory_t) ?*wasm_memory_t;
pub extern fn wasm_memory_same(?*const wasm_memory_t, ?*const wasm_memory_t) bool;
pub extern fn wasm_memory_get_host_info(?*const wasm_memory_t) ?*anyopaque;
pub extern fn wasm_memory_set_host_info(?*wasm_memory_t, ?*anyopaque) void;
pub extern fn wasm_memory_set_host_info_with_finalizer(?*wasm_memory_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasm_memory_as_ref(?*wasm_memory_t) ?*wasm_ref_t;
pub extern fn wasm_ref_as_memory(?*wasm_ref_t) ?*wasm_memory_t;
pub extern fn wasm_memory_as_ref_const(?*const wasm_memory_t) ?*const wasm_ref_t;
pub extern fn wasm_ref_as_memory_const(?*const wasm_ref_t) ?*const wasm_memory_t;
pub const wasm_memory_pages_t = u32;
pub const MEMORY_PAGE_SIZE: usize = 65536;
pub extern fn wasm_memory_new(?*wasm_store_t, ?*const wasm_memorytype_t) ?*wasm_memory_t;
pub extern fn wasm_memory_type(?*const wasm_memory_t) ?*wasm_memorytype_t;
pub extern fn wasm_memory_data(?*wasm_memory_t) [*c]byte_t;
pub extern fn wasm_memory_data_size(?*const wasm_memory_t) usize;
pub extern fn wasm_memory_size(?*const wasm_memory_t) wasm_memory_pages_t;
pub extern fn wasm_memory_grow(?*wasm_memory_t, delta: wasm_memory_pages_t) bool;
pub const struct_wasm_extern_t = opaque {
    pub const wasm_extern_delete = __root.wasm_extern_delete;
    pub const wasm_extern_copy = __root.wasm_extern_copy;
    pub const wasm_extern_same = __root.wasm_extern_same;
    pub const wasm_extern_get_host_info = __root.wasm_extern_get_host_info;
    pub const wasm_extern_set_host_info = __root.wasm_extern_set_host_info;
    pub const wasm_extern_set_host_info_with_finalizer = __root.wasm_extern_set_host_info_with_finalizer;
    pub const wasm_extern_as_ref = __root.wasm_extern_as_ref;
    pub const wasm_extern_as_ref_const = __root.wasm_extern_as_ref_const;
    pub const wasm_extern_kind = __root.wasm_extern_kind;
    pub const wasm_extern_type = __root.wasm_extern_type;
    pub const wasm_extern_as_func = __root.wasm_extern_as_func;
    pub const wasm_extern_as_global = __root.wasm_extern_as_global;
    pub const wasm_extern_as_table = __root.wasm_extern_as_table;
    pub const wasm_extern_as_memory = __root.wasm_extern_as_memory;
    pub const wasm_extern_as_func_const = __root.wasm_extern_as_func_const;
    pub const wasm_extern_as_global_const = __root.wasm_extern_as_global_const;
    pub const wasm_extern_as_table_const = __root.wasm_extern_as_table_const;
    pub const wasm_extern_as_memory_const = __root.wasm_extern_as_memory_const;
    pub const delete = __root.wasm_extern_delete;
    pub const copy = __root.wasm_extern_copy;
    pub const same = __root.wasm_extern_same;
    pub const info = __root.wasm_extern_get_host_info;
    pub const finalizer = __root.wasm_extern_set_host_info_with_finalizer;
    pub const ref = __root.wasm_extern_as_ref;
    pub const @"const" = __root.wasm_extern_as_ref_const;
    pub const kind = __root.wasm_extern_kind;
    pub const @"type" = __root.wasm_extern_type;
    pub const func = __root.wasm_extern_as_func;
    pub const global = __root.wasm_extern_as_global;
    pub const table = __root.wasm_extern_as_table;
    pub const memory = __root.wasm_extern_as_memory;
};
pub const wasm_extern_t = struct_wasm_extern_t;
pub extern fn wasm_extern_delete(?*wasm_extern_t) void;
pub extern fn wasm_extern_copy(?*const wasm_extern_t) ?*wasm_extern_t;
pub extern fn wasm_extern_same(?*const wasm_extern_t, ?*const wasm_extern_t) bool;
pub extern fn wasm_extern_get_host_info(?*const wasm_extern_t) ?*anyopaque;
pub extern fn wasm_extern_set_host_info(?*wasm_extern_t, ?*anyopaque) void;
pub extern fn wasm_extern_set_host_info_with_finalizer(?*wasm_extern_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasm_extern_as_ref(?*wasm_extern_t) ?*wasm_ref_t;
pub extern fn wasm_ref_as_extern(?*wasm_ref_t) ?*wasm_extern_t;
pub extern fn wasm_extern_as_ref_const(?*const wasm_extern_t) ?*const wasm_ref_t;
pub extern fn wasm_ref_as_extern_const(?*const wasm_ref_t) ?*const wasm_extern_t;
pub const struct_wasm_extern_vec_t = extern struct {
    size: usize,
    data: [*c]?*wasm_extern_t,
    pub const wasm_extern_vec_new_empty = __root.wasm_extern_vec_new_empty;
    pub const wasm_extern_vec_new_uninitialized = __root.wasm_extern_vec_new_uninitialized;
    pub const wasm_extern_vec_new = __root.wasm_extern_vec_new;
    pub const wasm_extern_vec_copy = __root.wasm_extern_vec_copy;
    pub const wasm_extern_vec_delete = __root.wasm_extern_vec_delete;
    pub const empty = __root.wasm_extern_vec_new_empty;
    pub const uninitialized = __root.wasm_extern_vec_new_uninitialized;
    pub const new = __root.wasm_extern_vec_new;
    pub const copy = __root.wasm_extern_vec_copy;
    pub const delete = __root.wasm_extern_vec_delete;
};
pub const wasm_extern_vec_t = struct_wasm_extern_vec_t;
pub extern fn wasm_extern_vec_new_empty(out: [*c]wasm_extern_vec_t) void;
pub extern fn wasm_extern_vec_new_uninitialized(out: [*c]wasm_extern_vec_t, usize) void;
pub extern fn wasm_extern_vec_new(out: [*c]wasm_extern_vec_t, usize, [*c]const ?*wasm_extern_t) void;
pub extern fn wasm_extern_vec_copy(out: [*c]wasm_extern_vec_t, [*c]const wasm_extern_vec_t) void;
pub extern fn wasm_extern_vec_delete([*c]wasm_extern_vec_t) void;
pub extern fn wasm_extern_kind(?*const wasm_extern_t) wasm_externkind_t;
pub extern fn wasm_extern_type(?*const wasm_extern_t) ?*wasm_externtype_t;
pub extern fn wasm_func_as_extern(?*wasm_func_t) ?*wasm_extern_t;
pub extern fn wasm_global_as_extern(?*wasm_global_t) ?*wasm_extern_t;
pub extern fn wasm_table_as_extern(?*wasm_table_t) ?*wasm_extern_t;
pub extern fn wasm_memory_as_extern(?*wasm_memory_t) ?*wasm_extern_t;
pub extern fn wasm_extern_as_func(?*wasm_extern_t) ?*wasm_func_t;
pub extern fn wasm_extern_as_global(?*wasm_extern_t) ?*wasm_global_t;
pub extern fn wasm_extern_as_table(?*wasm_extern_t) ?*wasm_table_t;
pub extern fn wasm_extern_as_memory(?*wasm_extern_t) ?*wasm_memory_t;
pub extern fn wasm_func_as_extern_const(?*const wasm_func_t) ?*const wasm_extern_t;
pub extern fn wasm_global_as_extern_const(?*const wasm_global_t) ?*const wasm_extern_t;
pub extern fn wasm_table_as_extern_const(?*const wasm_table_t) ?*const wasm_extern_t;
pub extern fn wasm_memory_as_extern_const(?*const wasm_memory_t) ?*const wasm_extern_t;
pub extern fn wasm_extern_as_func_const(?*const wasm_extern_t) ?*const wasm_func_t;
pub extern fn wasm_extern_as_global_const(?*const wasm_extern_t) ?*const wasm_global_t;
pub extern fn wasm_extern_as_table_const(?*const wasm_extern_t) ?*const wasm_table_t;
pub extern fn wasm_extern_as_memory_const(?*const wasm_extern_t) ?*const wasm_memory_t;
pub const wasm_instance_t = struct_wasm_instance_t;
pub extern fn wasm_instance_delete(?*wasm_instance_t) void;
pub extern fn wasm_instance_copy(?*const wasm_instance_t) ?*wasm_instance_t;
pub extern fn wasm_instance_same(?*const wasm_instance_t, ?*const wasm_instance_t) bool;
pub extern fn wasm_instance_get_host_info(?*const wasm_instance_t) ?*anyopaque;
pub extern fn wasm_instance_set_host_info(?*wasm_instance_t, ?*anyopaque) void;
pub extern fn wasm_instance_set_host_info_with_finalizer(?*wasm_instance_t, ?*anyopaque, ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasm_instance_as_ref(?*wasm_instance_t) ?*wasm_ref_t;
pub extern fn wasm_ref_as_instance(?*wasm_ref_t) ?*wasm_instance_t;
pub extern fn wasm_instance_as_ref_const(?*const wasm_instance_t) ?*const wasm_ref_t;
pub extern fn wasm_ref_as_instance_const(?*const wasm_ref_t) ?*const wasm_instance_t;
pub extern fn wasm_instance_new(?*wasm_store_t, ?*const wasm_module_t, imports: [*c]const wasm_extern_vec_t, [*c]?*wasm_trap_t) ?*wasm_instance_t;
pub extern fn wasm_instance_exports(?*const wasm_instance_t, out: [*c]wasm_extern_vec_t) void;
pub fn wasm_valtype_new_i32() callconv(.c) ?*wasm_valtype_t {
    return wasm_valtype_new(WASM_I32);
}
pub fn wasm_valtype_new_i64() callconv(.c) ?*wasm_valtype_t {
    return wasm_valtype_new(WASM_I64);
}
pub fn wasm_valtype_new_f32() callconv(.c) ?*wasm_valtype_t {
    return wasm_valtype_new(WASM_F32);
}
pub fn wasm_valtype_new_f64() callconv(.c) ?*wasm_valtype_t {
    return wasm_valtype_new(WASM_F64);
}
pub fn wasm_valtype_new_externref() callconv(.c) ?*wasm_valtype_t {
    return wasm_valtype_new(WASM_EXTERNREF);
}
pub fn wasm_valtype_new_funcref() callconv(.c) ?*wasm_valtype_t {
    return wasm_valtype_new(WASM_FUNCREF);
}
pub fn wasm_functype_new_0_0() callconv(.c) ?*wasm_functype_t {
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new_empty(&params);
    wasm_valtype_vec_new_empty(&results);
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_1_0(arg_p: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var p = arg_p;
    _ = &p;
    var ps: [1]?*wasm_valtype_t = [1]?*wasm_valtype_t{
        p,
    };
    _ = &ps;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new(&params, 1, @ptrCast(@alignCast(&ps)));
    wasm_valtype_vec_new_empty(&results);
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_2_0(arg_p1: ?*wasm_valtype_t, arg_p2: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var p1 = arg_p1;
    _ = &p1;
    var p2 = arg_p2;
    _ = &p2;
    var ps: [2]?*wasm_valtype_t = [2]?*wasm_valtype_t{
        p1,
        p2,
    };
    _ = &ps;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new(&params, 2, @ptrCast(@alignCast(&ps)));
    wasm_valtype_vec_new_empty(&results);
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_3_0(arg_p1: ?*wasm_valtype_t, arg_p2: ?*wasm_valtype_t, arg_p3: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var p1 = arg_p1;
    _ = &p1;
    var p2 = arg_p2;
    _ = &p2;
    var p3 = arg_p3;
    _ = &p3;
    var ps: [3]?*wasm_valtype_t = [3]?*wasm_valtype_t{
        p1,
        p2,
        p3,
    };
    _ = &ps;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new(&params, 3, @ptrCast(@alignCast(&ps)));
    wasm_valtype_vec_new_empty(&results);
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_0_1(arg_r: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var r = arg_r;
    _ = &r;
    var rs: [1]?*wasm_valtype_t = [1]?*wasm_valtype_t{
        r,
    };
    _ = &rs;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new_empty(&params);
    wasm_valtype_vec_new(&results, 1, @ptrCast(@alignCast(&rs)));
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_1_1(arg_p: ?*wasm_valtype_t, arg_r: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var p = arg_p;
    _ = &p;
    var r = arg_r;
    _ = &r;
    var ps: [1]?*wasm_valtype_t = [1]?*wasm_valtype_t{
        p,
    };
    _ = &ps;
    var rs: [1]?*wasm_valtype_t = [1]?*wasm_valtype_t{
        r,
    };
    _ = &rs;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new(&params, 1, @ptrCast(@alignCast(&ps)));
    wasm_valtype_vec_new(&results, 1, @ptrCast(@alignCast(&rs)));
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_2_1(arg_p1: ?*wasm_valtype_t, arg_p2: ?*wasm_valtype_t, arg_r: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var p1 = arg_p1;
    _ = &p1;
    var p2 = arg_p2;
    _ = &p2;
    var r = arg_r;
    _ = &r;
    var ps: [2]?*wasm_valtype_t = [2]?*wasm_valtype_t{
        p1,
        p2,
    };
    _ = &ps;
    var rs: [1]?*wasm_valtype_t = [1]?*wasm_valtype_t{
        r,
    };
    _ = &rs;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new(&params, 2, @ptrCast(@alignCast(&ps)));
    wasm_valtype_vec_new(&results, 1, @ptrCast(@alignCast(&rs)));
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_3_1(arg_p1: ?*wasm_valtype_t, arg_p2: ?*wasm_valtype_t, arg_p3: ?*wasm_valtype_t, arg_r: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var p1 = arg_p1;
    _ = &p1;
    var p2 = arg_p2;
    _ = &p2;
    var p3 = arg_p3;
    _ = &p3;
    var r = arg_r;
    _ = &r;
    var ps: [3]?*wasm_valtype_t = [3]?*wasm_valtype_t{
        p1,
        p2,
        p3,
    };
    _ = &ps;
    var rs: [1]?*wasm_valtype_t = [1]?*wasm_valtype_t{
        r,
    };
    _ = &rs;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new(&params, 3, @ptrCast(@alignCast(&ps)));
    wasm_valtype_vec_new(&results, 1, @ptrCast(@alignCast(&rs)));
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_0_2(arg_r1: ?*wasm_valtype_t, arg_r2: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var r1 = arg_r1;
    _ = &r1;
    var r2 = arg_r2;
    _ = &r2;
    var rs: [2]?*wasm_valtype_t = [2]?*wasm_valtype_t{
        r1,
        r2,
    };
    _ = &rs;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new_empty(&params);
    wasm_valtype_vec_new(&results, 2, @ptrCast(@alignCast(&rs)));
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_1_2(arg_p: ?*wasm_valtype_t, arg_r1: ?*wasm_valtype_t, arg_r2: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var p = arg_p;
    _ = &p;
    var r1 = arg_r1;
    _ = &r1;
    var r2 = arg_r2;
    _ = &r2;
    var ps: [1]?*wasm_valtype_t = [1]?*wasm_valtype_t{
        p,
    };
    _ = &ps;
    var rs: [2]?*wasm_valtype_t = [2]?*wasm_valtype_t{
        r1,
        r2,
    };
    _ = &rs;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new(&params, 1, @ptrCast(@alignCast(&ps)));
    wasm_valtype_vec_new(&results, 2, @ptrCast(@alignCast(&rs)));
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_2_2(arg_p1: ?*wasm_valtype_t, arg_p2: ?*wasm_valtype_t, arg_r1: ?*wasm_valtype_t, arg_r2: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var p1 = arg_p1;
    _ = &p1;
    var p2 = arg_p2;
    _ = &p2;
    var r1 = arg_r1;
    _ = &r1;
    var r2 = arg_r2;
    _ = &r2;
    var ps: [2]?*wasm_valtype_t = [2]?*wasm_valtype_t{
        p1,
        p2,
    };
    _ = &ps;
    var rs: [2]?*wasm_valtype_t = [2]?*wasm_valtype_t{
        r1,
        r2,
    };
    _ = &rs;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new(&params, 2, @ptrCast(@alignCast(&ps)));
    wasm_valtype_vec_new(&results, 2, @ptrCast(@alignCast(&rs)));
    return wasm_functype_new(&params, &results);
}
pub fn wasm_functype_new_3_2(arg_p1: ?*wasm_valtype_t, arg_p2: ?*wasm_valtype_t, arg_p3: ?*wasm_valtype_t, arg_r1: ?*wasm_valtype_t, arg_r2: ?*wasm_valtype_t) callconv(.c) ?*wasm_functype_t {
    var p1 = arg_p1;
    _ = &p1;
    var p2 = arg_p2;
    _ = &p2;
    var p3 = arg_p3;
    _ = &p3;
    var r1 = arg_r1;
    _ = &r1;
    var r2 = arg_r2;
    _ = &r2;
    var ps: [3]?*wasm_valtype_t = [3]?*wasm_valtype_t{
        p1,
        p2,
        p3,
    };
    _ = &ps;
    var rs: [2]?*wasm_valtype_t = [2]?*wasm_valtype_t{
        r1,
        r2,
    };
    _ = &rs;
    var params: wasm_valtype_vec_t = undefined;
    _ = &params;
    var results: wasm_valtype_vec_t = undefined;
    _ = &results;
    wasm_valtype_vec_new(&params, 3, @ptrCast(@alignCast(&ps)));
    wasm_valtype_vec_new(&results, 2, @ptrCast(@alignCast(&rs)));
    return wasm_functype_new(&params, &results);
}
pub fn wasm_val_init_ptr(arg_out: [*c]wasm_val_t, arg_p: ?*anyopaque) callconv(.c) void {
    var out = arg_out;
    _ = &out;
    var p = arg_p;
    _ = &p;
    out.*.kind = WASM_I64;
    out.*.of.i64 = @intCast(@intFromPtr(p));
}
pub fn wasm_val_ptr(arg_val: [*c]const wasm_val_t) callconv(.c) ?*anyopaque {
    var val = arg_val;
    _ = &val;
    return @ptrFromInt(@as(usize, @intCast(val.*.of.i64)));
}
pub const struct_wasi_config_t = opaque {
    pub const wasi_config_delete = __root.wasi_config_delete;
    pub const wasi_config_inherit_network = __root.wasi_config_inherit_network;
    pub const wasi_config_allow_ip_name_lookup = __root.wasi_config_allow_ip_name_lookup;
    pub const wasi_config_set_argv = __root.wasi_config_set_argv;
    pub const wasi_config_inherit_argv = __root.wasi_config_inherit_argv;
    pub const wasi_config_set_env = __root.wasi_config_set_env;
    pub const wasi_config_inherit_env = __root.wasi_config_inherit_env;
    pub const wasi_config_set_stdin_file = __root.wasi_config_set_stdin_file;
    pub const wasi_config_set_stdin_bytes = __root.wasi_config_set_stdin_bytes;
    pub const wasi_config_inherit_stdin = __root.wasi_config_inherit_stdin;
    pub const wasi_config_set_stdout_file = __root.wasi_config_set_stdout_file;
    pub const wasi_config_inherit_stdout = __root.wasi_config_inherit_stdout;
    pub const wasi_config_set_stdout_custom = __root.wasi_config_set_stdout_custom;
    pub const wasi_config_set_stderr_file = __root.wasi_config_set_stderr_file;
    pub const wasi_config_inherit_stderr = __root.wasi_config_inherit_stderr;
    pub const wasi_config_set_stderr_custom = __root.wasi_config_set_stderr_custom;
    pub const wasi_config_preopen_dir = __root.wasi_config_preopen_dir;
    pub const delete = __root.wasi_config_delete;
    pub const network = __root.wasi_config_inherit_network;
    pub const lookup = __root.wasi_config_allow_ip_name_lookup;
    pub const argv = __root.wasi_config_set_argv;
    pub const env = __root.wasi_config_set_env;
    pub const file = __root.wasi_config_set_stdin_file;
    pub const bytes = __root.wasi_config_set_stdin_bytes;
    pub const stdin = __root.wasi_config_inherit_stdin;
    pub const stdout = __root.wasi_config_inherit_stdout;
    pub const custom = __root.wasi_config_set_stdout_custom;
    pub const stderr = __root.wasi_config_inherit_stderr;
    pub const dir = __root.wasi_config_preopen_dir;
};
pub const wasi_config_t = struct_wasi_config_t;
pub extern fn wasi_config_delete(?*wasi_config_t) void;
pub extern fn wasi_config_new(...) ?*wasi_config_t;
pub extern fn wasi_config_inherit_network(config: ?*wasi_config_t) void;
pub extern fn wasi_config_allow_ip_name_lookup(config: ?*wasi_config_t, enable: bool) void;
pub extern fn wasi_config_set_argv(config: ?*wasi_config_t, argc: usize, argv: [*c][*c]const u8) bool;
pub extern fn wasi_config_inherit_argv(config: ?*wasi_config_t) void;
pub extern fn wasi_config_set_env(config: ?*wasi_config_t, envc: usize, names: [*c][*c]const u8, values: [*c][*c]const u8) bool;
pub extern fn wasi_config_inherit_env(config: ?*wasi_config_t) void;
pub extern fn wasi_config_set_stdin_file(config: ?*wasi_config_t, path: [*c]const u8) bool;
pub extern fn wasi_config_set_stdin_bytes(config: ?*wasi_config_t, binary: [*c]wasm_byte_vec_t) void;
pub extern fn wasi_config_inherit_stdin(config: ?*wasi_config_t) void;
pub extern fn wasi_config_set_stdout_file(config: ?*wasi_config_t, path: [*c]const u8) bool;
pub extern fn wasi_config_inherit_stdout(config: ?*wasi_config_t) void;
pub extern fn wasi_config_set_stdout_custom(config: ?*wasi_config_t, callback: ?*const fn (?*anyopaque, [*c]const u8, usize) callconv(.c) ptrdiff_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) void;
pub extern fn wasi_config_set_stderr_file(config: ?*wasi_config_t, path: [*c]const u8) bool;
pub extern fn wasi_config_inherit_stderr(config: ?*wasi_config_t) void;
pub extern fn wasi_config_set_stderr_custom(config: ?*wasi_config_t, callback: ?*const fn (?*anyopaque, [*c]const u8, usize) callconv(.c) ptrdiff_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) void;
pub const wasi_file_perms = usize;
pub extern fn wasi_config_preopen_dir(config: ?*wasi_config_t, host_path: [*c]const u8, guest_path: [*c]const u8, fs_mutable: bool) bool;
pub const wasmtime_storage_type_kind_t = u8;
pub const struct_wasmtime_storage_type = extern struct {
    kind: wasmtime_storage_type_kind_t,
    valtype: ?*wasm_valtype_t,
    pub const wasmtime_storage_type_clone = __root.wasmtime_storage_type_clone;
    pub const wasmtime_storage_type_delete = __root.wasmtime_storage_type_delete;
    pub const clone = __root.wasmtime_storage_type_clone;
    pub const delete = __root.wasmtime_storage_type_delete;
};
pub const wasmtime_storage_type_t = struct_wasmtime_storage_type;
pub extern fn wasmtime_storage_type_clone(storage: [*c]const wasmtime_storage_type_t, out: [*c]wasmtime_storage_type_t) void;
pub extern fn wasmtime_storage_type_delete(storage: [*c]wasmtime_storage_type_t) void;
pub const struct_wasmtime_field_type = extern struct {
    mutable_: bool,
    storage: wasmtime_storage_type_t,
    pub const wasmtime_field_type_clone = __root.wasmtime_field_type_clone;
    pub const wasmtime_field_type_delete = __root.wasmtime_field_type_delete;
    pub const clone = __root.wasmtime_field_type_clone;
    pub const delete = __root.wasmtime_field_type_delete;
};
pub const wasmtime_field_type_t = struct_wasmtime_field_type;
pub extern fn wasmtime_field_type_clone(field: [*c]const wasmtime_field_type_t, out: [*c]wasmtime_field_type_t) void;
pub extern fn wasmtime_field_type_delete(field: [*c]wasmtime_field_type_t) void;
pub const struct_wasmtime_struct_type = opaque {
    pub const wasmtime_struct_type_copy = __root.wasmtime_struct_type_copy;
    pub const wasmtime_struct_type_delete = __root.wasmtime_struct_type_delete;
    pub const wasmtime_struct_type_num_fields = __root.wasmtime_struct_type_num_fields;
    pub const wasmtime_struct_type_field = __root.wasmtime_struct_type_field;
    pub const copy = __root.wasmtime_struct_type_copy;
    pub const delete = __root.wasmtime_struct_type_delete;
    pub const num_fields = __root.wasmtime_struct_type_num_fields;
    pub const field = __root.wasmtime_struct_type_field;
};
pub const wasmtime_struct_type_t = struct_wasmtime_struct_type;
pub extern fn wasmtime_struct_type_new(engine: ?*const wasm_engine_t, fields: [*c]const wasmtime_field_type_t, nfields: usize) ?*wasmtime_struct_type_t;
pub extern fn wasmtime_struct_type_copy(ty: ?*const wasmtime_struct_type_t) ?*wasmtime_struct_type_t;
pub extern fn wasmtime_struct_type_delete(ty: ?*wasmtime_struct_type_t) void;
pub extern fn wasmtime_struct_type_num_fields(ty: ?*const wasmtime_struct_type_t) usize;
pub extern fn wasmtime_struct_type_field(ty: ?*const wasmtime_struct_type_t, index: usize, out: [*c]wasmtime_field_type_t) bool;
pub const struct_wasmtime_array_type = opaque {
    pub const wasmtime_array_type_copy = __root.wasmtime_array_type_copy;
    pub const wasmtime_array_type_delete = __root.wasmtime_array_type_delete;
    pub const wasmtime_array_type_element = __root.wasmtime_array_type_element;
    pub const copy = __root.wasmtime_array_type_copy;
    pub const delete = __root.wasmtime_array_type_delete;
    pub const element = __root.wasmtime_array_type_element;
};
pub const wasmtime_array_type_t = struct_wasmtime_array_type;
pub extern fn wasmtime_array_type_new(engine: ?*const wasm_engine_t, field: [*c]const wasmtime_field_type_t) ?*wasmtime_array_type_t;
pub extern fn wasmtime_array_type_copy(ty: ?*const wasmtime_array_type_t) ?*wasmtime_array_type_t;
pub extern fn wasmtime_array_type_delete(ty: ?*wasmtime_array_type_t) void;
pub extern fn wasmtime_array_type_element(ty: ?*const wasmtime_array_type_t, out: [*c]wasmtime_field_type_t) void;
pub const struct_wasmtime_error = opaque {
    pub const wasmtime_error_delete = __root.wasmtime_error_delete;
    pub const wasmtime_error_message = __root.wasmtime_error_message;
    pub const wasmtime_error_exit_status = __root.wasmtime_error_exit_status;
    pub const wasmtime_error_wasm_trace = __root.wasmtime_error_wasm_trace;
    pub const delete = __root.wasmtime_error_delete;
    pub const message = __root.wasmtime_error_message;
    pub const exit_status = __root.wasmtime_error_exit_status;
    pub const wasm_trace = __root.wasmtime_error_wasm_trace;
};
pub const wasmtime_error_t = struct_wasmtime_error;
pub extern fn wasmtime_error_new([*c]const u8) ?*wasmtime_error_t;
pub extern fn wasmtime_error_delete(@"error": ?*wasmtime_error_t) void;
pub extern fn wasmtime_error_message(@"error": ?*const wasmtime_error_t, message: [*c]wasm_name_t) void;
pub extern fn wasmtime_error_exit_status(?*const wasmtime_error_t, status: [*c]c_int) bool;
pub extern fn wasmtime_error_wasm_trace(?*const wasmtime_error_t, out: [*c]wasm_frame_vec_t) void;
pub const struct_wasmtime_exn_type = opaque {
    pub const wasmtime_exn_type_delete = __root.wasmtime_exn_type_delete;
    pub const wasmtime_exn_type_copy = __root.wasmtime_exn_type_copy;
    pub const wasmtime_exn_type_tag_type = __root.wasmtime_exn_type_tag_type;
    pub const delete = __root.wasmtime_exn_type_delete;
    pub const copy = __root.wasmtime_exn_type_copy;
    pub const tag_type = __root.wasmtime_exn_type_tag_type;
};
pub const wasmtime_exn_type_t = struct_wasmtime_exn_type;
pub extern fn wasmtime_exn_type_new(engine: ?*const wasm_engine_t, params: [*c]const wasm_valtype_vec_t, out: [*c]?*wasmtime_exn_type_t) ?*wasmtime_error_t;
pub extern fn wasmtime_exn_type_delete(ty: ?*wasmtime_exn_type_t) void;
pub extern fn wasmtime_exn_type_copy(ty: ?*const wasmtime_exn_type_t) ?*wasmtime_exn_type_t;
pub extern fn wasmtime_exn_type_tag_type(ty: ?*const wasmtime_exn_type_t) ?*wasm_tagtype_t;
pub extern fn wasmtime_wasm_valtype_v128() ?*wasm_valtype_t;
pub extern fn wasmtime_wasm_valtype_equal(a: ?*const wasm_valtype_t, b: ?*const wasm_valtype_t) bool;
pub const wasmtime_heaptype_kind_t = u8;
pub const union_wasmtime_heaptype_union = extern union {
    concrete_func: ?*wasm_functype_t,
    concrete_array: ?*wasmtime_array_type_t,
    concrete_struct: ?*wasmtime_struct_type_t,
    concrete_exn: ?*wasmtime_exn_type_t,
};
pub const wasmtime_heaptype_union_t = union_wasmtime_heaptype_union;
pub const struct_wasmtime_heaptype = extern struct {
    kind: wasmtime_heaptype_kind_t,
    of: wasmtime_heaptype_union_t,
    pub const wasmtime_heaptype_clone = __root.wasmtime_heaptype_clone;
    pub const wasmtime_heaptype_delete = __root.wasmtime_heaptype_delete;
    pub const clone = __root.wasmtime_heaptype_clone;
    pub const delete = __root.wasmtime_heaptype_delete;
};
pub const wasmtime_heaptype_t = struct_wasmtime_heaptype;
pub extern fn wasmtime_heaptype_clone(ty: [*c]const wasmtime_heaptype_t, out: [*c]wasmtime_heaptype_t) void;
pub extern fn wasmtime_heaptype_delete(ty: [*c]wasmtime_heaptype_t) void;
pub const struct_wasmtime_reftype = extern struct {
    nullable: bool,
    heaptype: wasmtime_heaptype_t,
    pub const wasmtime_reftype_clone = __root.wasmtime_reftype_clone;
    pub const wasmtime_reftype_delete = __root.wasmtime_reftype_delete;
    pub const clone = __root.wasmtime_reftype_clone;
    pub const delete = __root.wasmtime_reftype_delete;
};
pub const wasmtime_reftype_t = struct_wasmtime_reftype;
pub extern fn wasmtime_reftype_clone(ty: [*c]const wasmtime_reftype_t, out: [*c]wasmtime_reftype_t) void;
pub extern fn wasmtime_reftype_delete(ty: [*c]wasmtime_reftype_t) void;
pub const wasmtime_valtype_kind_t = u8;
pub const struct_wasmtime_valtype = extern struct {
    kind: wasmtime_valtype_kind_t,
    reftype: wasmtime_reftype_t,
    pub const wasmtime_valtype_clone = __root.wasmtime_valtype_clone;
    pub const wasmtime_valtype_delete = __root.wasmtime_valtype_delete;
    pub const clone = __root.wasmtime_valtype_clone;
    pub const delete = __root.wasmtime_valtype_delete;
};
pub const wasmtime_valtype_t = struct_wasmtime_valtype;
pub extern fn wasmtime_valtype_new(ty: ?*const wasm_valtype_t, out: [*c]wasmtime_valtype_t) void;
pub extern fn wasmtime_valtype_clone(ty: [*c]const wasmtime_valtype_t, out: [*c]wasmtime_valtype_t) void;
pub extern fn wasmtime_valtype_delete(ty: [*c]wasmtime_valtype_t) void;
pub extern fn wasmtime_valtype_to_wasm(engine: ?*const wasm_engine_t, ty: [*c]const wasmtime_valtype_t) ?*wasm_valtype_t;
pub const struct_wasmtime_module = opaque {
    pub const wasmtime_module_delete = __root.wasmtime_module_delete;
    pub const wasmtime_module_clone = __root.wasmtime_module_clone;
    pub const wasmtime_module_imports = __root.wasmtime_module_imports;
    pub const wasmtime_module_exports = __root.wasmtime_module_exports;
    pub const wasmtime_module_serialize = __root.wasmtime_module_serialize;
    pub const wasmtime_module_image_range = __root.wasmtime_module_image_range;
    pub const delete = __root.wasmtime_module_delete;
    pub const clone = __root.wasmtime_module_clone;
    pub const imports = __root.wasmtime_module_imports;
    pub const exports = __root.wasmtime_module_exports;
    pub const serialize = __root.wasmtime_module_serialize;
    pub const image_range = __root.wasmtime_module_image_range;
};
pub const wasmtime_module_t = struct_wasmtime_module;
pub extern fn wasmtime_module_new(engine: ?*wasm_engine_t, wasm: [*c]const u8, wasm_len: usize, ret: [*c]?*wasmtime_module_t) ?*wasmtime_error_t;
pub extern fn wasmtime_module_delete(m: ?*wasmtime_module_t) void;
pub extern fn wasmtime_module_clone(m: ?*const wasmtime_module_t) ?*wasmtime_module_t;
pub extern fn wasmtime_module_imports(module: ?*const wasmtime_module_t, out: [*c]wasm_importtype_vec_t) void;
pub extern fn wasmtime_module_exports(module: ?*const wasmtime_module_t, out: [*c]wasm_exporttype_vec_t) void;
pub extern fn wasmtime_module_validate(engine: ?*wasm_engine_t, wasm: [*c]const u8, wasm_len: usize) ?*wasmtime_error_t;
pub extern fn wasmtime_module_serialize(module: ?*const wasmtime_module_t, ret: [*c]wasm_byte_vec_t) ?*wasmtime_error_t;
pub extern fn wasmtime_module_deserialize(engine: ?*wasm_engine_t, bytes: [*c]const u8, bytes_len: usize, ret: [*c]?*wasmtime_module_t) ?*wasmtime_error_t;
pub extern fn wasmtime_module_deserialize_file(engine: ?*wasm_engine_t, path: [*c]const u8, ret: [*c]?*wasmtime_module_t) ?*wasmtime_error_t;
pub extern fn wasmtime_module_image_range(module: ?*const wasmtime_module_t, start: [*c]?*anyopaque, end: [*c]?*anyopaque) void;
pub const struct_wasmtime_sharedmemory = opaque {
    pub const wasmtime_sharedmemory_delete = __root.wasmtime_sharedmemory_delete;
    pub const wasmtime_sharedmemory_clone = __root.wasmtime_sharedmemory_clone;
    pub const wasmtime_sharedmemory_type = __root.wasmtime_sharedmemory_type;
    pub const wasmtime_sharedmemory_data = __root.wasmtime_sharedmemory_data;
    pub const wasmtime_sharedmemory_data_size = __root.wasmtime_sharedmemory_data_size;
    pub const wasmtime_sharedmemory_size = __root.wasmtime_sharedmemory_size;
    pub const wasmtime_sharedmemory_grow = __root.wasmtime_sharedmemory_grow;
    pub const delete = __root.wasmtime_sharedmemory_delete;
    pub const clone = __root.wasmtime_sharedmemory_clone;
    pub const @"type" = __root.wasmtime_sharedmemory_type;
    pub const data = __root.wasmtime_sharedmemory_data;
    pub const data_size = __root.wasmtime_sharedmemory_data_size;
    pub const size = __root.wasmtime_sharedmemory_size;
    pub const grow = __root.wasmtime_sharedmemory_grow;
};
pub const wasmtime_sharedmemory_t = struct_wasmtime_sharedmemory;
pub extern fn wasmtime_sharedmemory_new(engine: ?*const wasm_engine_t, ty: ?*const wasm_memorytype_t, ret: [*c]?*wasmtime_sharedmemory_t) ?*wasmtime_error_t;
pub extern fn wasmtime_sharedmemory_delete(memory: ?*wasmtime_sharedmemory_t) void;
pub extern fn wasmtime_sharedmemory_clone(memory: ?*const wasmtime_sharedmemory_t) ?*wasmtime_sharedmemory_t;
pub extern fn wasmtime_sharedmemory_type(memory: ?*const wasmtime_sharedmemory_t) ?*wasm_memorytype_t;
pub extern fn wasmtime_sharedmemory_data(memory: ?*const wasmtime_sharedmemory_t) [*c]u8;
pub extern fn wasmtime_sharedmemory_data_size(memory: ?*const wasmtime_sharedmemory_t) usize;
pub extern fn wasmtime_sharedmemory_size(memory: ?*const wasmtime_sharedmemory_t) u64;
pub extern fn wasmtime_sharedmemory_grow(memory: ?*const wasmtime_sharedmemory_t, delta: u64, prev_size: [*c]u64) ?*wasmtime_error_t;
pub const struct_wasmtime_store = opaque {
    pub const wasmtime_store_context = __root.wasmtime_store_context;
    pub const wasmtime_store_limiter = __root.wasmtime_store_limiter;
    pub const wasmtime_store_delete = __root.wasmtime_store_delete;
    pub const wasmtime_store_epoch_deadline_callback = __root.wasmtime_store_epoch_deadline_callback;
    pub const context = __root.wasmtime_store_context;
    pub const limiter = __root.wasmtime_store_limiter;
    pub const delete = __root.wasmtime_store_delete;
    pub const epoch_deadline_callback = __root.wasmtime_store_epoch_deadline_callback;
};
pub const wasmtime_store_t = struct_wasmtime_store;
pub const struct_wasmtime_context = opaque {
    pub const wasmtime_context_get_data = __root.wasmtime_context_get_data;
    pub const wasmtime_context_set_data = __root.wasmtime_context_set_data;
    pub const wasmtime_context_gc = __root.wasmtime_context_gc;
    pub const wasmtime_context_set_fuel = __root.wasmtime_context_set_fuel;
    pub const wasmtime_context_get_fuel = __root.wasmtime_context_get_fuel;
    pub const wasmtime_context_set_wasi = __root.wasmtime_context_set_wasi;
    pub const wasmtime_context_set_wasi_http = __root.wasmtime_context_set_wasi_http;
    pub const wasmtime_context_set_epoch_deadline = __root.wasmtime_context_set_epoch_deadline;
    pub const wasmtime_tag_new = __root.wasmtime_tag_new;
    pub const wasmtime_tag_type = __root.wasmtime_tag_type;
    pub const wasmtime_tag_eq = __root.wasmtime_tag_eq;
    pub const wasmtime_extern_type = __root.wasmtime_extern_type;
    pub const wasmtime_anyref_from_raw = __root.wasmtime_anyref_from_raw;
    pub const wasmtime_anyref_to_raw = __root.wasmtime_anyref_to_raw;
    pub const wasmtime_anyref_from_i31 = __root.wasmtime_anyref_from_i31;
    pub const wasmtime_anyref_is_i31 = __root.wasmtime_anyref_is_i31;
    pub const wasmtime_anyref_i31_get_u = __root.wasmtime_anyref_i31_get_u;
    pub const wasmtime_anyref_i31_get_s = __root.wasmtime_anyref_i31_get_s;
    pub const wasmtime_anyref_is_eqref = __root.wasmtime_anyref_is_eqref;
    pub const wasmtime_anyref_as_eqref = __root.wasmtime_anyref_as_eqref;
    pub const wasmtime_anyref_is_struct = __root.wasmtime_anyref_is_struct;
    pub const wasmtime_anyref_as_struct = __root.wasmtime_anyref_as_struct;
    pub const wasmtime_anyref_is_array = __root.wasmtime_anyref_is_array;
    pub const wasmtime_anyref_as_array = __root.wasmtime_anyref_as_array;
    pub const wasmtime_anyref_type = __root.wasmtime_anyref_type;
    pub const wasmtime_array_ref_pre_new = __root.wasmtime_array_ref_pre_new;
    pub const wasmtime_arrayref_new = __root.wasmtime_arrayref_new;
    pub const wasmtime_arrayref_len = __root.wasmtime_arrayref_len;
    pub const wasmtime_arrayref_get = __root.wasmtime_arrayref_get;
    pub const wasmtime_arrayref_set = __root.wasmtime_arrayref_set;
    pub const wasmtime_arrayref_type = __root.wasmtime_arrayref_type;
    pub const wasmtime_func_new = __root.wasmtime_func_new;
    pub const wasmtime_func_new_unchecked = __root.wasmtime_func_new_unchecked;
    pub const wasmtime_func_type = __root.wasmtime_func_type;
    pub const wasmtime_func_call = __root.wasmtime_func_call;
    pub const wasmtime_func_call_unchecked = __root.wasmtime_func_call_unchecked;
    pub const wasmtime_func_from_raw = __root.wasmtime_func_from_raw;
    pub const wasmtime_func_to_raw = __root.wasmtime_func_to_raw;
    pub const wasmtime_instance_new = __root.wasmtime_instance_new;
    pub const wasmtime_instance_export_get = __root.wasmtime_instance_export_get;
    pub const wasmtime_instance_export_nth = __root.wasmtime_instance_export_nth;
    pub const wasmtime_context_fuel_async_yield_interval = __root.wasmtime_context_fuel_async_yield_interval;
    pub const wasmtime_context_epoch_deadline_async_yield_and_update = __root.wasmtime_context_epoch_deadline_async_yield_and_update;
    pub const wasmtime_func_call_async = __root.wasmtime_func_call_async;
    pub const wasmtime_component_resource_any_drop = __root.wasmtime_component_resource_any_drop;
    pub const wasmtime_component_resource_any_to_host = __root.wasmtime_component_resource_any_to_host;
    pub const wasmtime_component_resource_host_to_any = __root.wasmtime_component_resource_host_to_any;
    pub const wasmtime_eqref_from_i31 = __root.wasmtime_eqref_from_i31;
    pub const wasmtime_eqref_is_i31 = __root.wasmtime_eqref_is_i31;
    pub const wasmtime_eqref_i31_get_u = __root.wasmtime_eqref_i31_get_u;
    pub const wasmtime_eqref_i31_get_s = __root.wasmtime_eqref_i31_get_s;
    pub const wasmtime_eqref_is_array = __root.wasmtime_eqref_is_array;
    pub const wasmtime_eqref_as_array = __root.wasmtime_eqref_as_array;
    pub const wasmtime_eqref_is_struct = __root.wasmtime_eqref_is_struct;
    pub const wasmtime_eqref_as_struct = __root.wasmtime_eqref_as_struct;
    pub const wasmtime_eqref_type = __root.wasmtime_eqref_type;
    pub const wasmtime_exnref_new = __root.wasmtime_exnref_new;
    pub const wasmtime_exnref_from_raw = __root.wasmtime_exnref_from_raw;
    pub const wasmtime_exnref_to_raw = __root.wasmtime_exnref_to_raw;
    pub const wasmtime_exnref_tag = __root.wasmtime_exnref_tag;
    pub const wasmtime_exnref_field_count = __root.wasmtime_exnref_field_count;
    pub const wasmtime_exnref_field = __root.wasmtime_exnref_field;
    pub const wasmtime_context_set_exception = __root.wasmtime_context_set_exception;
    pub const wasmtime_context_take_exception = __root.wasmtime_context_take_exception;
    pub const wasmtime_context_has_exception = __root.wasmtime_context_has_exception;
    pub const wasmtime_exnref_type = __root.wasmtime_exnref_type;
    pub const wasmtime_externref_new = __root.wasmtime_externref_new;
    pub const wasmtime_externref_data = __root.wasmtime_externref_data;
    pub const wasmtime_externref_from_raw = __root.wasmtime_externref_from_raw;
    pub const wasmtime_externref_to_raw = __root.wasmtime_externref_to_raw;
    pub const wasmtime_global_new = __root.wasmtime_global_new;
    pub const wasmtime_global_type = __root.wasmtime_global_type;
    pub const wasmtime_global_get = __root.wasmtime_global_get;
    pub const wasmtime_global_set = __root.wasmtime_global_set;
    pub const wasmtime_memory_new = __root.wasmtime_memory_new;
    pub const wasmtime_memory_type = __root.wasmtime_memory_type;
    pub const wasmtime_memory_data = __root.wasmtime_memory_data;
    pub const wasmtime_memory_data_size = __root.wasmtime_memory_data_size;
    pub const wasmtime_memory_size = __root.wasmtime_memory_size;
    pub const wasmtime_memory_grow = __root.wasmtime_memory_grow;
    pub const wasmtime_memory_page_size = __root.wasmtime_memory_page_size;
    pub const wasmtime_memory_page_size_log2 = __root.wasmtime_memory_page_size_log2;
    pub const wasmtime_struct_ref_pre_new = __root.wasmtime_struct_ref_pre_new;
    pub const wasmtime_structref_new = __root.wasmtime_structref_new;
    pub const wasmtime_structref_field = __root.wasmtime_structref_field;
    pub const wasmtime_structref_set_field = __root.wasmtime_structref_set_field;
    pub const wasmtime_structref_type = __root.wasmtime_structref_type;
    pub const wasmtime_table_new = __root.wasmtime_table_new;
    pub const wasmtime_table_type = __root.wasmtime_table_type;
    pub const wasmtime_table_get = __root.wasmtime_table_get;
    pub const wasmtime_table_set = __root.wasmtime_table_set;
    pub const wasmtime_table_size = __root.wasmtime_table_size;
    pub const wasmtime_table_grow = __root.wasmtime_table_grow;
    pub const get_data = __root.wasmtime_context_get_data;
    pub const set_data = __root.wasmtime_context_set_data;
    pub const gc = __root.wasmtime_context_gc;
    pub const set_fuel = __root.wasmtime_context_set_fuel;
    pub const get_fuel = __root.wasmtime_context_get_fuel;
    pub const set_wasi = __root.wasmtime_context_set_wasi;
    pub const set_wasi_http = __root.wasmtime_context_set_wasi_http;
    pub const set_epoch_deadline = __root.wasmtime_context_set_epoch_deadline;
    pub const new = __root.wasmtime_tag_new;
    pub const @"type" = __root.wasmtime_tag_type;
    pub const eq = __root.wasmtime_tag_eq;
    pub const raw = __root.wasmtime_anyref_from_raw;
    pub const @"i31" = __root.wasmtime_anyref_from_i31;
    pub const u = __root.wasmtime_anyref_i31_get_u;
    pub const s = __root.wasmtime_anyref_i31_get_s;
    pub const eqref = __root.wasmtime_anyref_is_eqref;
    pub const @"struct" = __root.wasmtime_anyref_is_struct;
    pub const array = __root.wasmtime_anyref_is_array;
    pub const len = __root.wasmtime_arrayref_len;
    pub const get = __root.wasmtime_arrayref_get;
    pub const set = __root.wasmtime_arrayref_set;
    pub const unchecked = __root.wasmtime_func_new_unchecked;
    pub const call = __root.wasmtime_func_call;
    pub const nth = __root.wasmtime_instance_export_nth;
    pub const fuel_async_yield_interval = __root.wasmtime_context_fuel_async_yield_interval;
    pub const epoch_deadline_async_yield_and_update = __root.wasmtime_context_epoch_deadline_async_yield_and_update;
    pub const async = __root.wasmtime_func_call_async;
    pub const drop = __root.wasmtime_component_resource_any_drop;
    pub const host = __root.wasmtime_component_resource_any_to_host;
    pub const any = __root.wasmtime_component_resource_host_to_any;
    pub const tag = __root.wasmtime_exnref_tag;
    pub const count = __root.wasmtime_exnref_field_count;
    pub const field = __root.wasmtime_exnref_field;
    pub const set_exception = __root.wasmtime_context_set_exception;
    pub const take_exception = __root.wasmtime_context_take_exception;
    pub const has_exception = __root.wasmtime_context_has_exception;
    pub const data = __root.wasmtime_externref_data;
    pub const size = __root.wasmtime_memory_data_size;
    pub const grow = __root.wasmtime_memory_grow;
    pub const log2 = __root.wasmtime_memory_page_size_log2;
};
pub const wasmtime_context_t = struct_wasmtime_context;
pub extern fn wasmtime_store_new(engine: ?*wasm_engine_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) ?*wasmtime_store_t;
pub extern fn wasmtime_store_context(store: ?*wasmtime_store_t) ?*wasmtime_context_t;
pub extern fn wasmtime_store_limiter(store: ?*wasmtime_store_t, memory_size: i64, table_elements: i64, instances: i64, tables: i64, memories: i64) void;
pub extern fn wasmtime_store_delete(store: ?*wasmtime_store_t) void;
pub extern fn wasmtime_context_get_data(context: ?*const wasmtime_context_t) ?*anyopaque;
pub extern fn wasmtime_context_set_data(context: ?*wasmtime_context_t, data: ?*anyopaque) void;
pub extern fn wasmtime_context_gc(context: ?*wasmtime_context_t) ?*wasmtime_error_t;
pub extern fn wasmtime_context_set_fuel(store: ?*wasmtime_context_t, fuel: u64) ?*wasmtime_error_t;
pub extern fn wasmtime_context_get_fuel(context: ?*const wasmtime_context_t, fuel: [*c]u64) ?*wasmtime_error_t;
pub extern fn wasmtime_context_set_wasi(context: ?*wasmtime_context_t, wasi: ?*wasi_config_t) ?*wasmtime_error_t;
pub extern fn wasmtime_context_set_wasi_http(context: ?*wasmtime_context_t) void;
pub extern fn wasmtime_context_set_epoch_deadline(context: ?*wasmtime_context_t, ticks_beyond_current: u64) void;
pub const wasmtime_update_deadline_kind_t = u8;
pub extern fn wasmtime_store_epoch_deadline_callback(store: ?*wasmtime_store_t, func: ?*const fn (context: ?*const wasmtime_context_t, data: ?*anyopaque, epoch_deadline_delta: [*c]u64, update_kind: [*c]wasmtime_update_deadline_kind_t) callconv(.c) ?*wasmtime_error_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) void;
const struct_unnamed_3 = extern struct {
    store_id: u64,
    __private1: u32,
};
pub const struct_wasmtime_tag = extern struct {
    unnamed_0: struct_unnamed_3,
    __private2: u32,
};
pub const wasmtime_tag_t = struct_wasmtime_tag;
pub extern fn wasmtime_tag_new(store: ?*wasmtime_context_t, tt: ?*const wasm_tagtype_t, ret: [*c]wasmtime_tag_t) ?*wasmtime_error_t;
pub extern fn wasmtime_tag_type(store: ?*const wasmtime_context_t, tag: [*c]const wasmtime_tag_t) ?*wasm_tagtype_t;
pub extern fn wasmtime_tag_eq(store: ?*const wasmtime_context_t, a: [*c]const wasmtime_tag_t, b: [*c]const wasmtime_tag_t) bool;
pub const struct_wasmtime_func = extern struct {
    store_id: u64,
    __private: ?*anyopaque,
    pub const wasmtime_funcref_set_null = __root.wasmtime_funcref_set_null;
    pub const wasmtime_funcref_is_null = __root.wasmtime_funcref_is_null;
    pub const @"null" = __root.wasmtime_funcref_set_null;
};
pub const wasmtime_func_t = struct_wasmtime_func;
const struct_unnamed_4 = extern struct {
    store_id: u64,
    __private1: u32,
};
pub const struct_wasmtime_table = extern struct {
    unnamed_0: struct_unnamed_4,
    __private2: u32,
};
pub const wasmtime_table_t = struct_wasmtime_table;
const struct_unnamed_5 = extern struct {
    store_id: u64,
    __private1: u32,
};
pub const struct_wasmtime_memory = extern struct {
    unnamed_0: struct_unnamed_5,
    __private2: u32,
};
pub const wasmtime_memory_t = struct_wasmtime_memory;
pub const struct_wasmtime_global = extern struct {
    store_id: u64,
    __private1: u32,
    __private2: u32,
    __private3: u32,
};
pub const wasmtime_global_t = struct_wasmtime_global;
pub const wasmtime_extern_kind_t = u8;
pub const union_wasmtime_extern_union = extern union {
    func: wasmtime_func_t,
    global: wasmtime_global_t,
    table: wasmtime_table_t,
    memory: wasmtime_memory_t,
    sharedmemory: ?*struct_wasmtime_sharedmemory,
    tag: wasmtime_tag_t,
};
pub const wasmtime_extern_union_t = union_wasmtime_extern_union;
pub const struct_wasmtime_extern = extern struct {
    kind: wasmtime_extern_kind_t,
    of: wasmtime_extern_union_t,
    pub const wasmtime_extern_delete = __root.wasmtime_extern_delete;
    pub const delete = __root.wasmtime_extern_delete;
};
pub const wasmtime_extern_t = struct_wasmtime_extern;
pub extern fn wasmtime_extern_delete(val: [*c]wasmtime_extern_t) void;
pub extern fn wasmtime_extern_type(context: ?*wasmtime_context_t, val: [*c]const wasmtime_extern_t) ?*wasm_externtype_t;
pub const wasmtime_valkind_t = u8;
pub const wasmtime_v128 = [16]u8;
pub const struct_wasmtime_anyref = extern struct {
    store_id: u64,
    __private1: u32,
    __private2: u32,
    __private3: ?*anyopaque,
    pub const wasmtime_anyref_set_null = __root.wasmtime_anyref_set_null;
    pub const wasmtime_anyref_is_null = __root.wasmtime_anyref_is_null;
    pub const wasmtime_anyref_clone = __root.wasmtime_anyref_clone;
    pub const wasmtime_anyref_unroot = __root.wasmtime_anyref_unroot;
    pub const set_null = __root.wasmtime_anyref_set_null;
    pub const is_null = __root.wasmtime_anyref_is_null;
    pub const clone = __root.wasmtime_anyref_clone;
    pub const unroot = __root.wasmtime_anyref_unroot;
};
pub const wasmtime_anyref_t = struct_wasmtime_anyref;
pub const struct_wasmtime_exnref = extern struct {
    store_id: u64,
    __private1: u32,
    __private2: u32,
    __private3: ?*anyopaque,
    pub const wasmtime_exnref_set_null = __root.wasmtime_exnref_set_null;
    pub const wasmtime_exnref_is_null = __root.wasmtime_exnref_is_null;
    pub const wasmtime_exnref_clone = __root.wasmtime_exnref_clone;
    pub const wasmtime_exnref_unroot = __root.wasmtime_exnref_unroot;
    pub const set_null = __root.wasmtime_exnref_set_null;
    pub const is_null = __root.wasmtime_exnref_is_null;
    pub const clone = __root.wasmtime_exnref_clone;
    pub const unroot = __root.wasmtime_exnref_unroot;
};
pub const wasmtime_exnref_t = struct_wasmtime_exnref;
pub const struct_wasmtime_externref = extern struct {
    store_id: u64,
    __private1: u32,
    __private2: u32,
    __private3: ?*anyopaque,
    pub const wasmtime_externref_set_null = __root.wasmtime_externref_set_null;
    pub const wasmtime_externref_is_null = __root.wasmtime_externref_is_null;
    pub const wasmtime_externref_clone = __root.wasmtime_externref_clone;
    pub const wasmtime_externref_unroot = __root.wasmtime_externref_unroot;
    pub const set_null = __root.wasmtime_externref_set_null;
    pub const is_null = __root.wasmtime_externref_is_null;
    pub const clone = __root.wasmtime_externref_clone;
    pub const unroot = __root.wasmtime_externref_unroot;
};
pub const wasmtime_externref_t = struct_wasmtime_externref;
pub const struct_wasmtime_eqref = extern struct {
    store_id: u64,
    __private1: u32,
    __private2: u32,
    __private3: ?*anyopaque,
    pub const wasmtime_eqref_set_null = __root.wasmtime_eqref_set_null;
    pub const wasmtime_eqref_is_null = __root.wasmtime_eqref_is_null;
    pub const wasmtime_eqref_clone = __root.wasmtime_eqref_clone;
    pub const wasmtime_eqref_unroot = __root.wasmtime_eqref_unroot;
    pub const wasmtime_eqref_to_anyref = __root.wasmtime_eqref_to_anyref;
    pub const set_null = __root.wasmtime_eqref_set_null;
    pub const is_null = __root.wasmtime_eqref_is_null;
    pub const clone = __root.wasmtime_eqref_clone;
    pub const unroot = __root.wasmtime_eqref_unroot;
    pub const to_anyref = __root.wasmtime_eqref_to_anyref;
};
pub const wasmtime_eqref_t = struct_wasmtime_eqref;
pub const struct_wasmtime_structref = extern struct {
    store_id: u64,
    __private1: u32,
    __private2: u32,
    __private3: ?*anyopaque,
    pub const wasmtime_structref_set_null = __root.wasmtime_structref_set_null;
    pub const wasmtime_structref_is_null = __root.wasmtime_structref_is_null;
    pub const wasmtime_structref_clone = __root.wasmtime_structref_clone;
    pub const wasmtime_structref_unroot = __root.wasmtime_structref_unroot;
    pub const wasmtime_structref_to_anyref = __root.wasmtime_structref_to_anyref;
    pub const wasmtime_structref_to_eqref = __root.wasmtime_structref_to_eqref;
    pub const set_null = __root.wasmtime_structref_set_null;
    pub const is_null = __root.wasmtime_structref_is_null;
    pub const clone = __root.wasmtime_structref_clone;
    pub const unroot = __root.wasmtime_structref_unroot;
    pub const to_anyref = __root.wasmtime_structref_to_anyref;
    pub const to_eqref = __root.wasmtime_structref_to_eqref;
};
pub const wasmtime_structref_t = struct_wasmtime_structref;
pub const struct_wasmtime_arrayref = extern struct {
    store_id: u64,
    __private1: u32,
    __private2: u32,
    __private3: ?*anyopaque,
    pub const wasmtime_arrayref_set_null = __root.wasmtime_arrayref_set_null;
    pub const wasmtime_arrayref_is_null = __root.wasmtime_arrayref_is_null;
    pub const wasmtime_arrayref_clone = __root.wasmtime_arrayref_clone;
    pub const wasmtime_arrayref_unroot = __root.wasmtime_arrayref_unroot;
    pub const wasmtime_arrayref_to_anyref = __root.wasmtime_arrayref_to_anyref;
    pub const wasmtime_arrayref_to_eqref = __root.wasmtime_arrayref_to_eqref;
    pub const set_null = __root.wasmtime_arrayref_set_null;
    pub const is_null = __root.wasmtime_arrayref_is_null;
    pub const clone = __root.wasmtime_arrayref_clone;
    pub const unroot = __root.wasmtime_arrayref_unroot;
    pub const to_anyref = __root.wasmtime_arrayref_to_anyref;
    pub const to_eqref = __root.wasmtime_arrayref_to_eqref;
};
pub const wasmtime_arrayref_t = struct_wasmtime_arrayref;
pub const union_wasmtime_valunion = extern union {
    i32: i32,
    i64: i64,
    f32: float32_t,
    f64: float64_t,
    anyref: wasmtime_anyref_t,
    externref: wasmtime_externref_t,
    exnref: wasmtime_exnref_t,
    funcref: wasmtime_func_t,
    v128: wasmtime_v128,
};
pub const wasmtime_valunion_t = union_wasmtime_valunion;
pub fn wasmtime_funcref_set_null(arg_func: [*c]wasmtime_func_t) callconv(.c) void {
    var func = arg_func;
    _ = &func;
    func.*.store_id = 0;
}
pub fn wasmtime_funcref_is_null(arg_func: [*c]const wasmtime_func_t) callconv(.c) bool {
    var func = arg_func;
    _ = &func;
    return func.*.store_id == @as(u64, 0);
}
pub const union_wasmtime_val_raw = extern union {
    i32: i32,
    i64: i64,
    f32: float32_t,
    f64: float64_t,
    v128: wasmtime_v128,
    anyref: u32,
    externref: u32,
    exnref: u32,
    funcref: ?*anyopaque,
};
pub const wasmtime_val_raw_t = union_wasmtime_val_raw;
pub fn __wasmtime_val_assertions() callconv(.c) void {
    comptime {
        if (!((@sizeOf(wasmtime_valunion_t) >= @as(c_ulong, 16)) and (@sizeOf(wasmtime_valunion_t) <= @as(c_ulong, 24)))) @compileError("static assertion failed \"should be 16 bytes plus a pointer large (plus alignment on some platforms)\"");
    }
    comptime {
        if (!(@alignOf(wasmtime_valunion_t) == @alignOf(u64))) @compileError("static assertion failed \"should be aligned to u64\"");
    }
    comptime {
        if (!(@sizeOf(wasmtime_val_raw_t) == @as(c_ulong, 16))) @compileError("static assertion failed \"should be 16 bytes large\"");
    }
    comptime {
        if (!(@alignOf(wasmtime_val_raw_t) == @alignOf(u64))) @compileError("static assertion failed \"should be aligned to u64\"");
    }
}
pub const struct_wasmtime_val = extern struct {
    kind: wasmtime_valkind_t,
    of: wasmtime_valunion_t,
    pub const wasmtime_val_unroot = __root.wasmtime_val_unroot;
    pub const wasmtime_val_clone = __root.wasmtime_val_clone;
    pub const unroot = __root.wasmtime_val_unroot;
    pub const clone = __root.wasmtime_val_clone;
};
pub const wasmtime_val_t = struct_wasmtime_val;
pub extern fn wasmtime_val_unroot(val: [*c]wasmtime_val_t) void;
pub extern fn wasmtime_val_clone(src: [*c]const wasmtime_val_t, dst: [*c]wasmtime_val_t) void;
pub fn wasmtime_anyref_set_null(arg_ref: [*c]wasmtime_anyref_t) callconv(.c) void {
    var ref = arg_ref;
    _ = &ref;
    ref.*.store_id = 0;
}
pub fn wasmtime_anyref_is_null(arg_ref: [*c]const wasmtime_anyref_t) callconv(.c) bool {
    var ref = arg_ref;
    _ = &ref;
    return ref.*.store_id == @as(u64, 0);
}
pub extern fn wasmtime_anyref_clone(anyref: [*c]const wasmtime_anyref_t, out: [*c]wasmtime_anyref_t) void;
pub extern fn wasmtime_anyref_unroot(ref: [*c]wasmtime_anyref_t) void;
pub extern fn wasmtime_anyref_from_raw(context: ?*wasmtime_context_t, raw: u32, out: [*c]wasmtime_anyref_t) void;
pub extern fn wasmtime_anyref_to_raw(context: ?*wasmtime_context_t, ref: [*c]const wasmtime_anyref_t) u32;
pub extern fn wasmtime_anyref_from_i31(context: ?*wasmtime_context_t, i31val: u32, out: [*c]wasmtime_anyref_t) void;
pub extern fn wasmtime_anyref_is_i31(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t) bool;
pub extern fn wasmtime_anyref_i31_get_u(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t, dst: [*c]u32) bool;
pub extern fn wasmtime_anyref_i31_get_s(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t, dst: [*c]i32) bool;
pub extern fn wasmtime_anyref_is_eqref(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t) bool;
pub extern fn wasmtime_anyref_as_eqref(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t, out: [*c]wasmtime_eqref_t) bool;
pub extern fn wasmtime_anyref_is_struct(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t) bool;
pub extern fn wasmtime_anyref_as_struct(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t, out: [*c]wasmtime_structref_t) bool;
pub extern fn wasmtime_anyref_is_array(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t) bool;
pub extern fn wasmtime_anyref_as_array(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t, out: [*c]wasmtime_arrayref_t) bool;
pub extern fn wasmtime_anyref_type(context: ?*wasmtime_context_t, anyref: [*c]const wasmtime_anyref_t, out: [*c]wasmtime_heaptype_t) bool;
pub const struct_wasmtime_array_ref_pre = opaque {
    pub const wasmtime_array_ref_pre_delete = __root.wasmtime_array_ref_pre_delete;
    pub const delete = __root.wasmtime_array_ref_pre_delete;
};
pub const wasmtime_array_ref_pre_t = struct_wasmtime_array_ref_pre;
pub extern fn wasmtime_array_ref_pre_new(context: ?*wasmtime_context_t, ty: ?*const wasmtime_array_type_t) ?*wasmtime_array_ref_pre_t;
pub extern fn wasmtime_array_ref_pre_delete(pre: ?*wasmtime_array_ref_pre_t) void;
pub fn wasmtime_arrayref_set_null(arg_ref: [*c]wasmtime_arrayref_t) callconv(.c) void {
    var ref = arg_ref;
    _ = &ref;
    ref.*.store_id = 0;
}
pub fn wasmtime_arrayref_is_null(arg_ref: [*c]const wasmtime_arrayref_t) callconv(.c) bool {
    var ref = arg_ref;
    _ = &ref;
    return ref.*.store_id == @as(u64, 0);
}
pub extern fn wasmtime_arrayref_new(context: ?*wasmtime_context_t, pre: ?*const wasmtime_array_ref_pre_t, elem: [*c]const wasmtime_val_t, len: u32, out: [*c]wasmtime_arrayref_t) ?*wasmtime_error_t;
pub extern fn wasmtime_arrayref_clone(arrayref: [*c]const wasmtime_arrayref_t, out: [*c]wasmtime_arrayref_t) void;
pub extern fn wasmtime_arrayref_unroot(ref: [*c]wasmtime_arrayref_t) void;
pub extern fn wasmtime_arrayref_to_anyref(arrayref: [*c]const wasmtime_arrayref_t, out: [*c]wasmtime_anyref_t) void;
pub extern fn wasmtime_arrayref_to_eqref(arrayref: [*c]const wasmtime_arrayref_t, out: [*c]wasmtime_eqref_t) void;
pub extern fn wasmtime_arrayref_len(context: ?*wasmtime_context_t, arrayref: [*c]const wasmtime_arrayref_t, out: [*c]u32) ?*wasmtime_error_t;
pub extern fn wasmtime_arrayref_get(context: ?*wasmtime_context_t, arrayref: [*c]const wasmtime_arrayref_t, index: u32, out: [*c]wasmtime_val_t) ?*wasmtime_error_t;
pub extern fn wasmtime_arrayref_set(context: ?*wasmtime_context_t, arrayref: [*c]const wasmtime_arrayref_t, index: u32, val: [*c]const wasmtime_val_t) ?*wasmtime_error_t;
pub extern fn wasmtime_arrayref_type(context: ?*wasmtime_context_t, arrayref: [*c]const wasmtime_arrayref_t) ?*wasmtime_array_type_t;
pub const wasmtime_strategy_t = u8;
pub const WASMTIME_STRATEGY_AUTO: c_int = 0;
pub const WASMTIME_STRATEGY_CRANELIFT: c_int = 1;
pub const WASMTIME_STRATEGY_WINCH: c_int = 2;
pub const enum_wasmtime_strategy_enum = c_uint;
pub const wasmtime_opt_level_t = u8;
pub const WASMTIME_OPT_LEVEL_NONE: c_int = 0;
pub const WASMTIME_OPT_LEVEL_SPEED: c_int = 1;
pub const WASMTIME_OPT_LEVEL_SPEED_AND_SIZE: c_int = 2;
pub const enum_wasmtime_opt_level_enum = c_uint;
pub const wasmtime_profiling_strategy_t = u8;
pub const WASMTIME_PROFILING_STRATEGY_NONE: c_int = 0;
pub const WASMTIME_PROFILING_STRATEGY_JITDUMP: c_int = 1;
pub const WASMTIME_PROFILING_STRATEGY_VTUNE: c_int = 2;
pub const WASMTIME_PROFILING_STRATEGY_PERFMAP: c_int = 3;
pub const enum_wasmtime_profiling_strategy_enum = c_uint;
pub const wasmtime_regalloc_algorithm_t = u8;
pub const WASMTIME_REGALLOC_BACKTRACKING: c_int = 0;
pub const WASMTIME_REGALLOC_SINGLE_PASS: c_int = 1;
pub const enum_wasmtime_regalloc_algorithm_enum = c_uint;
pub extern fn wasmtime_config_debug_info_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_consume_fuel_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_epoch_interruption_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_max_wasm_stack_set(?*wasm_config_t, usize) void;
pub extern fn wasmtime_config_wasm_threads_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_shared_memory_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_tail_call_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_reference_types_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_function_references_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_gc_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_gc_support_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_simd_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_relaxed_simd_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_relaxed_simd_deterministic_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_bulk_memory_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_multi_value_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_multi_memory_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_memory64_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_wide_arithmetic_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_branch_hinting_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_exceptions_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_custom_page_sizes_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_compact_imports_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_stack_switching_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_strategy_set(?*wasm_config_t, wasmtime_strategy_t) void;
pub extern fn wasmtime_config_parallel_compilation_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_cranelift_debug_verifier_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_cranelift_nan_canonicalization_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_cranelift_opt_level_set(?*wasm_config_t, wasmtime_opt_level_t) void;
pub extern fn wasmtime_config_cranelift_regalloc_algorithm_set(?*wasm_config_t, wasmtime_regalloc_algorithm_t) void;
pub extern fn wasmtime_config_profiler_set(?*wasm_config_t, wasmtime_profiling_strategy_t) void;
pub extern fn wasmtime_config_memory_may_move_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_memory_reservation_set(?*wasm_config_t, u64) void;
pub extern fn wasmtime_config_memory_guard_size_set(?*wasm_config_t, u64) void;
pub extern fn wasmtime_config_memory_reservation_for_growth_set(?*wasm_config_t, u64) void;
pub extern fn wasmtime_config_native_unwind_info_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_cache_config_load(?*wasm_config_t, [*c]const u8) ?*wasmtime_error_t;
pub extern fn wasmtime_config_target_set(?*wasm_config_t, [*c]const u8) ?*wasmtime_error_t;
pub extern fn wasmtime_config_cranelift_flag_enable(?*wasm_config_t, [*c]const u8) void;
pub extern fn wasmtime_config_cranelift_flag_set(?*wasm_config_t, key: [*c]const u8, value: [*c]const u8) void;
pub extern fn wasmtime_config_macos_use_mach_ports_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_signals_based_traps_set(?*wasm_config_t, bool) void;
pub const wasmtime_memory_get_callback_t = ?*const fn (env: ?*anyopaque, byte_size: [*c]usize, byte_capacity: [*c]usize) callconv(.c) [*c]u8;
pub const wasmtime_memory_grow_callback_t = ?*const fn (env: ?*anyopaque, new_size: usize) callconv(.c) ?*wasmtime_error_t;
pub const struct_wasmtime_linear_memory = extern struct {
    env: ?*anyopaque,
    get_memory: wasmtime_memory_get_callback_t,
    grow_memory: wasmtime_memory_grow_callback_t,
    finalizer: ?*const fn (?*anyopaque) callconv(.c) void,
};
pub const wasmtime_linear_memory_t = struct_wasmtime_linear_memory;
pub const wasmtime_new_memory_callback_t = ?*const fn (env: ?*anyopaque, ty: ?*const wasm_memorytype_t, minimum: usize, maximum: usize, reserved_size_in_bytes: usize, guard_size_in_bytes: usize, memory_ret: [*c]wasmtime_linear_memory_t) callconv(.c) ?*wasmtime_error_t;
pub const struct_wasmtime_memory_creator = extern struct {
    env: ?*anyopaque,
    new_memory: wasmtime_new_memory_callback_t,
    finalizer: ?*const fn (?*anyopaque) callconv(.c) void,
};
pub const wasmtime_memory_creator_t = struct_wasmtime_memory_creator;
pub extern fn wasmtime_config_host_memory_creator_set(?*wasm_config_t, [*c]wasmtime_memory_creator_t) void;
pub extern fn wasmtime_config_memory_init_cow_set(?*wasm_config_t, bool) void;
pub const struct_wasmtime_pooling_allocation_config_t = opaque {
    pub const wasmtime_pooling_allocation_config_delete = __root.wasmtime_pooling_allocation_config_delete;
    pub const wasmtime_pooling_allocation_config_max_unused_warm_slots_set = __root.wasmtime_pooling_allocation_config_max_unused_warm_slots_set;
    pub const wasmtime_pooling_allocation_config_decommit_batch_size_set = __root.wasmtime_pooling_allocation_config_decommit_batch_size_set;
    pub const wasmtime_pooling_allocation_config_async_stack_keep_resident_set = __root.wasmtime_pooling_allocation_config_async_stack_keep_resident_set;
    pub const wasmtime_pooling_allocation_config_linear_memory_keep_resident_set = __root.wasmtime_pooling_allocation_config_linear_memory_keep_resident_set;
    pub const wasmtime_pooling_allocation_config_table_keep_resident_set = __root.wasmtime_pooling_allocation_config_table_keep_resident_set;
    pub const wasmtime_pooling_allocation_config_total_component_instances_set = __root.wasmtime_pooling_allocation_config_total_component_instances_set;
    pub const wasmtime_pooling_allocation_config_max_component_instance_size_set = __root.wasmtime_pooling_allocation_config_max_component_instance_size_set;
    pub const wasmtime_pooling_allocation_config_max_core_instances_per_component_set = __root.wasmtime_pooling_allocation_config_max_core_instances_per_component_set;
    pub const wasmtime_pooling_allocation_config_max_memories_per_component_set = __root.wasmtime_pooling_allocation_config_max_memories_per_component_set;
    pub const wasmtime_pooling_allocation_config_max_tables_per_component_set = __root.wasmtime_pooling_allocation_config_max_tables_per_component_set;
    pub const wasmtime_pooling_allocation_config_total_memories_set = __root.wasmtime_pooling_allocation_config_total_memories_set;
    pub const wasmtime_pooling_allocation_config_total_tables_set = __root.wasmtime_pooling_allocation_config_total_tables_set;
    pub const wasmtime_pooling_allocation_config_total_stacks_set = __root.wasmtime_pooling_allocation_config_total_stacks_set;
    pub const wasmtime_pooling_allocation_config_total_core_instances_set = __root.wasmtime_pooling_allocation_config_total_core_instances_set;
    pub const wasmtime_pooling_allocation_config_max_core_instance_size_set = __root.wasmtime_pooling_allocation_config_max_core_instance_size_set;
    pub const wasmtime_pooling_allocation_config_max_tables_per_module_set = __root.wasmtime_pooling_allocation_config_max_tables_per_module_set;
    pub const wasmtime_pooling_allocation_config_table_elements_set = __root.wasmtime_pooling_allocation_config_table_elements_set;
    pub const wasmtime_pooling_allocation_config_max_memories_per_module_set = __root.wasmtime_pooling_allocation_config_max_memories_per_module_set;
    pub const wasmtime_pooling_allocation_config_max_memory_size_set = __root.wasmtime_pooling_allocation_config_max_memory_size_set;
    pub const wasmtime_pooling_allocation_config_total_gc_heaps_set = __root.wasmtime_pooling_allocation_config_total_gc_heaps_set;
    pub const delete = __root.wasmtime_pooling_allocation_config_delete;
    pub const set = __root.wasmtime_pooling_allocation_config_max_unused_warm_slots_set;
};
pub const wasmtime_pooling_allocation_config_t = struct_wasmtime_pooling_allocation_config_t;
pub extern fn wasmtime_pooling_allocation_config_new(...) ?*wasmtime_pooling_allocation_config_t;
pub extern fn wasmtime_pooling_allocation_config_delete(?*wasmtime_pooling_allocation_config_t) void;
pub extern fn wasmtime_pooling_allocation_config_max_unused_warm_slots_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_decommit_batch_size_set(?*wasmtime_pooling_allocation_config_t, usize) void;
pub extern fn wasmtime_pooling_allocation_config_async_stack_keep_resident_set(?*wasmtime_pooling_allocation_config_t, usize) void;
pub extern fn wasmtime_pooling_allocation_config_linear_memory_keep_resident_set(?*wasmtime_pooling_allocation_config_t, usize) void;
pub extern fn wasmtime_pooling_allocation_config_table_keep_resident_set(?*wasmtime_pooling_allocation_config_t, usize) void;
pub extern fn wasmtime_pooling_allocation_config_total_component_instances_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_max_component_instance_size_set(?*wasmtime_pooling_allocation_config_t, usize) void;
pub extern fn wasmtime_pooling_allocation_config_max_core_instances_per_component_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_max_memories_per_component_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_max_tables_per_component_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_total_memories_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_total_tables_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_total_stacks_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_total_core_instances_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_max_core_instance_size_set(?*wasmtime_pooling_allocation_config_t, usize) void;
pub extern fn wasmtime_pooling_allocation_config_max_tables_per_module_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_table_elements_set(?*wasmtime_pooling_allocation_config_t, usize) void;
pub extern fn wasmtime_pooling_allocation_config_max_memories_per_module_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_config_max_memory_size_set(?*wasmtime_pooling_allocation_config_t, usize) void;
pub extern fn wasmtime_pooling_allocation_config_total_gc_heaps_set(?*wasmtime_pooling_allocation_config_t, u32) void;
pub extern fn wasmtime_pooling_allocation_strategy_set(?*wasm_config_t, ?*const wasmtime_pooling_allocation_config_t) void;
pub extern fn wasmtime_config_wasm_component_model_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_concurrency_support_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_component_model_map_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_component_model_implements_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_component_model_canonical_names_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_component_model_accessors_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_component_model_async_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_component_model_more_async_builtins_set(?*wasm_config_t, bool) void;
pub extern fn wasmtime_config_wasm_component_model_async_stackful_set(?*wasm_config_t, bool) void;
pub const struct_wasmtime_caller = opaque {
    pub const wasmtime_caller_export_get = __root.wasmtime_caller_export_get;
    pub const wasmtime_caller_context = __root.wasmtime_caller_context;
    pub const export_get = __root.wasmtime_caller_export_get;
    pub const context = __root.wasmtime_caller_context;
};
pub const wasmtime_caller_t = struct_wasmtime_caller;
pub const wasmtime_func_callback_t = ?*const fn (env: ?*anyopaque, caller: ?*wasmtime_caller_t, args: [*c]const wasmtime_val_t, nargs: usize, results: [*c]wasmtime_val_t, nresults: usize) callconv(.c) ?*wasm_trap_t;
pub extern fn wasmtime_func_new(store: ?*wasmtime_context_t, @"type": ?*const wasm_functype_t, callback: wasmtime_func_callback_t, env: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void, ret: [*c]wasmtime_func_t) void;
pub const wasmtime_func_unchecked_callback_t = ?*const fn (env: ?*anyopaque, caller: ?*wasmtime_caller_t, args_and_results: [*c]wasmtime_val_raw_t, num_args_and_results: usize) callconv(.c) ?*wasm_trap_t;
pub extern fn wasmtime_func_new_unchecked(store: ?*wasmtime_context_t, @"type": ?*const wasm_functype_t, callback: wasmtime_func_unchecked_callback_t, env: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void, ret: [*c]wasmtime_func_t) void;
pub extern fn wasmtime_func_type(store: ?*const wasmtime_context_t, func: [*c]const wasmtime_func_t) ?*wasm_functype_t;
pub extern fn wasmtime_func_call(store: ?*wasmtime_context_t, func: [*c]const wasmtime_func_t, args: [*c]const wasmtime_val_t, nargs: usize, results: [*c]wasmtime_val_t, nresults: usize, trap: [*c]?*wasm_trap_t) ?*wasmtime_error_t;
pub extern fn wasmtime_func_call_unchecked(store: ?*wasmtime_context_t, func: [*c]const wasmtime_func_t, args_and_results: [*c]wasmtime_val_raw_t, args_and_results_len: usize, trap: [*c]?*wasm_trap_t) ?*wasmtime_error_t;
pub extern fn wasmtime_caller_export_get(caller: ?*wasmtime_caller_t, name: [*c]const u8, name_len: usize, item: [*c]wasmtime_extern_t) bool;
pub extern fn wasmtime_caller_context(caller: ?*wasmtime_caller_t) ?*wasmtime_context_t;
pub extern fn wasmtime_func_from_raw(context: ?*wasmtime_context_t, raw: ?*anyopaque, ret: [*c]wasmtime_func_t) void;
pub extern fn wasmtime_func_to_raw(context: ?*wasmtime_context_t, func: [*c]const wasmtime_func_t) ?*anyopaque;
pub const struct_wasmtime_instance = extern struct {
    store_id: u64,
    __private: usize,
};
pub const wasmtime_instance_t = struct_wasmtime_instance;
pub extern fn wasmtime_instance_new(store: ?*wasmtime_context_t, module: ?*const wasmtime_module_t, imports: [*c]const wasmtime_extern_t, nimports: usize, instance: [*c]wasmtime_instance_t, trap: [*c]?*wasm_trap_t) ?*wasmtime_error_t;
pub extern fn wasmtime_instance_export_get(store: ?*wasmtime_context_t, instance: [*c]const wasmtime_instance_t, name: [*c]const u8, name_len: usize, item: [*c]wasmtime_extern_t) bool;
pub extern fn wasmtime_instance_export_nth(store: ?*wasmtime_context_t, instance: [*c]const wasmtime_instance_t, index: usize, name: [*c][*c]u8, name_len: [*c]usize, item: [*c]wasmtime_extern_t) bool;
pub const struct_wasmtime_instance_pre = opaque {
    pub const wasmtime_instance_pre_delete = __root.wasmtime_instance_pre_delete;
    pub const wasmtime_instance_pre_instantiate = __root.wasmtime_instance_pre_instantiate;
    pub const wasmtime_instance_pre_module = __root.wasmtime_instance_pre_module;
    pub const wasmtime_instance_pre_instantiate_async = __root.wasmtime_instance_pre_instantiate_async;
    pub const delete = __root.wasmtime_instance_pre_delete;
    pub const instantiate = __root.wasmtime_instance_pre_instantiate;
    pub const module = __root.wasmtime_instance_pre_module;
    pub const instantiate_async = __root.wasmtime_instance_pre_instantiate_async;
};
pub const wasmtime_instance_pre_t = struct_wasmtime_instance_pre;
pub extern fn wasmtime_instance_pre_delete(instance_pre: ?*wasmtime_instance_pre_t) void;
pub extern fn wasmtime_instance_pre_instantiate(instance_pre: ?*const wasmtime_instance_pre_t, store: ?*wasmtime_context_t, instance: [*c]wasmtime_instance_t, trap_ptr: [*c]?*wasm_trap_t) ?*wasmtime_error_t;
pub extern fn wasmtime_instance_pre_module(instance_pre: ?*const wasmtime_instance_pre_t) ?*wasmtime_module_t;
pub const struct_wasmtime_linker = opaque {
    pub const wasmtime_linker_clone = __root.wasmtime_linker_clone;
    pub const wasmtime_linker_delete = __root.wasmtime_linker_delete;
    pub const wasmtime_linker_allow_shadowing = __root.wasmtime_linker_allow_shadowing;
    pub const wasmtime_linker_define_unknown_imports_as_traps = __root.wasmtime_linker_define_unknown_imports_as_traps;
    pub const wasmtime_linker_define_unknown_imports_as_default_values = __root.wasmtime_linker_define_unknown_imports_as_default_values;
    pub const wasmtime_linker_define = __root.wasmtime_linker_define;
    pub const wasmtime_linker_define_func = __root.wasmtime_linker_define_func;
    pub const wasmtime_linker_define_func_unchecked = __root.wasmtime_linker_define_func_unchecked;
    pub const wasmtime_linker_define_wasi = __root.wasmtime_linker_define_wasi;
    pub const wasmtime_linker_define_instance = __root.wasmtime_linker_define_instance;
    pub const wasmtime_linker_instantiate = __root.wasmtime_linker_instantiate;
    pub const wasmtime_linker_module = __root.wasmtime_linker_module;
    pub const wasmtime_linker_get_default = __root.wasmtime_linker_get_default;
    pub const wasmtime_linker_get = __root.wasmtime_linker_get;
    pub const wasmtime_linker_instantiate_pre = __root.wasmtime_linker_instantiate_pre;
    pub const wasmtime_linker_define_async_func = __root.wasmtime_linker_define_async_func;
    pub const wasmtime_linker_instantiate_async = __root.wasmtime_linker_instantiate_async;
    pub const clone = __root.wasmtime_linker_clone;
    pub const delete = __root.wasmtime_linker_delete;
    pub const allow_shadowing = __root.wasmtime_linker_allow_shadowing;
    pub const define_unknown_imports_as_traps = __root.wasmtime_linker_define_unknown_imports_as_traps;
    pub const define_unknown_imports_as_default_values = __root.wasmtime_linker_define_unknown_imports_as_default_values;
    pub const define = __root.wasmtime_linker_define;
    pub const define_func = __root.wasmtime_linker_define_func;
    pub const define_func_unchecked = __root.wasmtime_linker_define_func_unchecked;
    pub const define_wasi = __root.wasmtime_linker_define_wasi;
    pub const define_instance = __root.wasmtime_linker_define_instance;
    pub const instantiate = __root.wasmtime_linker_instantiate;
    pub const module = __root.wasmtime_linker_module;
    pub const get_default = __root.wasmtime_linker_get_default;
    pub const get = __root.wasmtime_linker_get;
    pub const instantiate_pre = __root.wasmtime_linker_instantiate_pre;
    pub const define_async_func = __root.wasmtime_linker_define_async_func;
    pub const instantiate_async = __root.wasmtime_linker_instantiate_async;
};
pub const wasmtime_linker_t = struct_wasmtime_linker;
pub extern fn wasmtime_linker_new(engine: ?*wasm_engine_t) ?*wasmtime_linker_t;
pub extern fn wasmtime_linker_clone(linker: ?*const wasmtime_linker_t) ?*wasmtime_linker_t;
pub extern fn wasmtime_linker_delete(linker: ?*wasmtime_linker_t) void;
pub extern fn wasmtime_linker_allow_shadowing(linker: ?*wasmtime_linker_t, allow_shadowing: bool) void;
pub extern fn wasmtime_linker_define_unknown_imports_as_traps(linker: ?*wasmtime_linker_t, module: ?*const wasmtime_module_t) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_define_unknown_imports_as_default_values(linker: ?*wasmtime_linker_t, store: ?*wasmtime_context_t, module: ?*const wasmtime_module_t) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_define(linker: ?*wasmtime_linker_t, store: ?*wasmtime_context_t, module: [*c]const u8, module_len: usize, name: [*c]const u8, name_len: usize, item: [*c]const wasmtime_extern_t) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_define_func(linker: ?*wasmtime_linker_t, module: [*c]const u8, module_len: usize, name: [*c]const u8, name_len: usize, ty: ?*const wasm_functype_t, cb: wasmtime_func_callback_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_define_func_unchecked(linker: ?*wasmtime_linker_t, module: [*c]const u8, module_len: usize, name: [*c]const u8, name_len: usize, ty: ?*const wasm_functype_t, cb: wasmtime_func_unchecked_callback_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_define_wasi(linker: ?*wasmtime_linker_t) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_define_instance(linker: ?*wasmtime_linker_t, store: ?*wasmtime_context_t, name: [*c]const u8, name_len: usize, instance: [*c]const wasmtime_instance_t) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_instantiate(linker: ?*const wasmtime_linker_t, store: ?*wasmtime_context_t, module: ?*const wasmtime_module_t, instance: [*c]wasmtime_instance_t, trap: [*c]?*wasm_trap_t) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_module(linker: ?*wasmtime_linker_t, store: ?*wasmtime_context_t, name: [*c]const u8, name_len: usize, module: ?*const wasmtime_module_t) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_get_default(linker: ?*const wasmtime_linker_t, store: ?*wasmtime_context_t, name: [*c]const u8, name_len: usize, func: [*c]wasmtime_func_t) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_get(linker: ?*const wasmtime_linker_t, store: ?*wasmtime_context_t, module: [*c]const u8, module_len: usize, name: [*c]const u8, name_len: usize, item: [*c]wasmtime_extern_t) bool;
pub extern fn wasmtime_linker_instantiate_pre(linker: ?*const wasmtime_linker_t, module: ?*const wasmtime_module_t, instance_pre: [*c]?*wasmtime_instance_pre_t) ?*wasmtime_error_t;
pub extern fn wasmtime_config_async_stack_size_set(?*wasm_config_t, usize) void;
pub extern fn wasmtime_context_fuel_async_yield_interval(context: ?*wasmtime_context_t, interval: u64) ?*wasmtime_error_t;
pub extern fn wasmtime_context_epoch_deadline_async_yield_and_update(context: ?*wasmtime_context_t, delta: u64) ?*wasmtime_error_t;
pub const wasmtime_func_async_continuation_callback_t = ?*const fn (env: ?*anyopaque) callconv(.c) bool;
pub const struct_wasmtime_async_continuation_t = extern struct {
    callback: wasmtime_func_async_continuation_callback_t,
    env: ?*anyopaque,
    finalizer: ?*const fn (?*anyopaque) callconv(.c) void,
};
pub const wasmtime_async_continuation_t = struct_wasmtime_async_continuation_t;
pub const wasmtime_func_async_callback_t = ?*const fn (env: ?*anyopaque, caller: ?*wasmtime_caller_t, args: [*c]const wasmtime_val_t, nargs: usize, results: [*c]wasmtime_val_t, nresults: usize, trap_ret: [*c]?*wasm_trap_t, continuation_ret: [*c]wasmtime_async_continuation_t) callconv(.c) void;
pub const struct_wasmtime_call_future = opaque {
    pub const wasmtime_call_future_poll = __root.wasmtime_call_future_poll;
    pub const wasmtime_call_future_delete = __root.wasmtime_call_future_delete;
    pub const poll = __root.wasmtime_call_future_poll;
    pub const delete = __root.wasmtime_call_future_delete;
};
pub const wasmtime_call_future_t = struct_wasmtime_call_future;
pub extern fn wasmtime_call_future_poll(future: ?*wasmtime_call_future_t) bool;
pub extern fn wasmtime_call_future_delete(future: ?*wasmtime_call_future_t) void;
pub extern fn wasmtime_func_call_async(context: ?*wasmtime_context_t, func: [*c]const wasmtime_func_t, args: [*c]const wasmtime_val_t, nargs: usize, results: [*c]wasmtime_val_t, nresults: usize, trap_ret: [*c]?*wasm_trap_t, error_ret: [*c]?*wasmtime_error_t) ?*wasmtime_call_future_t;
pub extern fn wasmtime_linker_define_async_func(linker: ?*wasmtime_linker_t, module: [*c]const u8, module_len: usize, name: [*c]const u8, name_len: usize, ty: ?*const wasm_functype_t, cb: wasmtime_func_async_callback_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) ?*wasmtime_error_t;
pub extern fn wasmtime_linker_instantiate_async(linker: ?*const wasmtime_linker_t, store: ?*wasmtime_context_t, module: ?*const wasmtime_module_t, instance: [*c]wasmtime_instance_t, trap_ret: [*c]?*wasm_trap_t, error_ret: [*c]?*wasmtime_error_t) ?*wasmtime_call_future_t;
pub extern fn wasmtime_instance_pre_instantiate_async(instance_pre: ?*const wasmtime_instance_pre_t, store: ?*wasmtime_context_t, instance: [*c]wasmtime_instance_t, trap_ret: [*c]?*wasm_trap_t, error_ret: [*c]?*wasmtime_error_t) ?*wasmtime_call_future_t;
pub const wasmtime_stack_memory_get_callback_t = ?*const fn (env: ?*anyopaque, out_len: [*c]usize) callconv(.c) [*c]u8;
pub const wasmtime_stack_memory_t = extern struct {
    env: ?*anyopaque,
    get_stack_memory: wasmtime_stack_memory_get_callback_t,
    finalizer: ?*const fn (?*anyopaque) callconv(.c) void,
};
pub const wasmtime_new_stack_memory_callback_t = ?*const fn (env: ?*anyopaque, size: usize, zeroed: bool, stack_ret: [*c]wasmtime_stack_memory_t) callconv(.c) ?*wasmtime_error_t;
pub const wasmtime_stack_creator_t = extern struct {
    env: ?*anyopaque,
    new_stack: wasmtime_new_stack_memory_callback_t,
    finalizer: ?*const fn (?*anyopaque) callconv(.c) void,
};
pub extern fn wasmtime_config_host_stack_creator_set(?*wasm_config_t, [*c]wasmtime_stack_creator_t) void;
pub const struct_wasmtime_component_resource_type = opaque {
    pub const wasmtime_component_resource_type_clone = __root.wasmtime_component_resource_type_clone;
    pub const wasmtime_component_resource_type_equal = __root.wasmtime_component_resource_type_equal;
    pub const wasmtime_component_resource_type_delete = __root.wasmtime_component_resource_type_delete;
    pub const clone = __root.wasmtime_component_resource_type_clone;
    pub const equal = __root.wasmtime_component_resource_type_equal;
    pub const delete = __root.wasmtime_component_resource_type_delete;
};
pub const wasmtime_component_resource_type_t = struct_wasmtime_component_resource_type;
pub extern fn wasmtime_component_resource_type_new_host(ty: u32) ?*wasmtime_component_resource_type_t;
pub extern fn wasmtime_component_resource_type_clone(ty: ?*const wasmtime_component_resource_type_t) ?*wasmtime_component_resource_type_t;
pub extern fn wasmtime_component_resource_type_equal(a: ?*const wasmtime_component_resource_type_t, b: ?*const wasmtime_component_resource_type_t) bool;
pub extern fn wasmtime_component_resource_type_delete(resource: ?*wasmtime_component_resource_type_t) void;
pub const wasmtime_component_valtype_kind_t = u8;
pub const struct_wasmtime_component_list_type = opaque {
    pub const wasmtime_component_list_type_clone = __root.wasmtime_component_list_type_clone;
    pub const wasmtime_component_list_type_equal = __root.wasmtime_component_list_type_equal;
    pub const wasmtime_component_list_type_delete = __root.wasmtime_component_list_type_delete;
    pub const wasmtime_component_list_type_element = __root.wasmtime_component_list_type_element;
    pub const clone = __root.wasmtime_component_list_type_clone;
    pub const equal = __root.wasmtime_component_list_type_equal;
    pub const delete = __root.wasmtime_component_list_type_delete;
    pub const element = __root.wasmtime_component_list_type_element;
};
pub const wasmtime_component_list_type_t = struct_wasmtime_component_list_type;
pub const struct_wasmtime_component_record_type = opaque {
    pub const wasmtime_component_record_type_clone = __root.wasmtime_component_record_type_clone;
    pub const wasmtime_component_record_type_equal = __root.wasmtime_component_record_type_equal;
    pub const wasmtime_component_record_type_delete = __root.wasmtime_component_record_type_delete;
    pub const wasmtime_component_record_type_field_count = __root.wasmtime_component_record_type_field_count;
    pub const wasmtime_component_record_type_field_nth = __root.wasmtime_component_record_type_field_nth;
    pub const clone = __root.wasmtime_component_record_type_clone;
    pub const equal = __root.wasmtime_component_record_type_equal;
    pub const delete = __root.wasmtime_component_record_type_delete;
    pub const field_count = __root.wasmtime_component_record_type_field_count;
    pub const field_nth = __root.wasmtime_component_record_type_field_nth;
};
pub const wasmtime_component_record_type_t = struct_wasmtime_component_record_type;
pub const struct_wasmtime_component_tuple_type = opaque {
    pub const wasmtime_component_tuple_type_clone = __root.wasmtime_component_tuple_type_clone;
    pub const wasmtime_component_tuple_type_equal = __root.wasmtime_component_tuple_type_equal;
    pub const wasmtime_component_tuple_type_delete = __root.wasmtime_component_tuple_type_delete;
    pub const wasmtime_component_tuple_type_types_count = __root.wasmtime_component_tuple_type_types_count;
    pub const wasmtime_component_tuple_type_types_nth = __root.wasmtime_component_tuple_type_types_nth;
    pub const clone = __root.wasmtime_component_tuple_type_clone;
    pub const equal = __root.wasmtime_component_tuple_type_equal;
    pub const delete = __root.wasmtime_component_tuple_type_delete;
    pub const types_count = __root.wasmtime_component_tuple_type_types_count;
    pub const types_nth = __root.wasmtime_component_tuple_type_types_nth;
};
pub const wasmtime_component_tuple_type_t = struct_wasmtime_component_tuple_type;
pub const struct_wasmtime_component_variant_type = opaque {
    pub const wasmtime_component_variant_type_clone = __root.wasmtime_component_variant_type_clone;
    pub const wasmtime_component_variant_type_equal = __root.wasmtime_component_variant_type_equal;
    pub const wasmtime_component_variant_type_delete = __root.wasmtime_component_variant_type_delete;
    pub const wasmtime_component_variant_type_case_count = __root.wasmtime_component_variant_type_case_count;
    pub const wasmtime_component_variant_type_case_nth = __root.wasmtime_component_variant_type_case_nth;
    pub const clone = __root.wasmtime_component_variant_type_clone;
    pub const equal = __root.wasmtime_component_variant_type_equal;
    pub const delete = __root.wasmtime_component_variant_type_delete;
    pub const case_count = __root.wasmtime_component_variant_type_case_count;
    pub const case_nth = __root.wasmtime_component_variant_type_case_nth;
};
pub const wasmtime_component_variant_type_t = struct_wasmtime_component_variant_type;
pub const struct_wasmtime_component_enum_type = opaque {
    pub const wasmtime_component_enum_type_clone = __root.wasmtime_component_enum_type_clone;
    pub const wasmtime_component_enum_type_equal = __root.wasmtime_component_enum_type_equal;
    pub const wasmtime_component_enum_type_delete = __root.wasmtime_component_enum_type_delete;
    pub const wasmtime_component_enum_type_names_count = __root.wasmtime_component_enum_type_names_count;
    pub const wasmtime_component_enum_type_names_nth = __root.wasmtime_component_enum_type_names_nth;
    pub const clone = __root.wasmtime_component_enum_type_clone;
    pub const equal = __root.wasmtime_component_enum_type_equal;
    pub const delete = __root.wasmtime_component_enum_type_delete;
    pub const names_count = __root.wasmtime_component_enum_type_names_count;
    pub const names_nth = __root.wasmtime_component_enum_type_names_nth;
};
pub const wasmtime_component_enum_type_t = struct_wasmtime_component_enum_type;
pub const struct_wasmtime_component_option_type = opaque {
    pub const wasmtime_component_option_type_clone = __root.wasmtime_component_option_type_clone;
    pub const wasmtime_component_option_type_equal = __root.wasmtime_component_option_type_equal;
    pub const wasmtime_component_option_type_delete = __root.wasmtime_component_option_type_delete;
    pub const wasmtime_component_option_type_ty = __root.wasmtime_component_option_type_ty;
    pub const clone = __root.wasmtime_component_option_type_clone;
    pub const equal = __root.wasmtime_component_option_type_equal;
    pub const delete = __root.wasmtime_component_option_type_delete;
    pub const ty = __root.wasmtime_component_option_type_ty;
};
pub const wasmtime_component_option_type_t = struct_wasmtime_component_option_type;
pub const struct_wasmtime_component_result_type = opaque {
    pub const wasmtime_component_result_type_clone = __root.wasmtime_component_result_type_clone;
    pub const wasmtime_component_result_type_equal = __root.wasmtime_component_result_type_equal;
    pub const wasmtime_component_result_type_delete = __root.wasmtime_component_result_type_delete;
    pub const wasmtime_component_result_type_ok = __root.wasmtime_component_result_type_ok;
    pub const wasmtime_component_result_type_err = __root.wasmtime_component_result_type_err;
    pub const clone = __root.wasmtime_component_result_type_clone;
    pub const equal = __root.wasmtime_component_result_type_equal;
    pub const delete = __root.wasmtime_component_result_type_delete;
    pub const ok = __root.wasmtime_component_result_type_ok;
    pub const err = __root.wasmtime_component_result_type_err;
};
pub const wasmtime_component_result_type_t = struct_wasmtime_component_result_type;
pub const struct_wasmtime_component_flags_type = opaque {
    pub const wasmtime_component_flags_type_clone = __root.wasmtime_component_flags_type_clone;
    pub const wasmtime_component_flags_type_equal = __root.wasmtime_component_flags_type_equal;
    pub const wasmtime_component_flags_type_delete = __root.wasmtime_component_flags_type_delete;
    pub const wasmtime_component_flags_type_names_count = __root.wasmtime_component_flags_type_names_count;
    pub const wasmtime_component_flags_type_names_nth = __root.wasmtime_component_flags_type_names_nth;
    pub const clone = __root.wasmtime_component_flags_type_clone;
    pub const equal = __root.wasmtime_component_flags_type_equal;
    pub const delete = __root.wasmtime_component_flags_type_delete;
    pub const names_count = __root.wasmtime_component_flags_type_names_count;
    pub const names_nth = __root.wasmtime_component_flags_type_names_nth;
};
pub const wasmtime_component_flags_type_t = struct_wasmtime_component_flags_type;
pub const struct_wasmtime_component_future_type = opaque {
    pub const wasmtime_component_future_type_clone = __root.wasmtime_component_future_type_clone;
    pub const wasmtime_component_future_type_equal = __root.wasmtime_component_future_type_equal;
    pub const wasmtime_component_future_type_delete = __root.wasmtime_component_future_type_delete;
    pub const wasmtime_component_future_type_ty = __root.wasmtime_component_future_type_ty;
    pub const clone = __root.wasmtime_component_future_type_clone;
    pub const equal = __root.wasmtime_component_future_type_equal;
    pub const delete = __root.wasmtime_component_future_type_delete;
    pub const ty = __root.wasmtime_component_future_type_ty;
};
pub const wasmtime_component_future_type_t = struct_wasmtime_component_future_type;
pub const struct_wasmtime_component_stream_type = opaque {
    pub const wasmtime_component_stream_type_clone = __root.wasmtime_component_stream_type_clone;
    pub const wasmtime_component_stream_type_equal = __root.wasmtime_component_stream_type_equal;
    pub const wasmtime_component_stream_type_delete = __root.wasmtime_component_stream_type_delete;
    pub const wasmtime_component_stream_type_ty = __root.wasmtime_component_stream_type_ty;
    pub const clone = __root.wasmtime_component_stream_type_clone;
    pub const equal = __root.wasmtime_component_stream_type_equal;
    pub const delete = __root.wasmtime_component_stream_type_delete;
    pub const ty = __root.wasmtime_component_stream_type_ty;
};
pub const wasmtime_component_stream_type_t = struct_wasmtime_component_stream_type;
pub const struct_wasmtime_component_map_type = opaque {
    pub const wasmtime_component_map_type_clone = __root.wasmtime_component_map_type_clone;
    pub const wasmtime_component_map_type_equal = __root.wasmtime_component_map_type_equal;
    pub const wasmtime_component_map_type_delete = __root.wasmtime_component_map_type_delete;
    pub const wasmtime_component_map_type_key = __root.wasmtime_component_map_type_key;
    pub const wasmtime_component_map_type_value = __root.wasmtime_component_map_type_value;
    pub const clone = __root.wasmtime_component_map_type_clone;
    pub const equal = __root.wasmtime_component_map_type_equal;
    pub const delete = __root.wasmtime_component_map_type_delete;
    pub const key = __root.wasmtime_component_map_type_key;
    pub const value = __root.wasmtime_component_map_type_value;
};
pub const wasmtime_component_map_type_t = struct_wasmtime_component_map_type;
pub const union_wasmtime_component_valtype_union = extern union {
    list: ?*wasmtime_component_list_type_t,
    record: ?*wasmtime_component_record_type_t,
    tuple: ?*wasmtime_component_tuple_type_t,
    variant: ?*wasmtime_component_variant_type_t,
    enum_: ?*wasmtime_component_enum_type_t,
    option: ?*wasmtime_component_option_type_t,
    result: ?*wasmtime_component_result_type_t,
    flags: ?*wasmtime_component_flags_type_t,
    own: ?*wasmtime_component_resource_type_t,
    borrow: ?*wasmtime_component_resource_type_t,
    future: ?*wasmtime_component_future_type_t,
    stream: ?*wasmtime_component_stream_type_t,
    map: ?*wasmtime_component_map_type_t,
};
pub const wasmtime_component_valtype_union_t = union_wasmtime_component_valtype_union;
pub const struct_wasmtime_component_valtype_t = extern struct {
    kind: wasmtime_component_valtype_kind_t,
    of: wasmtime_component_valtype_union_t,
    pub const wasmtime_component_valtype_clone = __root.wasmtime_component_valtype_clone;
    pub const wasmtime_component_valtype_equal = __root.wasmtime_component_valtype_equal;
    pub const wasmtime_component_valtype_delete = __root.wasmtime_component_valtype_delete;
    pub const clone = __root.wasmtime_component_valtype_clone;
    pub const equal = __root.wasmtime_component_valtype_equal;
    pub const delete = __root.wasmtime_component_valtype_delete;
};
pub extern fn wasmtime_component_list_type_clone(ty: ?*const wasmtime_component_list_type_t) ?*wasmtime_component_list_type_t;
pub extern fn wasmtime_component_list_type_equal(a: ?*const wasmtime_component_list_type_t, b: ?*const wasmtime_component_list_type_t) bool;
pub extern fn wasmtime_component_list_type_delete(ptr: ?*wasmtime_component_list_type_t) void;
pub extern fn wasmtime_component_list_type_element(ty: ?*const wasmtime_component_list_type_t, type_ret: [*c]struct_wasmtime_component_valtype_t) void;
pub extern fn wasmtime_component_record_type_clone(ty: ?*const wasmtime_component_record_type_t) ?*wasmtime_component_record_type_t;
pub extern fn wasmtime_component_record_type_equal(a: ?*const wasmtime_component_record_type_t, b: ?*const wasmtime_component_record_type_t) bool;
pub extern fn wasmtime_component_record_type_delete(ptr: ?*wasmtime_component_record_type_t) void;
pub extern fn wasmtime_component_record_type_field_count(ty: ?*const wasmtime_component_record_type_t) usize;
pub extern fn wasmtime_component_record_type_field_nth(ty: ?*const wasmtime_component_record_type_t, nth: usize, name_ret: [*c][*c]const u8, name_len_ret: [*c]usize, type_ret: [*c]struct_wasmtime_component_valtype_t) bool;
pub extern fn wasmtime_component_tuple_type_clone(ty: ?*const wasmtime_component_tuple_type_t) ?*wasmtime_component_tuple_type_t;
pub extern fn wasmtime_component_tuple_type_equal(a: ?*const wasmtime_component_tuple_type_t, b: ?*const wasmtime_component_tuple_type_t) bool;
pub extern fn wasmtime_component_tuple_type_delete(ptr: ?*wasmtime_component_tuple_type_t) void;
pub extern fn wasmtime_component_tuple_type_types_count(ty: ?*const wasmtime_component_tuple_type_t) usize;
pub extern fn wasmtime_component_tuple_type_types_nth(ty: ?*const wasmtime_component_tuple_type_t, nth: usize, type_ret: [*c]struct_wasmtime_component_valtype_t) bool;
pub extern fn wasmtime_component_variant_type_clone(ty: ?*const wasmtime_component_variant_type_t) ?*wasmtime_component_variant_type_t;
pub extern fn wasmtime_component_variant_type_equal(a: ?*const wasmtime_component_variant_type_t, b: ?*const wasmtime_component_variant_type_t) bool;
pub extern fn wasmtime_component_variant_type_delete(ptr: ?*wasmtime_component_variant_type_t) void;
pub extern fn wasmtime_component_variant_type_case_count(ty: ?*const wasmtime_component_variant_type_t) usize;
pub extern fn wasmtime_component_variant_type_case_nth(ty: ?*const wasmtime_component_variant_type_t, nth: usize, name_ret: [*c][*c]const u8, name_len_ret: [*c]usize, has_payload_ret: [*c]bool, payload_ret: [*c]struct_wasmtime_component_valtype_t) bool;
pub extern fn wasmtime_component_enum_type_clone(ty: ?*const wasmtime_component_enum_type_t) ?*wasmtime_component_enum_type_t;
pub extern fn wasmtime_component_enum_type_equal(a: ?*const wasmtime_component_enum_type_t, b: ?*const wasmtime_component_enum_type_t) bool;
pub extern fn wasmtime_component_enum_type_delete(ptr: ?*wasmtime_component_enum_type_t) void;
pub extern fn wasmtime_component_enum_type_names_count(ty: ?*const wasmtime_component_enum_type_t) usize;
pub extern fn wasmtime_component_enum_type_names_nth(ty: ?*const wasmtime_component_enum_type_t, nth: usize, name_ret: [*c][*c]const u8, name_len_ret: [*c]usize) bool;
pub extern fn wasmtime_component_option_type_clone(ty: ?*const wasmtime_component_option_type_t) ?*wasmtime_component_option_type_t;
pub extern fn wasmtime_component_option_type_equal(a: ?*const wasmtime_component_option_type_t, b: ?*const wasmtime_component_option_type_t) bool;
pub extern fn wasmtime_component_option_type_delete(ptr: ?*wasmtime_component_option_type_t) void;
pub extern fn wasmtime_component_option_type_ty(ty: ?*const wasmtime_component_option_type_t, type_ret: [*c]struct_wasmtime_component_valtype_t) void;
pub extern fn wasmtime_component_result_type_clone(ty: ?*const wasmtime_component_result_type_t) ?*wasmtime_component_result_type_t;
pub extern fn wasmtime_component_result_type_equal(a: ?*const wasmtime_component_result_type_t, b: ?*const wasmtime_component_result_type_t) bool;
pub extern fn wasmtime_component_result_type_delete(ptr: ?*wasmtime_component_result_type_t) void;
pub extern fn wasmtime_component_result_type_ok(ty: ?*const wasmtime_component_result_type_t, type_ret: [*c]struct_wasmtime_component_valtype_t) bool;
pub extern fn wasmtime_component_result_type_err(ty: ?*const wasmtime_component_result_type_t, type_ret: [*c]struct_wasmtime_component_valtype_t) bool;
pub extern fn wasmtime_component_flags_type_clone(ty: ?*const wasmtime_component_flags_type_t) ?*wasmtime_component_flags_type_t;
pub extern fn wasmtime_component_flags_type_equal(a: ?*const wasmtime_component_flags_type_t, b: ?*const wasmtime_component_flags_type_t) bool;
pub extern fn wasmtime_component_flags_type_delete(ptr: ?*wasmtime_component_flags_type_t) void;
pub extern fn wasmtime_component_flags_type_names_count(ty: ?*const wasmtime_component_flags_type_t) usize;
pub extern fn wasmtime_component_flags_type_names_nth(ty: ?*const wasmtime_component_flags_type_t, nth: usize, name_ret: [*c][*c]const u8, name_len_ret: [*c]usize) bool;
pub extern fn wasmtime_component_future_type_clone(ty: ?*const wasmtime_component_future_type_t) ?*wasmtime_component_future_type_t;
pub extern fn wasmtime_component_future_type_equal(a: ?*const wasmtime_component_future_type_t, b: ?*const wasmtime_component_future_type_t) bool;
pub extern fn wasmtime_component_future_type_delete(ptr: ?*wasmtime_component_future_type_t) void;
pub extern fn wasmtime_component_future_type_ty(ty: ?*const wasmtime_component_future_type_t, type_ret: [*c]struct_wasmtime_component_valtype_t) bool;
pub extern fn wasmtime_component_stream_type_clone(ty: ?*const wasmtime_component_stream_type_t) ?*wasmtime_component_stream_type_t;
pub extern fn wasmtime_component_stream_type_equal(a: ?*const wasmtime_component_stream_type_t, b: ?*const wasmtime_component_stream_type_t) bool;
pub extern fn wasmtime_component_stream_type_delete(ptr: ?*wasmtime_component_stream_type_t) void;
pub extern fn wasmtime_component_stream_type_ty(ty: ?*const wasmtime_component_stream_type_t, type_ret: [*c]struct_wasmtime_component_valtype_t) bool;
pub extern fn wasmtime_component_map_type_clone(ty: ?*const wasmtime_component_map_type_t) ?*wasmtime_component_map_type_t;
pub extern fn wasmtime_component_map_type_equal(a: ?*const wasmtime_component_map_type_t, b: ?*const wasmtime_component_map_type_t) bool;
pub extern fn wasmtime_component_map_type_delete(ptr: ?*wasmtime_component_map_type_t) void;
pub extern fn wasmtime_component_map_type_key(ty: ?*const wasmtime_component_map_type_t, type_ret: [*c]struct_wasmtime_component_valtype_t) void;
pub extern fn wasmtime_component_map_type_value(ty: ?*const wasmtime_component_map_type_t, type_ret: [*c]struct_wasmtime_component_valtype_t) void;
pub const wasmtime_component_valtype_t = struct_wasmtime_component_valtype_t;
pub extern fn wasmtime_component_valtype_clone(ty: [*c]const wasmtime_component_valtype_t, out: [*c]wasmtime_component_valtype_t) void;
pub extern fn wasmtime_component_valtype_equal(a: [*c]const wasmtime_component_valtype_t, b: [*c]const wasmtime_component_valtype_t) bool;
pub extern fn wasmtime_component_valtype_delete(ptr: [*c]wasmtime_component_valtype_t) void;
pub const struct_wasmtime_component_func_type_t = opaque {
    pub const wasmtime_component_func_type_clone = __root.wasmtime_component_func_type_clone;
    pub const wasmtime_component_func_type_delete = __root.wasmtime_component_func_type_delete;
    pub const wasmtime_component_func_type_async = __root.wasmtime_component_func_type_async;
    pub const wasmtime_component_func_type_param_count = __root.wasmtime_component_func_type_param_count;
    pub const wasmtime_component_func_type_param_nth = __root.wasmtime_component_func_type_param_nth;
    pub const wasmtime_component_func_type_result = __root.wasmtime_component_func_type_result;
    pub const clone = __root.wasmtime_component_func_type_clone;
    pub const delete = __root.wasmtime_component_func_type_delete;
    pub const async = __root.wasmtime_component_func_type_async;
    pub const count = __root.wasmtime_component_func_type_param_count;
    pub const nth = __root.wasmtime_component_func_type_param_nth;
    pub const result = __root.wasmtime_component_func_type_result;
};
pub const wasmtime_component_func_type_t = struct_wasmtime_component_func_type_t;
pub extern fn wasmtime_component_func_type_clone(ty: ?*const wasmtime_component_func_type_t) ?*wasmtime_component_func_type_t;
pub extern fn wasmtime_component_func_type_delete(ty: ?*wasmtime_component_func_type_t) void;
pub extern fn wasmtime_component_func_type_async(ty: ?*const wasmtime_component_func_type_t) bool;
pub extern fn wasmtime_component_func_type_param_count(ty: ?*const wasmtime_component_func_type_t) usize;
pub extern fn wasmtime_component_func_type_param_nth(ty: ?*const wasmtime_component_func_type_t, nth: usize, name_ret: [*c][*c]const u8, name_len_ret: [*c]usize, type_ret: [*c]wasmtime_component_valtype_t) bool;
pub extern fn wasmtime_component_func_type_result(ty: ?*const wasmtime_component_func_type_t, type_ret: [*c]wasmtime_component_valtype_t) bool;
pub const struct_wasmtime_component_extern_t = opaque {
    pub const wasmtime_component_extern_clone = __root.wasmtime_component_extern_clone;
    pub const wasmtime_component_extern_type = __root.wasmtime_component_extern_type;
    pub const wasmtime_component_extern_implements = __root.wasmtime_component_extern_implements;
    pub const wasmtime_component_extern_is_implements = __root.wasmtime_component_extern_is_implements;
    pub const wasmtime_component_extern_external_id = __root.wasmtime_component_extern_external_id;
    pub const wasmtime_component_extern_delete = __root.wasmtime_component_extern_delete;
    pub const clone = __root.wasmtime_component_extern_clone;
    pub const @"type" = __root.wasmtime_component_extern_type;
    pub const implements = __root.wasmtime_component_extern_implements;
    pub const id = __root.wasmtime_component_extern_external_id;
    pub const delete = __root.wasmtime_component_extern_delete;
};
pub const struct_wasmtime_component_instance_type = opaque {
    pub const wasmtime_component_instance_type_clone = __root.wasmtime_component_instance_type_clone;
    pub const wasmtime_component_instance_type_delete = __root.wasmtime_component_instance_type_delete;
    pub const wasmtime_component_instance_type_export_count = __root.wasmtime_component_instance_type_export_count;
    pub const wasmtime_component_instance_type_export_get = __root.wasmtime_component_instance_type_export_get;
    pub const wasmtime_component_instance_type_export_nth = __root.wasmtime_component_instance_type_export_nth;
    pub const clone = __root.wasmtime_component_instance_type_clone;
    pub const delete = __root.wasmtime_component_instance_type_delete;
    pub const export_count = __root.wasmtime_component_instance_type_export_count;
    pub const export_get = __root.wasmtime_component_instance_type_export_get;
    pub const export_nth = __root.wasmtime_component_instance_type_export_nth;
};
pub const wasmtime_component_instance_type_t = struct_wasmtime_component_instance_type;
pub extern fn wasmtime_component_instance_type_clone(ty: ?*const wasmtime_component_instance_type_t) ?*wasmtime_component_instance_type_t;
pub extern fn wasmtime_component_instance_type_delete(ty: ?*wasmtime_component_instance_type_t) void;
pub extern fn wasmtime_component_instance_type_export_count(ty: ?*const wasmtime_component_instance_type_t, engine: ?*const wasm_engine_t) usize;
pub extern fn wasmtime_component_instance_type_export_get(ty: ?*const wasmtime_component_instance_type_t, engine: ?*const wasm_engine_t, name: [*c]const u8, name_len: usize, ret: [*c]?*struct_wasmtime_component_extern_t) bool;
pub extern fn wasmtime_component_instance_type_export_nth(ty: ?*const wasmtime_component_instance_type_t, engine: ?*const wasm_engine_t, nth: usize, name_ret: [*c][*c]const u8, name_len_ret: [*c]usize, ret: [*c]?*struct_wasmtime_component_extern_t) bool;
pub const struct_wasmtime_module_type = opaque {
    pub const wasmtime_module_type_clone = __root.wasmtime_module_type_clone;
    pub const wasmtime_module_type_delete = __root.wasmtime_module_type_delete;
    pub const wasmtime_module_type_import_count = __root.wasmtime_module_type_import_count;
    pub const wasmtime_module_type_import_nth = __root.wasmtime_module_type_import_nth;
    pub const wasmtime_module_type_export_count = __root.wasmtime_module_type_export_count;
    pub const wasmtime_module_type_export_nth = __root.wasmtime_module_type_export_nth;
    pub const clone = __root.wasmtime_module_type_clone;
    pub const delete = __root.wasmtime_module_type_delete;
    pub const import_count = __root.wasmtime_module_type_import_count;
    pub const import_nth = __root.wasmtime_module_type_import_nth;
    pub const export_count = __root.wasmtime_module_type_export_count;
    pub const export_nth = __root.wasmtime_module_type_export_nth;
};
pub const wasmtime_module_type_t = struct_wasmtime_module_type;
pub extern fn wasmtime_module_type_clone(ty: ?*const wasmtime_module_type_t) ?*wasmtime_module_type_t;
pub extern fn wasmtime_module_type_delete(ty: ?*wasmtime_module_type_t) void;
pub extern fn wasmtime_module_type_import_count(ty: ?*const wasmtime_module_type_t, engine: ?*const wasm_engine_t) usize;
pub extern fn wasmtime_module_type_import_nth(ty: ?*const wasmtime_module_type_t, engine: ?*const wasm_engine_t, nth: usize) ?*wasm_importtype_t;
pub extern fn wasmtime_module_type_export_count(ty: ?*const wasmtime_module_type_t, engine: ?*const wasm_engine_t) usize;
pub extern fn wasmtime_module_type_export_nth(ty: ?*const wasmtime_module_type_t, engine: ?*const wasm_engine_t, nth: usize) ?*wasm_exporttype_t;
pub const struct_wasmtime_component_type_t = opaque {
    pub const wasmtime_component_type_clone = __root.wasmtime_component_type_clone;
    pub const wasmtime_component_type_delete = __root.wasmtime_component_type_delete;
    pub const wasmtime_component_type_import_count = __root.wasmtime_component_type_import_count;
    pub const wasmtime_component_type_import_get = __root.wasmtime_component_type_import_get;
    pub const wasmtime_component_type_import_nth = __root.wasmtime_component_type_import_nth;
    pub const wasmtime_component_type_export_count = __root.wasmtime_component_type_export_count;
    pub const wasmtime_component_type_export_get = __root.wasmtime_component_type_export_get;
    pub const wasmtime_component_type_export_nth = __root.wasmtime_component_type_export_nth;
    pub const clone = __root.wasmtime_component_type_clone;
    pub const delete = __root.wasmtime_component_type_delete;
    pub const count = __root.wasmtime_component_type_import_count;
    pub const get = __root.wasmtime_component_type_import_get;
    pub const nth = __root.wasmtime_component_type_import_nth;
};
pub const wasmtime_component_type_t = struct_wasmtime_component_type_t;
pub extern fn wasmtime_component_type_clone(ty: ?*const wasmtime_component_type_t) ?*wasmtime_component_type_t;
pub extern fn wasmtime_component_type_delete(ty: ?*wasmtime_component_type_t) void;
pub extern fn wasmtime_component_type_import_count(ty: ?*const wasmtime_component_type_t, engine: ?*const wasm_engine_t) usize;
pub extern fn wasmtime_component_type_import_get(ty: ?*const wasmtime_component_type_t, engine: ?*const wasm_engine_t, name: [*c]const u8, name_len: usize, ret: [*c]?*struct_wasmtime_component_extern_t) bool;
pub extern fn wasmtime_component_type_import_nth(ty: ?*const wasmtime_component_type_t, engine: ?*const wasm_engine_t, nth: usize, name_ret: [*c][*c]const u8, name_len_ret: [*c]usize, ret: [*c]?*struct_wasmtime_component_extern_t) bool;
pub extern fn wasmtime_component_type_export_count(ty: ?*const wasmtime_component_type_t, engine: ?*const wasm_engine_t) usize;
pub extern fn wasmtime_component_type_export_get(ty: ?*const wasmtime_component_type_t, engine: ?*const wasm_engine_t, name: [*c]const u8, name_len: usize, ret: [*c]?*struct_wasmtime_component_extern_t) bool;
pub extern fn wasmtime_component_type_export_nth(ty: ?*const wasmtime_component_type_t, engine: ?*const wasm_engine_t, nth: usize, name_ret: [*c][*c]const u8, name_len_ret: [*c]usize, ret: [*c]?*struct_wasmtime_component_extern_t) bool;
pub const wasmtime_component_item_kind_t = u8;
pub const union_wasmtime_component_item_union = extern union {
    component: ?*wasmtime_component_type_t,
    component_instance: ?*wasmtime_component_instance_type_t,
    module: ?*wasmtime_module_type_t,
    component_func: ?*wasmtime_component_func_type_t,
    resource: ?*wasmtime_component_resource_type_t,
    core_func: ?*wasm_functype_t,
    type: wasmtime_component_valtype_t,
};
pub const wasmtime_component_item_union_t = union_wasmtime_component_item_union;
pub const struct_wasmtime_component_item_t = extern struct {
    kind: wasmtime_component_item_kind_t,
    of: wasmtime_component_item_union_t,
    pub const wasmtime_component_item_clone = __root.wasmtime_component_item_clone;
    pub const wasmtime_component_item_delete = __root.wasmtime_component_item_delete;
    pub const clone = __root.wasmtime_component_item_clone;
    pub const delete = __root.wasmtime_component_item_delete;
};
pub const wasmtime_component_item_t = struct_wasmtime_component_item_t;
pub extern fn wasmtime_component_item_clone(item: [*c]const wasmtime_component_item_t, out: [*c]wasmtime_component_item_t) void;
pub extern fn wasmtime_component_item_delete(ptr: [*c]wasmtime_component_item_t) void;
pub const wasmtime_component_extern_t = struct_wasmtime_component_extern_t;
pub extern fn wasmtime_component_extern_clone(e: ?*const wasmtime_component_extern_t) ?*wasmtime_component_extern_t;
pub extern fn wasmtime_component_extern_type(e: ?*const wasmtime_component_extern_t, ret: [*c]wasmtime_component_item_t) void;
pub extern fn wasmtime_component_extern_implements(e: ?*const wasmtime_component_extern_t, len: [*c]usize) [*c]const u8;
pub extern fn wasmtime_component_extern_is_implements(e: ?*const wasmtime_component_extern_t, name: [*c]const u8, len: usize) bool;
pub extern fn wasmtime_component_extern_external_id(e: ?*const wasmtime_component_extern_t, len: [*c]usize) [*c]const u8;
pub extern fn wasmtime_component_extern_delete(ptr: ?*wasmtime_component_extern_t) void;
pub const struct_wasmtime_component_t = opaque {
    pub const wasmtime_component_serialize = __root.wasmtime_component_serialize;
    pub const wasmtime_component_clone = __root.wasmtime_component_clone;
    pub const wasmtime_component_type = __root.wasmtime_component_type;
    pub const wasmtime_component_delete = __root.wasmtime_component_delete;
    pub const wasmtime_component_get_export_index = __root.wasmtime_component_get_export_index;
    pub const serialize = __root.wasmtime_component_serialize;
    pub const clone = __root.wasmtime_component_clone;
    pub const @"type" = __root.wasmtime_component_type;
    pub const delete = __root.wasmtime_component_delete;
};
pub const wasmtime_component_t = struct_wasmtime_component_t;
pub extern fn wasmtime_component_new(engine: ?*const wasm_engine_t, buf: [*c]const u8, len: usize, component_out: [*c]?*wasmtime_component_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_serialize(component: ?*const wasmtime_component_t, ret: [*c]wasm_byte_vec_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_deserialize(engine: ?*const wasm_engine_t, buf: [*c]const u8, len: usize, component_out: [*c]?*wasmtime_component_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_deserialize_file(engine: ?*const wasm_engine_t, path: [*c]const u8, component_out: [*c]?*wasmtime_component_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_clone(component: ?*const wasmtime_component_t) ?*wasmtime_component_t;
pub extern fn wasmtime_component_type(component: ?*const wasmtime_component_t) ?*wasmtime_component_type_t;
pub extern fn wasmtime_component_delete(component: ?*wasmtime_component_t) void;
pub const struct_wasmtime_component_export_index_t = opaque {
    pub const wasmtime_component_export_index_clone = __root.wasmtime_component_export_index_clone;
    pub const wasmtime_component_export_index_delete = __root.wasmtime_component_export_index_delete;
    pub const clone = __root.wasmtime_component_export_index_clone;
    pub const delete = __root.wasmtime_component_export_index_delete;
};
pub const wasmtime_component_export_index_t = struct_wasmtime_component_export_index_t;
pub extern fn wasmtime_component_get_export_index(component: ?*const wasmtime_component_t, instance_export_index: ?*const wasmtime_component_export_index_t, name: [*c]const u8, name_len: usize) ?*wasmtime_component_export_index_t;
pub extern fn wasmtime_component_export_index_clone(index: ?*const wasmtime_component_export_index_t) ?*wasmtime_component_export_index_t;
pub extern fn wasmtime_component_export_index_delete(export_index: ?*wasmtime_component_export_index_t) void;
pub const struct_wasmtime_component_resource_any = opaque {
    pub const wasmtime_component_resource_any_type = __root.wasmtime_component_resource_any_type;
    pub const wasmtime_component_resource_any_clone = __root.wasmtime_component_resource_any_clone;
    pub const wasmtime_component_resource_any_owned = __root.wasmtime_component_resource_any_owned;
    pub const wasmtime_component_resource_any_delete = __root.wasmtime_component_resource_any_delete;
    pub const @"type" = __root.wasmtime_component_resource_any_type;
    pub const clone = __root.wasmtime_component_resource_any_clone;
    pub const owned = __root.wasmtime_component_resource_any_owned;
    pub const delete = __root.wasmtime_component_resource_any_delete;
};
pub const wasmtime_component_resource_any_t = struct_wasmtime_component_resource_any;
pub extern fn wasmtime_component_resource_any_type(resource: ?*const wasmtime_component_resource_any_t) ?*wasmtime_component_resource_type_t;
pub extern fn wasmtime_component_resource_any_clone(resource: ?*const wasmtime_component_resource_any_t) ?*wasmtime_component_resource_any_t;
pub extern fn wasmtime_component_resource_any_owned(resource: ?*const wasmtime_component_resource_any_t) bool;
pub extern fn wasmtime_component_resource_any_drop(ctx: ?*wasmtime_context_t, resource: ?*const wasmtime_component_resource_any_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_resource_any_delete(resource: ?*wasmtime_component_resource_any_t) void;
pub const struct_wasmtime_component_resource_host = opaque {
    pub const wasmtime_component_resource_host_clone = __root.wasmtime_component_resource_host_clone;
    pub const wasmtime_component_resource_host_rep = __root.wasmtime_component_resource_host_rep;
    pub const wasmtime_component_resource_host_type = __root.wasmtime_component_resource_host_type;
    pub const wasmtime_component_resource_host_owned = __root.wasmtime_component_resource_host_owned;
    pub const wasmtime_component_resource_host_delete = __root.wasmtime_component_resource_host_delete;
    pub const clone = __root.wasmtime_component_resource_host_clone;
    pub const rep = __root.wasmtime_component_resource_host_rep;
    pub const @"type" = __root.wasmtime_component_resource_host_type;
    pub const owned = __root.wasmtime_component_resource_host_owned;
    pub const delete = __root.wasmtime_component_resource_host_delete;
};
pub const wasmtime_component_resource_host_t = struct_wasmtime_component_resource_host;
pub extern fn wasmtime_component_resource_host_new(owned: bool, rep: u32, ty: u32) ?*wasmtime_component_resource_host_t;
pub extern fn wasmtime_component_resource_host_clone(resource: ?*const wasmtime_component_resource_host_t) ?*wasmtime_component_resource_host_t;
pub extern fn wasmtime_component_resource_host_rep(resource: ?*const wasmtime_component_resource_host_t) u32;
pub extern fn wasmtime_component_resource_host_type(resource: ?*const wasmtime_component_resource_host_t) u32;
pub extern fn wasmtime_component_resource_host_owned(resource: ?*const wasmtime_component_resource_host_t) bool;
pub extern fn wasmtime_component_resource_host_delete(resource: ?*wasmtime_component_resource_host_t) void;
pub extern fn wasmtime_component_resource_any_to_host(ctx: ?*wasmtime_context_t, resource: ?*const wasmtime_component_resource_any_t, ret: [*c]?*wasmtime_component_resource_host_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_resource_host_to_any(ctx: ?*wasmtime_context_t, resource: ?*const wasmtime_component_resource_host_t, ret: [*c]?*wasmtime_component_resource_any_t) ?*wasmtime_error_t;
pub const wasmtime_component_valkind_t = u8;
pub const struct_wasmtime_component_val = extern struct {
    kind: wasmtime_component_valkind_t,
    of: wasmtime_component_valunion_t,
    pub const wasmtime_component_val_new = __root.wasmtime_component_val_new;
    pub const wasmtime_component_val_free = __root.wasmtime_component_val_free;
    pub const wasmtime_component_val_clone = __root.wasmtime_component_val_clone;
    pub const wasmtime_component_val_delete = __root.wasmtime_component_val_delete;
    pub const new = __root.wasmtime_component_val_new;
    pub const free = __root.wasmtime_component_val_free;
    pub const clone = __root.wasmtime_component_val_clone;
    pub const delete = __root.wasmtime_component_val_delete;
};
pub const wasmtime_component_val_t = struct_wasmtime_component_val;
pub const struct_wasmtime_component_valrecord_entry = extern struct {
    name: wasm_name_t,
    val: wasmtime_component_val_t,
};
pub const struct_wasmtime_component_valmap_entry = extern struct {
    key: wasmtime_component_val_t,
    value: wasmtime_component_val_t,
};
pub const struct_wasmtime_component_vallist = extern struct {
    size: usize,
    data: [*c]struct_wasmtime_component_val,
    pub const wasmtime_component_vallist_new = __root.wasmtime_component_vallist_new;
    pub const wasmtime_component_vallist_new_empty = __root.wasmtime_component_vallist_new_empty;
    pub const wasmtime_component_vallist_new_uninit = __root.wasmtime_component_vallist_new_uninit;
    pub const wasmtime_component_vallist_copy = __root.wasmtime_component_vallist_copy;
    pub const wasmtime_component_vallist_delete = __root.wasmtime_component_vallist_delete;
    pub const new = __root.wasmtime_component_vallist_new;
    pub const new_empty = __root.wasmtime_component_vallist_new_empty;
    pub const new_uninit = __root.wasmtime_component_vallist_new_uninit;
    pub const copy = __root.wasmtime_component_vallist_copy;
    pub const delete = __root.wasmtime_component_vallist_delete;
};
pub const wasmtime_component_vallist_t = struct_wasmtime_component_vallist;
pub extern fn wasmtime_component_vallist_new(out: [*c]wasmtime_component_vallist_t, size: usize, ptr: [*c]const struct_wasmtime_component_val) void;
pub extern fn wasmtime_component_vallist_new_empty(out: [*c]wasmtime_component_vallist_t) void;
pub extern fn wasmtime_component_vallist_new_uninit(out: [*c]wasmtime_component_vallist_t, size: usize) void;
pub extern fn wasmtime_component_vallist_copy(dst: [*c]wasmtime_component_vallist_t, src: [*c]const wasmtime_component_vallist_t) void;
pub extern fn wasmtime_component_vallist_delete(value: [*c]wasmtime_component_vallist_t) void;
pub const struct_wasmtime_component_valrecord = extern struct {
    size: usize,
    data: [*c]struct_wasmtime_component_valrecord_entry,
    pub const wasmtime_component_valrecord_new = __root.wasmtime_component_valrecord_new;
    pub const wasmtime_component_valrecord_new_empty = __root.wasmtime_component_valrecord_new_empty;
    pub const wasmtime_component_valrecord_new_uninit = __root.wasmtime_component_valrecord_new_uninit;
    pub const wasmtime_component_valrecord_copy = __root.wasmtime_component_valrecord_copy;
    pub const wasmtime_component_valrecord_delete = __root.wasmtime_component_valrecord_delete;
    pub const new = __root.wasmtime_component_valrecord_new;
    pub const new_empty = __root.wasmtime_component_valrecord_new_empty;
    pub const new_uninit = __root.wasmtime_component_valrecord_new_uninit;
    pub const copy = __root.wasmtime_component_valrecord_copy;
    pub const delete = __root.wasmtime_component_valrecord_delete;
};
pub const wasmtime_component_valrecord_t = struct_wasmtime_component_valrecord;
pub extern fn wasmtime_component_valrecord_new(out: [*c]wasmtime_component_valrecord_t, size: usize, ptr: [*c]const struct_wasmtime_component_valrecord_entry) void;
pub extern fn wasmtime_component_valrecord_new_empty(out: [*c]wasmtime_component_valrecord_t) void;
pub extern fn wasmtime_component_valrecord_new_uninit(out: [*c]wasmtime_component_valrecord_t, size: usize) void;
pub extern fn wasmtime_component_valrecord_copy(dst: [*c]wasmtime_component_valrecord_t, src: [*c]const wasmtime_component_valrecord_t) void;
pub extern fn wasmtime_component_valrecord_delete(value: [*c]wasmtime_component_valrecord_t) void;
pub const struct_wasmtime_component_valtuple = extern struct {
    size: usize,
    data: [*c]struct_wasmtime_component_val,
    pub const wasmtime_component_valtuple_new = __root.wasmtime_component_valtuple_new;
    pub const wasmtime_component_valtuple_new_empty = __root.wasmtime_component_valtuple_new_empty;
    pub const wasmtime_component_valtuple_new_uninit = __root.wasmtime_component_valtuple_new_uninit;
    pub const wasmtime_component_valtuple_copy = __root.wasmtime_component_valtuple_copy;
    pub const wasmtime_component_valtuple_delete = __root.wasmtime_component_valtuple_delete;
    pub const new = __root.wasmtime_component_valtuple_new;
    pub const new_empty = __root.wasmtime_component_valtuple_new_empty;
    pub const new_uninit = __root.wasmtime_component_valtuple_new_uninit;
    pub const copy = __root.wasmtime_component_valtuple_copy;
    pub const delete = __root.wasmtime_component_valtuple_delete;
};
pub const wasmtime_component_valtuple_t = struct_wasmtime_component_valtuple;
pub extern fn wasmtime_component_valtuple_new(out: [*c]wasmtime_component_valtuple_t, size: usize, ptr: [*c]const struct_wasmtime_component_val) void;
pub extern fn wasmtime_component_valtuple_new_empty(out: [*c]wasmtime_component_valtuple_t) void;
pub extern fn wasmtime_component_valtuple_new_uninit(out: [*c]wasmtime_component_valtuple_t, size: usize) void;
pub extern fn wasmtime_component_valtuple_copy(dst: [*c]wasmtime_component_valtuple_t, src: [*c]const wasmtime_component_valtuple_t) void;
pub extern fn wasmtime_component_valtuple_delete(value: [*c]wasmtime_component_valtuple_t) void;
pub const struct_wasmtime_component_valflags = extern struct {
    size: usize,
    data: [*c]wasm_name_t,
    pub const wasmtime_component_valflags_new = __root.wasmtime_component_valflags_new;
    pub const wasmtime_component_valflags_new_empty = __root.wasmtime_component_valflags_new_empty;
    pub const wasmtime_component_valflags_new_uninit = __root.wasmtime_component_valflags_new_uninit;
    pub const wasmtime_component_valflags_copy = __root.wasmtime_component_valflags_copy;
    pub const wasmtime_component_valflags_delete = __root.wasmtime_component_valflags_delete;
    pub const new = __root.wasmtime_component_valflags_new;
    pub const new_empty = __root.wasmtime_component_valflags_new_empty;
    pub const new_uninit = __root.wasmtime_component_valflags_new_uninit;
    pub const copy = __root.wasmtime_component_valflags_copy;
    pub const delete = __root.wasmtime_component_valflags_delete;
};
pub const wasmtime_component_valflags_t = struct_wasmtime_component_valflags;
pub extern fn wasmtime_component_valflags_new(out: [*c]wasmtime_component_valflags_t, size: usize, ptr: [*c]const wasm_name_t) void;
pub extern fn wasmtime_component_valflags_new_empty(out: [*c]wasmtime_component_valflags_t) void;
pub extern fn wasmtime_component_valflags_new_uninit(out: [*c]wasmtime_component_valflags_t, size: usize) void;
pub extern fn wasmtime_component_valflags_copy(dst: [*c]wasmtime_component_valflags_t, src: [*c]const wasmtime_component_valflags_t) void;
pub extern fn wasmtime_component_valflags_delete(value: [*c]wasmtime_component_valflags_t) void;
pub const struct_wasmtime_component_valmap = extern struct {
    size: usize,
    data: [*c]struct_wasmtime_component_valmap_entry,
    pub const wasmtime_component_valmap_new = __root.wasmtime_component_valmap_new;
    pub const wasmtime_component_valmap_new_empty = __root.wasmtime_component_valmap_new_empty;
    pub const wasmtime_component_valmap_new_uninit = __root.wasmtime_component_valmap_new_uninit;
    pub const wasmtime_component_valmap_copy = __root.wasmtime_component_valmap_copy;
    pub const wasmtime_component_valmap_delete = __root.wasmtime_component_valmap_delete;
    pub const new = __root.wasmtime_component_valmap_new;
    pub const new_empty = __root.wasmtime_component_valmap_new_empty;
    pub const new_uninit = __root.wasmtime_component_valmap_new_uninit;
    pub const copy = __root.wasmtime_component_valmap_copy;
    pub const delete = __root.wasmtime_component_valmap_delete;
};
pub const wasmtime_component_valmap_t = struct_wasmtime_component_valmap;
pub extern fn wasmtime_component_valmap_new(out: [*c]wasmtime_component_valmap_t, size: usize, ptr: [*c]const struct_wasmtime_component_valmap_entry) void;
pub extern fn wasmtime_component_valmap_new_empty(out: [*c]wasmtime_component_valmap_t) void;
pub extern fn wasmtime_component_valmap_new_uninit(out: [*c]wasmtime_component_valmap_t, size: usize) void;
pub extern fn wasmtime_component_valmap_copy(dst: [*c]wasmtime_component_valmap_t, src: [*c]const wasmtime_component_valmap_t) void;
pub extern fn wasmtime_component_valmap_delete(value: [*c]wasmtime_component_valmap_t) void;
pub const wasmtime_component_valvariant_t = extern struct {
    discriminant: wasm_name_t,
    val: [*c]struct_wasmtime_component_val,
};
pub const wasmtime_component_valresult_t = extern struct {
    is_ok: bool,
    val: [*c]struct_wasmtime_component_val,
};
pub const wasmtime_component_valunion_t = extern union {
    boolean: bool,
    s8: i8,
    u8: u8,
    s16: i16,
    u16: u16,
    s32: i32,
    u32: u32,
    s64: i64,
    u64: u64,
    f32: float32_t,
    f64: float64_t,
    character: u32,
    string: wasm_name_t,
    list: wasmtime_component_vallist_t,
    record: wasmtime_component_valrecord_t,
    tuple: wasmtime_component_valtuple_t,
    variant: wasmtime_component_valvariant_t,
    enumeration: wasm_name_t,
    option: [*c]struct_wasmtime_component_val,
    result: wasmtime_component_valresult_t,
    flags: wasmtime_component_valflags_t,
    map: wasmtime_component_valmap_t,
    resource: ?*wasmtime_component_resource_any_t,
};
pub const wasmtime_component_valrecord_entry_t = struct_wasmtime_component_valrecord_entry;
pub const wasmtime_component_valmap_entry_t = struct_wasmtime_component_valmap_entry;
pub extern fn wasmtime_component_val_new(val: [*c]wasmtime_component_val_t) [*c]wasmtime_component_val_t;
pub extern fn wasmtime_component_val_free(ptr: [*c]wasmtime_component_val_t) void;
pub extern fn wasmtime_component_val_clone(src: [*c]const wasmtime_component_val_t, dst: [*c]wasmtime_component_val_t) void;
pub extern fn wasmtime_component_val_delete(value: [*c]wasmtime_component_val_t) void;
const struct_unnamed_6 = extern struct {
    store_id: u64,
    __private1: u32,
};
pub const struct_wasmtime_component_func = extern struct {
    unnamed_0: struct_unnamed_6,
    __private2: u32,
    __private3: ?*anyopaque,
    pub const wasmtime_component_func_type = __root.wasmtime_component_func_type;
    pub const wasmtime_component_func_call = __root.wasmtime_component_func_call;
    pub const wasmtime_component_func_post_return = __root.wasmtime_component_func_post_return;
    pub const wasmtime_component_func_call_async = __root.wasmtime_component_func_call_async;
    pub const @"type" = __root.wasmtime_component_func_type;
    pub const call = __root.wasmtime_component_func_call;
    pub const post_return = __root.wasmtime_component_func_post_return;
    pub const call_async = __root.wasmtime_component_func_call_async;
};
pub const wasmtime_component_func_t = struct_wasmtime_component_func;
pub extern fn wasmtime_component_func_type(func: [*c]const wasmtime_component_func_t, context: ?*wasmtime_context_t) ?*wasmtime_component_func_type_t;
pub extern fn wasmtime_component_func_call(func: [*c]const wasmtime_component_func_t, context: ?*wasmtime_context_t, args: [*c]const wasmtime_component_val_t, args_size: usize, results: [*c]wasmtime_component_val_t, results_size: usize) ?*wasmtime_error_t;
pub extern fn wasmtime_component_func_post_return(func: [*c]const wasmtime_component_func_t, context: ?*wasmtime_context_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_func_call_async(func: [*c]const wasmtime_component_func_t, context: ?*wasmtime_context_t, args: [*c]const wasmtime_component_val_t, args_size: usize, results: [*c]wasmtime_component_val_t, results_size: usize, error_ret: [*c]?*wasmtime_error_t) ?*wasmtime_call_future_t;
pub const struct_wasmtime_component_instance = extern struct {
    store_id: u64,
    __private: u32,
    pub const wasmtime_component_instance_get_export_index = __root.wasmtime_component_instance_get_export_index;
    pub const wasmtime_component_instance_get_func = __root.wasmtime_component_instance_get_func;
    pub const get_export_index = __root.wasmtime_component_instance_get_export_index;
    pub const get_func = __root.wasmtime_component_instance_get_func;
};
pub const wasmtime_component_instance_t = struct_wasmtime_component_instance;
pub extern fn wasmtime_component_instance_get_export_index(instance: [*c]const wasmtime_component_instance_t, context: ?*wasmtime_context_t, instance_export_index: ?*const wasmtime_component_export_index_t, name: [*c]const u8, name_len: usize) ?*wasmtime_component_export_index_t;
pub extern fn wasmtime_component_instance_get_func(instance: [*c]const wasmtime_component_instance_t, context: ?*wasmtime_context_t, export_index: ?*const wasmtime_component_export_index_t, func_out: [*c]wasmtime_component_func_t) bool;
pub const struct_wasmtime_component_linker_t = opaque {
    pub const wasmtime_component_linker_allow_shadowing = __root.wasmtime_component_linker_allow_shadowing;
    pub const wasmtime_component_linker_root = __root.wasmtime_component_linker_root;
    pub const wasmtime_component_linker_instantiate = __root.wasmtime_component_linker_instantiate;
    pub const wasmtime_component_linker_define_unknown_imports_as_traps = __root.wasmtime_component_linker_define_unknown_imports_as_traps;
    pub const wasmtime_component_linker_delete = __root.wasmtime_component_linker_delete;
    pub const wasmtime_component_linker_add_wasip2 = __root.wasmtime_component_linker_add_wasip2;
    pub const wasmtime_component_linker_add_wasi_http = __root.wasmtime_component_linker_add_wasi_http;
    pub const wasmtime_component_linker_instantiate_async = __root.wasmtime_component_linker_instantiate_async;
    pub const wasmtime_component_linker_add_wasip2_async = __root.wasmtime_component_linker_add_wasip2_async;
    pub const wasmtime_component_linker_add_wasi_http_async = __root.wasmtime_component_linker_add_wasi_http_async;
    pub const shadowing = __root.wasmtime_component_linker_allow_shadowing;
    pub const root = __root.wasmtime_component_linker_root;
    pub const instantiate = __root.wasmtime_component_linker_instantiate;
    pub const traps = __root.wasmtime_component_linker_define_unknown_imports_as_traps;
    pub const delete = __root.wasmtime_component_linker_delete;
    pub const wasip2 = __root.wasmtime_component_linker_add_wasip2;
    pub const http = __root.wasmtime_component_linker_add_wasi_http;
    pub const async = __root.wasmtime_component_linker_instantiate_async;
};
pub const wasmtime_component_linker_t = struct_wasmtime_component_linker_t;
pub const struct_wasmtime_component_linker_instance_t = opaque {
    pub const wasmtime_component_linker_instance_add_instance = __root.wasmtime_component_linker_instance_add_instance;
    pub const wasmtime_component_linker_instance_add_module = __root.wasmtime_component_linker_instance_add_module;
    pub const wasmtime_component_linker_instance_add_func = __root.wasmtime_component_linker_instance_add_func;
    pub const wasmtime_component_linker_instance_add_resource = __root.wasmtime_component_linker_instance_add_resource;
    pub const wasmtime_component_linker_instance_delete = __root.wasmtime_component_linker_instance_delete;
    pub const wasmtime_component_linker_instance_add_func_async = __root.wasmtime_component_linker_instance_add_func_async;
    pub const instance = __root.wasmtime_component_linker_instance_add_instance;
    pub const module = __root.wasmtime_component_linker_instance_add_module;
    pub const func = __root.wasmtime_component_linker_instance_add_func;
    pub const resource = __root.wasmtime_component_linker_instance_add_resource;
    pub const delete = __root.wasmtime_component_linker_instance_delete;
    pub const async = __root.wasmtime_component_linker_instance_add_func_async;
};
pub const wasmtime_component_linker_instance_t = struct_wasmtime_component_linker_instance_t;
pub extern fn wasmtime_component_linker_new(engine: ?*const wasm_engine_t) ?*wasmtime_component_linker_t;
pub extern fn wasmtime_component_linker_allow_shadowing(linker: ?*wasmtime_component_linker_t, allow: bool) void;
pub extern fn wasmtime_component_linker_root(linker: ?*wasmtime_component_linker_t) ?*wasmtime_component_linker_instance_t;
pub extern fn wasmtime_component_linker_instantiate(linker: ?*const wasmtime_component_linker_t, context: ?*wasmtime_context_t, component: ?*const wasmtime_component_t, instance_out: [*c]wasmtime_component_instance_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_define_unknown_imports_as_traps(linker: ?*wasmtime_component_linker_t, component: ?*const wasmtime_component_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_delete(linker: ?*wasmtime_component_linker_t) void;
pub extern fn wasmtime_component_linker_instance_add_instance(linker_instance: ?*wasmtime_component_linker_instance_t, name: [*c]const u8, name_len: usize, linker_instance_out: [*c]?*wasmtime_component_linker_instance_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_instance_add_module(linker_instance: ?*wasmtime_component_linker_instance_t, name: [*c]const u8, name_len: usize, module: ?*const wasmtime_module_t) ?*wasmtime_error_t;
pub const wasmtime_component_func_callback_t = ?*const fn (?*anyopaque, ?*wasmtime_context_t, ?*const wasmtime_component_func_type_t, [*c]wasmtime_component_val_t, usize, [*c]wasmtime_component_val_t, usize) callconv(.c) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_instance_add_func(linker_instance: ?*wasmtime_component_linker_instance_t, name: [*c]const u8, name_len: usize, callback: wasmtime_component_func_callback_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_add_wasip2(linker: ?*wasmtime_component_linker_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_add_wasi_http(linker: ?*wasmtime_component_linker_t) ?*wasmtime_error_t;
pub const wasmtime_component_resource_destructor_t = ?*const fn (?*anyopaque, ?*wasmtime_context_t, u32) callconv(.c) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_instance_add_resource(linker_instance: ?*wasmtime_component_linker_instance_t, name: [*c]const u8, name_len: usize, resource: ?*const wasmtime_component_resource_type_t, destructor: wasmtime_component_resource_destructor_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_instance_delete(linker_instance: ?*wasmtime_component_linker_instance_t) void;
pub extern fn wasmtime_component_linker_instantiate_async(linker: ?*const wasmtime_component_linker_t, context: ?*wasmtime_context_t, component: ?*const wasmtime_component_t, instance_out: [*c]wasmtime_component_instance_t, error_ret: [*c]?*wasmtime_error_t) ?*wasmtime_call_future_t;
pub const wasmtime_component_func_async_callback_t = ?*const fn (env: ?*anyopaque, context: ?*wasmtime_context_t, ty: ?*const wasmtime_component_func_type_t, args: [*c]wasmtime_component_val_t, nargs: usize, results: [*c]wasmtime_component_val_t, nresults: usize, error_ret: [*c]?*wasmtime_error_t, continuation_ret: [*c]wasmtime_async_continuation_t) callconv(.c) void;
pub extern fn wasmtime_component_linker_instance_add_func_async(linker_instance: ?*wasmtime_component_linker_instance_t, name: [*c]const u8, name_len: usize, callback: wasmtime_component_func_async_callback_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_add_wasip2_async(linker: ?*wasmtime_component_linker_t) ?*wasmtime_error_t;
pub extern fn wasmtime_component_linker_add_wasi_http_async(linker: ?*wasmtime_component_linker_t) ?*wasmtime_error_t;
pub extern fn wasmtime_engine_clone(engine: ?*const wasm_engine_t) ?*wasm_engine_t;
pub extern fn wasmtime_engine_increment_epoch(engine: ?*const wasm_engine_t) void;
pub extern fn wasmtime_engine_is_pulley(engine: ?*const wasm_engine_t) bool;
pub fn wasmtime_eqref_set_null(arg_ref: [*c]wasmtime_eqref_t) callconv(.c) void {
    var ref = arg_ref;
    _ = &ref;
    ref.*.store_id = 0;
}
pub fn wasmtime_eqref_is_null(arg_ref: [*c]const wasmtime_eqref_t) callconv(.c) bool {
    var ref = arg_ref;
    _ = &ref;
    return ref.*.store_id == @as(u64, 0);
}
pub extern fn wasmtime_eqref_clone(eqref: [*c]const wasmtime_eqref_t, out: [*c]wasmtime_eqref_t) void;
pub extern fn wasmtime_eqref_unroot(ref: [*c]wasmtime_eqref_t) void;
pub extern fn wasmtime_eqref_to_anyref(eqref: [*c]const wasmtime_eqref_t, out: [*c]wasmtime_anyref_t) void;
pub extern fn wasmtime_eqref_from_i31(context: ?*wasmtime_context_t, i31val: u32, out: [*c]wasmtime_eqref_t) void;
pub extern fn wasmtime_eqref_is_i31(context: ?*wasmtime_context_t, eqref: [*c]const wasmtime_eqref_t) bool;
pub extern fn wasmtime_eqref_i31_get_u(context: ?*wasmtime_context_t, eqref: [*c]const wasmtime_eqref_t, dst: [*c]u32) bool;
pub extern fn wasmtime_eqref_i31_get_s(context: ?*wasmtime_context_t, eqref: [*c]const wasmtime_eqref_t, dst: [*c]i32) bool;
pub extern fn wasmtime_eqref_is_array(context: ?*wasmtime_context_t, eqref: [*c]const wasmtime_eqref_t) bool;
pub extern fn wasmtime_eqref_as_array(context: ?*wasmtime_context_t, eqref: [*c]const wasmtime_eqref_t, out: [*c]wasmtime_arrayref_t) bool;
pub extern fn wasmtime_eqref_is_struct(context: ?*wasmtime_context_t, eqref: [*c]const wasmtime_eqref_t) bool;
pub extern fn wasmtime_eqref_as_struct(context: ?*wasmtime_context_t, eqref: [*c]const wasmtime_eqref_t, out: [*c]wasmtime_structref_t) bool;
pub extern fn wasmtime_eqref_type(context: ?*wasmtime_context_t, eqref: [*c]const wasmtime_eqref_t, out: [*c]wasmtime_heaptype_t) bool;
pub extern fn wasmtime_exnref_new(store: ?*wasmtime_context_t, tag: [*c]const wasmtime_tag_t, fields: [*c]const wasmtime_val_t, nfields: usize, exn_ret: [*c]wasmtime_exnref_t) ?*wasmtime_error_t;
pub fn wasmtime_exnref_set_null(arg_ref: [*c]wasmtime_exnref_t) callconv(.c) void {
    var ref = arg_ref;
    _ = &ref;
    ref.*.store_id = 0;
}
pub fn wasmtime_exnref_is_null(arg_ref: [*c]const wasmtime_exnref_t) callconv(.c) bool {
    var ref = arg_ref;
    _ = &ref;
    return ref.*.store_id == @as(u64, 0);
}
pub extern fn wasmtime_exnref_clone(ref: [*c]const wasmtime_exnref_t, out: [*c]wasmtime_exnref_t) void;
pub extern fn wasmtime_exnref_unroot(ref: [*c]wasmtime_exnref_t) void;
pub extern fn wasmtime_exnref_from_raw(context: ?*wasmtime_context_t, raw: u32, out: [*c]wasmtime_exnref_t) void;
pub extern fn wasmtime_exnref_to_raw(context: ?*wasmtime_context_t, ref: [*c]const wasmtime_exnref_t) u32;
pub extern fn wasmtime_exnref_tag(store: ?*wasmtime_context_t, exn: [*c]const wasmtime_exnref_t, tag_ret: [*c]wasmtime_tag_t) ?*wasmtime_error_t;
pub extern fn wasmtime_exnref_field_count(store: ?*wasmtime_context_t, exn: [*c]const wasmtime_exnref_t) usize;
pub extern fn wasmtime_exnref_field(store: ?*wasmtime_context_t, exn: [*c]const wasmtime_exnref_t, index: usize, val_ret: [*c]wasmtime_val_t) ?*wasmtime_error_t;
pub extern fn wasmtime_context_set_exception(store: ?*wasmtime_context_t, exn: [*c]const wasmtime_exnref_t) ?*wasm_trap_t;
pub extern fn wasmtime_context_take_exception(store: ?*wasmtime_context_t, exn_ret: [*c]wasmtime_exnref_t) bool;
pub extern fn wasmtime_context_has_exception(store: ?*wasmtime_context_t) bool;
pub extern fn wasmtime_exnref_type(context: ?*wasmtime_context_t, exnref: [*c]const wasmtime_exnref_t) ?*wasmtime_exn_type_t;
pub fn wasmtime_externref_set_null(arg_ref: [*c]wasmtime_externref_t) callconv(.c) void {
    var ref = arg_ref;
    _ = &ref;
    ref.*.store_id = 0;
}
pub fn wasmtime_externref_is_null(arg_ref: [*c]const wasmtime_externref_t) callconv(.c) bool {
    var ref = arg_ref;
    _ = &ref;
    return ref.*.store_id == @as(u64, 0);
}
pub extern fn wasmtime_externref_new(context: ?*wasmtime_context_t, data: ?*anyopaque, finalizer: ?*const fn (?*anyopaque) callconv(.c) void, out: [*c]wasmtime_externref_t) bool;
pub extern fn wasmtime_externref_data(context: ?*wasmtime_context_t, data: [*c]const wasmtime_externref_t) ?*anyopaque;
pub extern fn wasmtime_externref_clone(ref: [*c]const wasmtime_externref_t, out: [*c]wasmtime_externref_t) void;
pub extern fn wasmtime_externref_unroot(ref: [*c]wasmtime_externref_t) void;
pub extern fn wasmtime_externref_from_raw(context: ?*wasmtime_context_t, raw: u32, out: [*c]wasmtime_externref_t) void;
pub extern fn wasmtime_externref_to_raw(context: ?*wasmtime_context_t, ref: [*c]const wasmtime_externref_t) u32;
pub extern fn wasmtime_global_new(store: ?*wasmtime_context_t, @"type": ?*const wasm_globaltype_t, val: [*c]const wasmtime_val_t, ret: [*c]wasmtime_global_t) ?*wasmtime_error_t;
pub extern fn wasmtime_global_type(store: ?*const wasmtime_context_t, global: [*c]const wasmtime_global_t) ?*wasm_globaltype_t;
pub extern fn wasmtime_global_get(store: ?*wasmtime_context_t, global: [*c]const wasmtime_global_t, out: [*c]wasmtime_val_t) void;
pub extern fn wasmtime_global_set(store: ?*wasmtime_context_t, global: [*c]const wasmtime_global_t, val: [*c]const wasmtime_val_t) ?*wasmtime_error_t;
pub extern fn wasmtime_memorytype_new(min: u64, max_present: bool, max: u64, is_64: bool, shared: bool, page_size_log2: u8, ret: [*c]?*wasm_memorytype_t) ?*wasmtime_error_t;
pub extern fn wasmtime_memorytype_minimum(ty: ?*const wasm_memorytype_t) u64;
pub extern fn wasmtime_memorytype_maximum(ty: ?*const wasm_memorytype_t, max: [*c]u64) bool;
pub extern fn wasmtime_memorytype_is64(ty: ?*const wasm_memorytype_t) bool;
pub extern fn wasmtime_memorytype_isshared(ty: ?*const wasm_memorytype_t) bool;
pub extern fn wasmtime_memorytype_page_size(ty: ?*const wasm_memorytype_t) u64;
pub extern fn wasmtime_memorytype_page_size_log2(ty: ?*const wasm_memorytype_t) u8;
pub extern fn wasmtime_memory_new(store: ?*wasmtime_context_t, ty: ?*const wasm_memorytype_t, ret: [*c]wasmtime_memory_t) ?*wasmtime_error_t;
pub extern fn wasmtime_memory_type(store: ?*const wasmtime_context_t, memory: [*c]const wasmtime_memory_t) ?*wasm_memorytype_t;
pub extern fn wasmtime_memory_data(store: ?*wasmtime_context_t, memory: [*c]const wasmtime_memory_t) [*c]u8;
pub extern fn wasmtime_memory_data_size(store: ?*const wasmtime_context_t, memory: [*c]const wasmtime_memory_t) usize;
pub extern fn wasmtime_memory_size(store: ?*const wasmtime_context_t, memory: [*c]const wasmtime_memory_t) u64;
pub extern fn wasmtime_memory_grow(store: ?*wasmtime_context_t, memory: [*c]const wasmtime_memory_t, delta: u64, prev_size: [*c]u64) ?*wasmtime_error_t;
pub extern fn wasmtime_memory_page_size(store: ?*wasmtime_context_t, memory: [*c]const wasmtime_memory_t) u64;
pub extern fn wasmtime_memory_page_size_log2(store: ?*wasmtime_context_t, memory: [*c]const wasmtime_memory_t) u8;
pub const struct_wasmtime_guestprofiler = opaque {
    pub const wasmtime_guestprofiler_delete = __root.wasmtime_guestprofiler_delete;
    pub const wasmtime_guestprofiler_sample = __root.wasmtime_guestprofiler_sample;
    pub const wasmtime_guestprofiler_finish = __root.wasmtime_guestprofiler_finish;
    pub const delete = __root.wasmtime_guestprofiler_delete;
    pub const sample = __root.wasmtime_guestprofiler_sample;
    pub const finish = __root.wasmtime_guestprofiler_finish;
};
pub const wasmtime_guestprofiler_t = struct_wasmtime_guestprofiler;
pub extern fn wasmtime_guestprofiler_delete(guestprofiler: ?*wasmtime_guestprofiler_t) void;
pub const struct_wasmtime_guestprofiler_modules = extern struct {
    name: [*c]const wasm_name_t,
    mod: ?*const wasmtime_module_t,
};
pub const wasmtime_guestprofiler_modules_t = struct_wasmtime_guestprofiler_modules;
pub extern fn wasmtime_guestprofiler_new(engine: ?*const wasm_engine_t, module_name: [*c]const wasm_name_t, interval_nanos: u64, modules: [*c]const wasmtime_guestprofiler_modules_t, modules_len: usize) ?*wasmtime_guestprofiler_t;
pub extern fn wasmtime_guestprofiler_sample(guestprofiler: ?*wasmtime_guestprofiler_t, store: ?*const wasmtime_store_t, delta_nanos: u64) void;
pub extern fn wasmtime_guestprofiler_finish(guestprofiler: ?*wasmtime_guestprofiler_t, out: [*c]wasm_byte_vec_t) ?*wasmtime_error_t;
pub const struct_wasmtime_struct_ref_pre = opaque {
    pub const wasmtime_struct_ref_pre_delete = __root.wasmtime_struct_ref_pre_delete;
    pub const delete = __root.wasmtime_struct_ref_pre_delete;
};
pub const wasmtime_struct_ref_pre_t = struct_wasmtime_struct_ref_pre;
pub extern fn wasmtime_struct_ref_pre_new(context: ?*wasmtime_context_t, ty: ?*const wasmtime_struct_type_t) ?*wasmtime_struct_ref_pre_t;
pub extern fn wasmtime_struct_ref_pre_delete(pre: ?*wasmtime_struct_ref_pre_t) void;
pub fn wasmtime_structref_set_null(arg_ref: [*c]wasmtime_structref_t) callconv(.c) void {
    var ref = arg_ref;
    _ = &ref;
    ref.*.store_id = 0;
}
pub fn wasmtime_structref_is_null(arg_ref: [*c]const wasmtime_structref_t) callconv(.c) bool {
    var ref = arg_ref;
    _ = &ref;
    return ref.*.store_id == @as(u64, 0);
}
pub extern fn wasmtime_structref_new(context: ?*wasmtime_context_t, pre: ?*const wasmtime_struct_ref_pre_t, fields: [*c]const wasmtime_val_t, nfields: usize, out: [*c]wasmtime_structref_t) ?*wasmtime_error_t;
pub extern fn wasmtime_structref_clone(structref: [*c]const wasmtime_structref_t, out: [*c]wasmtime_structref_t) void;
pub extern fn wasmtime_structref_unroot(ref: [*c]wasmtime_structref_t) void;
pub extern fn wasmtime_structref_to_anyref(structref: [*c]const wasmtime_structref_t, out: [*c]wasmtime_anyref_t) void;
pub extern fn wasmtime_structref_to_eqref(structref: [*c]const wasmtime_structref_t, out: [*c]wasmtime_eqref_t) void;
pub extern fn wasmtime_structref_field(context: ?*wasmtime_context_t, structref: [*c]const wasmtime_structref_t, index: usize, out: [*c]wasmtime_val_t) ?*wasmtime_error_t;
pub extern fn wasmtime_structref_set_field(context: ?*wasmtime_context_t, structref: [*c]const wasmtime_structref_t, index: usize, val: [*c]const wasmtime_val_t) ?*wasmtime_error_t;
pub extern fn wasmtime_structref_type(context: ?*wasmtime_context_t, structref: [*c]const wasmtime_structref_t) ?*wasmtime_struct_type_t;
pub extern fn wasmtime_table_new(store: ?*wasmtime_context_t, ty: ?*const wasm_tabletype_t, init: [*c]const wasmtime_val_t, table: [*c]wasmtime_table_t) ?*wasmtime_error_t;
pub extern fn wasmtime_table_type(store: ?*const wasmtime_context_t, table: [*c]const wasmtime_table_t) ?*wasm_tabletype_t;
pub extern fn wasmtime_table_get(store: ?*wasmtime_context_t, table: [*c]const wasmtime_table_t, index: u64, val: [*c]wasmtime_val_t) bool;
pub extern fn wasmtime_table_set(store: ?*wasmtime_context_t, table: [*c]const wasmtime_table_t, index: u64, value: [*c]const wasmtime_val_t) ?*wasmtime_error_t;
pub extern fn wasmtime_table_size(store: ?*const wasmtime_context_t, table: [*c]const wasmtime_table_t) u64;
pub extern fn wasmtime_table_grow(store: ?*wasmtime_context_t, table: [*c]const wasmtime_table_t, delta: u64, init: [*c]const wasmtime_val_t, prev_size: [*c]u64) ?*wasmtime_error_t;
pub const wasmtime_trap_code_t = u8;
pub const WASMTIME_TRAP_CODE_STACK_OVERFLOW: c_int = 0;
pub const WASMTIME_TRAP_CODE_MEMORY_OUT_OF_BOUNDS: c_int = 1;
pub const WASMTIME_TRAP_CODE_HEAP_MISALIGNED: c_int = 2;
pub const WASMTIME_TRAP_CODE_TABLE_OUT_OF_BOUNDS: c_int = 3;
pub const WASMTIME_TRAP_CODE_INDIRECT_CALL_TO_NULL: c_int = 4;
pub const WASMTIME_TRAP_CODE_BAD_SIGNATURE: c_int = 5;
pub const WASMTIME_TRAP_CODE_INTEGER_OVERFLOW: c_int = 6;
pub const WASMTIME_TRAP_CODE_INTEGER_DIVISION_BY_ZERO: c_int = 7;
pub const WASMTIME_TRAP_CODE_BAD_CONVERSION_TO_INTEGER: c_int = 8;
pub const WASMTIME_TRAP_CODE_UNREACHABLE_CODE_REACHED: c_int = 9;
pub const WASMTIME_TRAP_CODE_INTERRUPT: c_int = 10;
pub const WASMTIME_TRAP_CODE_OUT_OF_FUEL: c_int = 11;
pub const WASMTIME_TRAP_CODE_ATOMIC_WAIT_NON_SHARED_MEMORY: c_int = 12;
pub const WASMTIME_TRAP_CODE_NULL_REFERENCE: c_int = 13;
pub const WASMTIME_TRAP_CODE_ARRAY_OUT_OF_BOUNDS: c_int = 14;
pub const WASMTIME_TRAP_CODE_ALLOCATION_TOO_LARGE: c_int = 15;
pub const WASMTIME_TRAP_CODE_CAST_FAILURE: c_int = 16;
pub const WASMTIME_TRAP_CODE_CANNOT_ENTER_COMPONENT: c_int = 17;
pub const WASMTIME_TRAP_CODE_NO_ASYNC_RESULT: c_int = 18;
pub const WASMTIME_TRAP_CODE_UNHANDLED_TAG: c_int = 19;
pub const WASMTIME_TRAP_CODE_CONTINUATION_ALREADY_CONSUMED: c_int = 20;
pub const WASMTIME_TRAP_CODE_DISABLED_OPCODE: c_int = 21;
pub const WASMTIME_TRAP_CODE_ASYNC_DEADLOCK: c_int = 22;
pub const WASMTIME_TRAP_CODE_CANNOT_LEAVE_COMPONENT: c_int = 23;
pub const WASMTIME_TRAP_CODE_CANNOT_BLOCK_SYNC_TASK: c_int = 24;
pub const WASMTIME_TRAP_CODE_INVALID_CHAR: c_int = 25;
pub const WASMTIME_TRAP_CODE_DEBUG_ASSERT_STRING_ENCODING_FINISHED: c_int = 26;
pub const WASMTIME_TRAP_CODE_DEBUG_ASSERT_EQUAL_CODE_UNITS: c_int = 27;
pub const WASMTIME_TRAP_CODE_DEBUG_ASSERT_POINTER_ALIGNED: c_int = 28;
pub const WASMTIME_TRAP_CODE_DEBUG_ASSERT_UPPER_BITS_UNSET: c_int = 29;
pub const WASMTIME_TRAP_CODE_STRING_OUT_OF_BOUNDS: c_int = 30;
pub const WASMTIME_TRAP_CODE_LIST_OUT_OF_BOUNDS: c_int = 31;
pub const WASMTIME_TRAP_CODE_INVALID_DISCRIMINANT: c_int = 32;
pub const WASMTIME_TRAP_CODE_UNALIGNED_POINTER: c_int = 33;
pub const WASMTIME_TRAP_CODE_TASK_CANCEL_NOT_CANCELLED: c_int = 34;
pub const WASMTIME_TRAP_CODE_TASK_CANCEL_OR_RETURN_TWICE: c_int = 35;
pub const WASMTIME_TRAP_CODE_SUBTASK_CANCEL_AFTER_TERMINAL: c_int = 36;
pub const WASMTIME_TRAP_CODE_TASK_RETURN_INVALID: c_int = 37;
pub const WASMTIME_TRAP_CODE_WAITABLE_SET_DROP_HAS_WAITERS: c_int = 38;
pub const WASMTIME_TRAP_CODE_SUBTASK_DROP_NOT_RESOLVED: c_int = 39;
pub const WASMTIME_TRAP_CODE_THREAD_NEW_INDIRECT_INVALID_TYPE: c_int = 40;
pub const WASMTIME_TRAP_CODE_THREAD_NEW_INDIRECT_UNINITIALIZED: c_int = 41;
pub const WASMTIME_TRAP_CODE_BACKPRESSURE_OVERFLOW: c_int = 42;
pub const WASMTIME_TRAP_CODE_UNSUPPORTED_CALLBACK_CODE: c_int = 43;
pub const WASMTIME_TRAP_CODE_CANNOT_RESUME_THREAD: c_int = 44;
pub const WASMTIME_TRAP_CODE_CONCURRENT_FUTURE_STREAM_OP: c_int = 45;
pub const WASMTIME_TRAP_CODE_REFERENCE_COUNT_OVERFLOW: c_int = 46;
pub const WASMTIME_TRAP_CODE_STREAM_OP_TOO_BIG: c_int = 47;
pub const WASMTIME_TRAP_CODE_WAITABLE_SYNC_AND_ASYNC: c_int = 48;
pub const WASMTIME_TRAP_CODE_UNCAUGHT_EXCEPTION: c_int = 49;
pub const WASMTIME_TRAP_READ_FROM_DROPPED_STREAM: c_int = 50;
pub const WASMTIME_TRAP_WRITE_TO_DROPPED_STREAM: c_int = 51;
pub const WASMTIME_TRAP_WRITE_TO_DROPPED_FUTURE: c_int = 52;
pub const WASMTIME_TRAP_LIFT_DROPPED_STREAM: c_int = 53;
pub const enum_wasmtime_trap_code_enum = c_uint;
pub extern fn wasmtime_trap_new(msg: [*c]const u8, msg_len: usize) ?*wasm_trap_t;
pub extern fn wasmtime_trap_new_code(code: wasmtime_trap_code_t) ?*wasm_trap_t;
pub extern fn wasmtime_trap_code(?*const wasm_trap_t, code: [*c]wasmtime_trap_code_t) bool;
pub extern fn wasmtime_frame_func_name(?*const wasm_frame_t) [*c]const wasm_name_t;
pub extern fn wasmtime_frame_module_name(?*const wasm_frame_t) [*c]const wasm_name_t;
pub extern fn wasmtime_wat2wasm(wat: [*c]const u8, wat_len: usize, ret: [*c]wasm_byte_vec_t) ?*wasmtime_error_t;

pub const __VERSION__ = "Aro 0.0.0";
pub const __Aro__ = "";
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __GNUC__ = @as(c_int, 7);
pub const __GNUC_MINOR__ = @as(c_int, 1);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 0);
pub const __ARO_EMULATE_NO__ = @as(c_int, 0);
pub const __ARO_EMULATE_CLANG__ = @as(c_int, 1);
pub const __ARO_EMULATE_GCC__ = @as(c_int, 2);
pub const __ARO_EMULATE_MSVC__ = @as(c_int, 3);
pub const __ARO_EMULATE__ = __ARO_EMULATE_NO__;
pub inline fn __building_module(x: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &x;
    return @as(c_int, 0);
}
pub const TARGET_OS_WIN32 = @as(c_int, 0);
pub const TARGET_OS_WINDOWS = @as(c_int, 0);
pub const TARGET_OS_LINUX = @as(c_int, 1);
pub const TARGET_OS_UNIX = @as(c_int, 0);
pub const TARGET_OS_MAC = @as(c_int, 0);
pub const TARGET_OS_OSX = @as(c_int, 0);
pub const TARGET_OS_IPHONE = @as(c_int, 0);
pub const TARGET_OS_IOS = @as(c_int, 0);
pub const TARGET_OS_TV = @as(c_int, 0);
pub const TARGET_OS_WATCH = @as(c_int, 0);
pub const TARGET_OS_VISION = @as(c_int, 0);
pub const TARGET_OS_DRIVERKIT = @as(c_int, 0);
pub const TARGET_OS_MACCATALYST = @as(c_int, 0);
pub const TARGET_OS_SIMULATOR = @as(c_int, 0);
pub const TARGET_OS_EMBEDDED = @as(c_int, 0);
pub const TARGET_OS_NANO = @as(c_int, 0);
pub const TARGET_IPHONE_SIMULATOR = @as(c_int, 0);
pub const TARGET_OS_UIKITFORMAC = @as(c_int, 0);
pub const TARGET_OS_UEFI = @as(c_int, 0);
pub const linux = @as(c_int, 1);
pub const __linux = @as(c_int, 1);
pub const __linux__ = @as(c_int, 1);
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`");
// <builtin>:52:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`");
// <builtin>:53:9
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MWAITX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __SSE4A__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __SHA__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLZERO__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __FLOAT128__ = @as(c_int, 1);
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __ELF__ = @as(c_int, 1);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __ATOMIC_BOOL_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WINT_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_SHORT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_INT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LLONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_POINTER_LOCK_FREE = @as(c_int, 1);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SCHAR_WIDTH__ = @as(c_int, 8);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __LONG_LONG_WIDTH__ = @as(c_int, 64);
pub const __WCHAR_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIG_ATOMIC_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __BITINT_MAXWIDTH__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 10);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTPTR_TYPE__ = c_long;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// <builtin>:167:9
pub const __INTMAX_C = __helpers.L_SUFFIX;
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// <builtin>:170:9
pub const __UINTMAX_C = __helpers.UL_SUFFIX;
pub const __PTRDIFF_TYPE__ = c_long;
pub const __SIZE_TYPE__ = c_ulong;
pub const __WCHAR_TYPE__ = c_int;
pub const __WINT_TYPE__ = c_uint;
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub inline fn __INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub inline fn __INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub inline fn __INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT64_TYPE__ = c_long;
pub const __INT64_FMTd__ = "ld";
pub const __INT64_FMTi__ = "li";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// <builtin>:196:9
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub inline fn __UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub inline fn __UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`");
// <builtin>:221:9
pub const __UINT32_C = __helpers.U_SUFFIX;
pub const __UINT32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulong;
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// <builtin>:230:9
pub const __UINT64_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __INT64_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const INT_LEAST8_FMTd__ = "hhd";
pub const INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const UINT_LEAST8_FMTo__ = "hho";
pub const UINT_LEAST8_FMTu__ = "hhu";
pub const UINT_LEAST8_FMTx__ = "hhx";
pub const UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const INT_FAST8_FMTd__ = "hhd";
pub const INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const UINT_FAST8_FMTo__ = "hho";
pub const UINT_FAST8_FMTu__ = "hhu";
pub const UINT_FAST8_FMTx__ = "hhx";
pub const UINT_FAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const INT_LEAST16_FMTd__ = "hd";
pub const INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST16_FMTo__ = "ho";
pub const UINT_LEAST16_FMTu__ = "hu";
pub const UINT_LEAST16_FMTx__ = "hx";
pub const UINT_LEAST16_FMTX__ = "hX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const INT_FAST16_FMTd__ = "hd";
pub const INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_FAST16_FMTo__ = "ho";
pub const UINT_FAST16_FMTu__ = "hu";
pub const UINT_FAST16_FMTx__ = "hx";
pub const UINT_FAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const INT_LEAST32_FMTd__ = "d";
pub const INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST32_FMTo__ = "o";
pub const UINT_LEAST32_FMTu__ = "u";
pub const UINT_LEAST32_FMTx__ = "x";
pub const UINT_LEAST32_FMTX__ = "X";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const INT_FAST32_FMTd__ = "d";
pub const INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_FAST32_FMTo__ = "o";
pub const UINT_FAST32_FMTu__ = "u";
pub const UINT_FAST32_FMTx__ = "x";
pub const UINT_FAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_long;
pub const __INT_LEAST64_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const INT_LEAST64_FMTd__ = "ld";
pub const INT_LEAST64_FMTi__ = "li";
pub const __UINT_LEAST64_TYPE__ = c_ulong;
pub const __UINT_LEAST64_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_LEAST64_FMTo__ = "lo";
pub const UINT_LEAST64_FMTu__ = "lu";
pub const UINT_LEAST64_FMTx__ = "lx";
pub const UINT_LEAST64_FMTX__ = "lX";
pub const __INT_FAST64_TYPE__ = c_long;
pub const __INT_FAST64_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const INT_FAST64_FMTd__ = "ld";
pub const INT_FAST64_FMTi__ = "li";
pub const __UINT_FAST64_TYPE__ = c_ulong;
pub const __UINT_FAST64_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST64_FMTo__ = "lo";
pub const UINT_FAST64_FMTu__ = "lu";
pub const UINT_FAST64_FMTx__ = "lx";
pub const UINT_FAST64_FMTX__ = "lX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_HAS_DENORM__ = "";
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = "";
pub const __FLT16_HAS_QUIET_NAN__ = "";
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = "";
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = "";
pub const __FLT_HAS_QUIET_NAN__ = "";
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_HAS_DENORM__ = "";
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = "";
pub const __DBL_HAS_QUIET_NAN__ = "";
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_HAS_DENORM__ = "";
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = "";
pub const __LDBL_HAS_QUIET_NAN__ = "";
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __GLIBC_MINOR__ = @as(c_int, 43);
pub const WASM_H = "";
pub const __STDC_VERSION_STDDEF_H__ = @as(c_long, 202311);
pub const NULL = __helpers.cast(?*anyopaque, @as(c_int, 0));
pub const offsetof = @compileError("unable to translate macro: undefined identifier `__builtin_offsetof`");
// zig-pkg/aro-0.0.0-JSD1QtuBNwCASyBtNF3pqTl_W3oAJQGEVyFAtrBSE_Pa/include/stddef.h:18:9
pub const _STDINT_H = @as(c_int, 1);
pub const _FEATURES_H = @as(c_int, 1);
pub const __KERNEL_STRICT_NAMES = "";
pub inline fn __GNUC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    _ = &maj;
    _ = &min;
    return ((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub inline fn __glibc_clang_prereq(maj: anytype, min: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &maj;
    _ = &min;
    return @as(c_int, 0);
}
pub const __GLIBC_USE = @compileError("unable to translate macro: undefined identifier `__GLIBC_USE_`");
// /usr/include/features.h:197:9
pub const _DEFAULT_SOURCE = @as(c_int, 1);
pub const __GLIBC_USE_ISOC2Y = @as(c_int, 0);
pub const __GLIBC_USE_ISOC23 = @as(c_int, 0);
pub const __USE_ISOC11 = @as(c_int, 1);
pub const __USE_POSIX_IMPLICITLY = @as(c_int, 1);
pub const _POSIX_SOURCE = @as(c_int, 1);
pub const _POSIX_C_SOURCE = @as(c_long, 202405);
pub const __USE_POSIX = @as(c_int, 1);
pub const __USE_POSIX2 = @as(c_int, 1);
pub const __USE_POSIX199309 = @as(c_int, 1);
pub const __USE_POSIX199506 = @as(c_int, 1);
pub const __USE_XOPEN2K = @as(c_int, 1);
pub const __USE_ISOC95 = @as(c_int, 1);
pub const __USE_ISOC99 = @as(c_int, 1);
pub const __USE_XOPEN2K8 = @as(c_int, 1);
pub const _ATFILE_SOURCE = @as(c_int, 1);
pub const __USE_XOPEN2K24 = @as(c_int, 1);
pub const __WORDSIZE = @as(c_int, 64);
pub const __WORDSIZE_TIME64_COMPAT32 = @as(c_int, 1);
pub const __SYSCALL_WORDSIZE = @as(c_int, 64);
pub const __TIMESIZE = __WORDSIZE;
pub const __USE_TIME_BITS64 = @as(c_int, 1);
pub const __USE_MISC = @as(c_int, 1);
pub const __USE_ATFILE = @as(c_int, 1);
pub const __USE_FORTIFY_LEVEL = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_GETS = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_SCANF = @as(c_int, 0);
pub const __GLIBC_USE_C23_STRTOL = @as(c_int, 0);
pub const _STDC_PREDEF_H = @as(c_int, 1);
pub const __STDC_IEC_559__ = @as(c_int, 1);
pub const __STDC_IEC_60559_BFP__ = @as(c_long, 201404);
pub const __STDC_IEC_559_COMPLEX__ = @as(c_int, 1);
pub const __STDC_IEC_60559_COMPLEX__ = @as(c_long, 201404);
pub const __STDC_ISO_10646__ = @as(c_long, 201706);
pub const __GNU_LIBRARY__ = @as(c_int, 6);
pub const __GLIBC__ = @as(c_int, 2);
pub inline fn __GLIBC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    _ = &maj;
    _ = &min;
    return ((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub const _SYS_CDEFS_H = @as(c_int, 1);
pub const __glibc_has_attribute = @compileError("unable to translate macro: undefined identifier `__has_attribute`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:45:10
pub inline fn __glibc_has_builtin(name: anytype) @TypeOf(__builtin.has_builtin(name)) {
    _ = &name;
    return __builtin.has_builtin(name);
}
pub const __glibc_has_extension = @compileError("unable to translate macro: undefined identifier `__has_extension`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:55:10
pub const __LEAF = @compileError("unable to translate macro: undefined identifier `__leaf__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:65:11
pub const __LEAF_ATTR = @compileError("unable to translate macro: undefined identifier `__leaf__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:66:11
pub const __THROW = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:79:11
pub const __THROWNL = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:80:11
pub const __NTH = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:81:11
pub const __NTHNL = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:82:11
pub const __COLD = @compileError("unable to translate macro: undefined identifier `__cold__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:102:11
pub inline fn __P(args: anytype) @TypeOf(args) {
    _ = &args;
    return args;
}
pub inline fn __PMT(args: anytype) @TypeOf(args) {
    _ = &args;
    return args;
}
pub const __CONCAT = @compileError("unable to translate C expr: unexpected token '##'");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:131:9
pub const __STRING = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:132:9
pub const __ptr_t = ?*anyopaque;
pub const __BEGIN_DECLS = "";
pub const __END_DECLS = "";
pub const __attribute_overloadable__ = "";
pub inline fn __bos(ptr: anytype) @TypeOf(__builtin.object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1))) {
    _ = &ptr;
    return __builtin.object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1));
}
pub inline fn __bos0(ptr: anytype) @TypeOf(__builtin.object_size(ptr, @as(c_int, 0))) {
    _ = &ptr;
    return __builtin.object_size(ptr, @as(c_int, 0));
}
pub inline fn __glibc_objsize0(__o: anytype) @TypeOf(__bos0(__o)) {
    _ = &__o;
    return __bos0(__o);
}
pub inline fn __glibc_objsize(__o: anytype) @TypeOf(__bos(__o)) {
    _ = &__o;
    return __bos(__o);
}
pub const __warnattr = @compileError("unable to translate macro: undefined identifier `__warning__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:366:10
pub const __errordecl = @compileError("unable to translate macro: undefined identifier `__error__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:367:10
pub const __flexarr = @compileError("unable to translate C expr: unexpected token '['");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:379:10
pub const __glibc_c99_flexarr_available = @as(c_int, 1);
pub const __REDIRECT = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:410:10
pub const __REDIRECT_NTH = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:417:11
pub const __REDIRECT_NTHNL = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:419:11
pub const __ASMNAME = @compileError("unable to translate macro: undefined identifier `__USER_LABEL_PREFIX__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:422:10
pub inline fn __ASMNAME2(prefix: anytype, cname: anytype) @TypeOf(__STRING(prefix) ++ cname) {
    _ = &prefix;
    _ = &cname;
    return __STRING(prefix) ++ cname;
}
pub const __REDIRECT_FORTIFY = __REDIRECT;
pub const __REDIRECT_FORTIFY_NTH = __REDIRECT_NTH;
pub const __attribute_malloc__ = @compileError("unable to translate macro: undefined identifier `__malloc__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:452:10
pub const __attribute_alloc_size__ = @compileError("unable to translate macro: undefined identifier `__alloc_size__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:460:10
pub const __attribute_alloc_align__ = @compileError("unable to translate macro: undefined identifier `__alloc_align__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:469:10
pub const __attribute_pure__ = @compileError("unable to translate macro: undefined identifier `__pure__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:479:10
pub const __attribute_const__ = @compileError("unable to translate C expr: unexpected token '__attribute__'");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:486:10
pub const __attribute_maybe_unused__ = @compileError("unable to translate macro: undefined identifier `__unused__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:492:10
pub const __attribute_used__ = @compileError("unable to translate macro: undefined identifier `__used__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:501:10
pub const __attribute_noinline__ = @compileError("unable to translate macro: undefined identifier `__noinline__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:502:10
pub const __attribute_deprecated__ = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:510:10
pub const __attribute_deprecated_msg__ = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:520:10
pub const __attribute_format_arg__ = @compileError("unable to translate macro: undefined identifier `__format_arg__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:533:10
pub const __attribute_format_strfmon__ = @compileError("unable to translate macro: undefined identifier `__format__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:543:10
pub const __attribute_nonnull__ = @compileError("unable to translate macro: undefined identifier `__nonnull__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:555:11
pub inline fn __nonnull(params: anytype) @TypeOf(__attribute_nonnull__(params)) {
    _ = &params;
    return __attribute_nonnull__(params);
}
pub const __returns_nonnull = @compileError("unable to translate macro: undefined identifier `__returns_nonnull__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:568:10
pub const __attribute_warn_unused_result__ = @compileError("unable to translate macro: undefined identifier `__warn_unused_result__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:577:10
pub const __wur = "";
pub const __always_inline = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:595:10
pub const __attribute_artificial__ = @compileError("unable to translate macro: undefined identifier `__artificial__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:604:10
pub const __extern_inline = @compileError("unable to translate C expr: unexpected token 'extern'");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:626:11
pub const __extern_always_inline = @compileError("unable to translate C expr: unexpected token 'extern'");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:627:11
pub const __fortify_function = __extern_always_inline ++ __attribute_artificial__;
pub const __va_arg_pack = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg_pack`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:638:10
pub const __va_arg_pack_len = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg_pack_len`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:639:10
pub const __restrict_arr = @compileError("unable to translate C expr: unexpected token '__restrict'");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:666:10
pub inline fn __glibc_unlikely(cond: anytype) @TypeOf(__builtin.expect(cond, @as(c_int, 0))) {
    _ = &cond;
    return __builtin.expect(cond, @as(c_int, 0));
}
pub inline fn __glibc_likely(cond: anytype) @TypeOf(__builtin.expect(cond, @as(c_int, 1))) {
    _ = &cond;
    return __builtin.expect(cond, @as(c_int, 1));
}
pub const __attribute_nonstring__ = "";
pub inline fn __attribute_copy__(arg: anytype) void {
    _ = &arg;
    return;
}
pub const __LDOUBLE_REDIRECTS_TO_FLOAT128_ABI = @as(c_int, 0);
pub inline fn __LDBL_REDIR1(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return name ++ proto;
}
pub inline fn __LDBL_REDIR(name: anytype, proto: anytype) @TypeOf(name ++ proto) {
    _ = &name;
    _ = &proto;
    return name ++ proto;
}
pub inline fn __LDBL_REDIR1_NTH(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto ++ __THROW) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return name ++ proto ++ __THROW;
}
pub inline fn __LDBL_REDIR_NTH(name: anytype, proto: anytype) @TypeOf(name ++ proto ++ __THROW) {
    _ = &name;
    _ = &proto;
    return name ++ proto ++ __THROW;
}
pub inline fn __LDBL_REDIR2_DECL(name: anytype) void {
    _ = &name;
    return;
}
pub inline fn __LDBL_REDIR_DECL(name: anytype) void {
    _ = &name;
    return;
}
pub inline fn __REDIRECT_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT(name, proto, alias)) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return __REDIRECT(name, proto, alias);
}
pub inline fn __REDIRECT_NTH_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT_NTH(name, proto, alias)) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return __REDIRECT_NTH(name, proto, alias);
}
pub const __glibc_macro_warning1 = @compileError("unable to translate macro: undefined identifier `_Pragma`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:807:10
pub const __glibc_macro_warning = @compileError("unable to translate macro: undefined identifier `GCC`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:808:10
pub const __HAVE_GENERIC_SELECTION = @as(c_int, 1);
pub const __glibc_const_generic = @compileError("unable to translate C expr: expected type instead got 'const'");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:837:10
pub inline fn __fortified_attr_access(a: anytype, o: anytype, s: anytype) void {
    _ = &a;
    _ = &o;
    _ = &s;
    return;
}
pub inline fn __attr_access(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __attr_access_none(argno: anytype) void {
    _ = &argno;
    return;
}
pub inline fn __attr_dealloc(dealloc: anytype, argno: anytype) void {
    _ = &dealloc;
    _ = &argno;
    return;
}
pub const __attr_dealloc_free = "";
pub const __attribute_returns_twice__ = @compileError("unable to translate macro: undefined identifier `__returns_twice__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:884:10
pub const __attribute_struct_may_alias__ = @compileError("unable to translate macro: undefined identifier `__may_alias__`");
// /usr/include/x86_64-linux-gnu/sys/cdefs.h:893:10
pub const __stub___compat_bdflush = "";
pub const __stub_chflags = "";
pub const __stub_fchflags = "";
pub const __stub_gtty = "";
pub const __stub_revoke = "";
pub const __stub_setlogin = "";
pub const __stub_sigreturn = "";
pub const __stub_stty = "";
pub const _BITS_TYPES_H = @as(c_int, 1);
pub const __S16_TYPE = c_short;
pub const __U16_TYPE = c_ushort;
pub const __S32_TYPE = c_int;
pub const __U32_TYPE = c_uint;
pub const __SLONGWORD_TYPE = c_long;
pub const __ULONGWORD_TYPE = c_ulong;
pub const __SQUAD_TYPE = c_long;
pub const __UQUAD_TYPE = c_ulong;
pub const __SWORD_TYPE = c_long;
pub const __UWORD_TYPE = c_ulong;
pub const __SLONG32_TYPE = c_int;
pub const __ULONG32_TYPE = c_uint;
pub const __S64_TYPE = c_long;
pub const __U64_TYPE = c_ulong;
pub const _BITS_TYPESIZES_H = @as(c_int, 1);
pub const __SYSCALL_SLONG_TYPE = __SLONGWORD_TYPE;
pub const __SYSCALL_ULONG_TYPE = __ULONGWORD_TYPE;
pub const __DEV_T_TYPE = __UQUAD_TYPE;
pub const __UID_T_TYPE = __U32_TYPE;
pub const __GID_T_TYPE = __U32_TYPE;
pub const __INO_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __INO64_T_TYPE = __UQUAD_TYPE;
pub const __MODE_T_TYPE = __U32_TYPE;
pub const __NLINK_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSWORD_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __OFF_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __OFF64_T_TYPE = __SQUAD_TYPE;
pub const __PID_T_TYPE = __S32_TYPE;
pub const __RLIM_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __RLIM64_T_TYPE = __UQUAD_TYPE;
pub const __BLKCNT_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __BLKCNT64_T_TYPE = __SQUAD_TYPE;
pub const __FSBLKCNT_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSBLKCNT64_T_TYPE = __UQUAD_TYPE;
pub const __FSFILCNT_T_TYPE = __SYSCALL_ULONG_TYPE;
pub const __FSFILCNT64_T_TYPE = __UQUAD_TYPE;
pub const __ID_T_TYPE = __U32_TYPE;
pub const __CLOCK_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __TIME_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __USECONDS_T_TYPE = __U32_TYPE;
pub const __SUSECONDS_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __SUSECONDS64_T_TYPE = __SQUAD_TYPE;
pub const __DADDR_T_TYPE = __S32_TYPE;
pub const __KEY_T_TYPE = __S32_TYPE;
pub const __CLOCKID_T_TYPE = __S32_TYPE;
pub const __TIMER_T_TYPE = ?*anyopaque;
pub const __BLKSIZE_T_TYPE = __SYSCALL_SLONG_TYPE;
pub const __FSID_T_TYPE = @compileError("unable to translate macro: undefined identifier `__val`");
// /usr/include/x86_64-linux-gnu/bits/typesizes.h:73:9
pub const __SSIZE_T_TYPE = __SWORD_TYPE;
pub const __CPU_MASK_TYPE = __SYSCALL_ULONG_TYPE;
pub const __OFF_T_MATCHES_OFF64_T = @as(c_int, 1);
pub const __INO_T_MATCHES_INO64_T = @as(c_int, 1);
pub const __RLIM_T_MATCHES_RLIM64_T = @as(c_int, 1);
pub const __STATFS_MATCHES_STATFS64 = @as(c_int, 1);
pub const __KERNEL_OLD_TIMEVAL_MATCHES_TIMEVAL64 = @as(c_int, 1);
pub const __FD_SETSIZE = @as(c_int, 1024);
pub const _BITS_TIME64_H = @as(c_int, 1);
pub const __TIME64_T_TYPE = __TIME_T_TYPE;
pub const _BITS_WCHAR_H = @as(c_int, 1);
pub const __WCHAR_MAX = __WCHAR_MAX__;
pub const __WCHAR_MIN = -__WCHAR_MAX - @as(c_int, 1);
pub const _BITS_STDINT_INTN_H = @as(c_int, 1);
pub const _BITS_STDINT_UINTN_H = @as(c_int, 1);
pub const _BITS_STDINT_LEAST_H = @as(c_int, 1);
pub const __intptr_t_defined = "";
pub const __INT64_C = __helpers.L_SUFFIX;
pub const __UINT64_C = __helpers.UL_SUFFIX;
pub const INT8_MIN = -@as(c_int, 128);
pub const INT16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT32_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT64_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT8_MAX = @as(c_int, 127);
pub const INT16_MAX = @as(c_int, 32767);
pub const INT32_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT64_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT8_MAX = @as(c_int, 255);
pub const UINT16_MAX = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT32_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT64_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_LEAST8_MIN = -@as(c_int, 128);
pub const INT_LEAST16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT_LEAST32_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT_LEAST64_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_LEAST8_MAX = @as(c_int, 127);
pub const INT_LEAST16_MAX = @as(c_int, 32767);
pub const INT_LEAST32_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT_LEAST64_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_LEAST8_MAX = @as(c_int, 255);
pub const UINT_LEAST16_MAX = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST32_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST64_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_FAST8_MIN = -@as(c_int, 128);
pub const INT_FAST16_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST32_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST64_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_FAST8_MAX = @as(c_int, 127);
pub const INT_FAST16_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST32_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST64_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_FAST8_MAX = @as(c_int, 255);
pub const UINT_FAST16_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST32_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST64_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INTPTR_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INTPTR_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const UINTPTR_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const INTMAX_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INTMAX_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINTMAX_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const PTRDIFF_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const PTRDIFF_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const SIG_ATOMIC_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const SIG_ATOMIC_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const SIZE_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const WCHAR_MIN = __WCHAR_MIN;
pub const WCHAR_MAX = __WCHAR_MAX;
pub const WINT_MIN = @as(c_uint, 0);
pub const WINT_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub inline fn INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const INT64_C = __helpers.L_SUFFIX;
pub inline fn UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const UINT32_C = __helpers.U_SUFFIX;
pub const UINT64_C = __helpers.UL_SUFFIX;
pub const INTMAX_C = __helpers.L_SUFFIX;
pub const UINTMAX_C = __helpers.UL_SUFFIX;
pub const @"bool" = bool;
pub const @"true" = @as(c_int, 1);
pub const @"false" = @as(c_int, 0);
pub const __bool_true_false_are_defined = @as(c_int, 1);
pub const _STRING_H = @as(c_int, 1);
pub const __GLIBC_USE_LIB_EXT2 = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_BFP_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_BFP_EXT_C23 = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT_C23 = @as(c_int, 0);
pub const __GLIBC_USE_IEC_60559_TYPES_EXT = @as(c_int, 0);
pub const __need_size_t = "";
pub const __need_NULL = "";
pub const _BITS_TYPES_LOCALE_T_H = @as(c_int, 1);
pub const _BITS_TYPES___LOCALE_T_H = @as(c_int, 1);
pub const _STRINGS_H = @as(c_int, 1);
pub const _ASSERT_H = @as(c_int, 1);
pub const __ASSERT_VOID_CAST = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/assert.h:46:10
pub const __ASSERT_VARIADIC = @as(c_int, 0);
pub const _ASSERT_H_DECLS = "";
pub const assert = @compileError("unable to translate macro: undefined identifier `__FILE__`");
// /usr/include/assert.h:169:12
pub const __ASSERT_FUNCTION = @compileError("unable to translate C expr: unexpected token '__extension__'");
// /usr/include/assert.h:192:12
pub const static_assert = @compileError("unable to translate C expr: unexpected token '_Static_assert'");
// /usr/include/assert.h:210:10
pub const WASM_API_EXTERN = "";
pub const WASM_DECLARE_OWN = @compileError("unable to translate macro: undefined identifier `wasm_`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:74:9
pub const WASM_DECLARE_VEC = @compileError("unable to translate macro: undefined identifier `wasm_`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:82:9
pub const wasm_name = @compileError("unable to translate macro: undefined identifier `wasm_byte_vec`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:106:9
pub const wasm_name_new = wasm_byte_vec_new;
pub const wasm_name_new_empty = wasm_byte_vec_new_empty;
pub const wasm_name_new_uninitialized = wasm_byte_vec_new_uninitialized;
pub const wasm_name_copy = wasm_byte_vec_copy;
pub const wasm_name_delete = wasm_byte_vec_delete;
pub const WASM_DECLARE_TYPE = @compileError("unable to translate macro: undefined identifier `own`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:174:9
pub const WASM_DECLARE_REF_BASE = @compileError("unable to translate macro: undefined identifier `own`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:354:9
pub const WASM_DECLARE_REF = @compileError("unable to translate macro: undefined identifier `wasm_`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:365:9
pub const WASM_DECLARE_SHARABLE_REF = @compileError("unable to translate macro: undefined identifier `shared_`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:373:9
pub const WASM_EMPTY_VEC = @compileError("unable to translate C expr: unexpected token '{'");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:551:9
pub const WASM_ARRAY_VEC = @compileError("unable to translate C expr: unexpected token '{'");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:552:9
pub const WASM_I32_VAL = @compileError("unable to translate C expr: unexpected token '{'");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:727:9
pub const WASM_I64_VAL = @compileError("unable to translate C expr: unexpected token '{'");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:728:9
pub const WASM_F32_VAL = @compileError("unable to translate C expr: unexpected token '{'");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:729:9
pub const WASM_F64_VAL = @compileError("unable to translate C expr: unexpected token '{'");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:730:9
pub const WASM_REF_VAL = @compileError("unable to translate C expr: unexpected token '{'");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:731:9
pub const WASM_INIT_VAL = @compileError("unable to translate C expr: unexpected token '{'");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasm.h:732:9
pub const WASI_H = "";
pub const WASMTIME_CONF_H = "";
pub const WASMTIME_FEATURE_PROFILING = "";
pub const WASMTIME_FEATURE_WAT = "";
pub const WASMTIME_FEATURE_CACHE = "";
pub const WASMTIME_FEATURE_PARALLEL_COMPILATION = "";
pub const WASMTIME_FEATURE_WASI = "";
pub const WASMTIME_FEATURE_WASI_HTTP = "";
pub const WASMTIME_FEATURE_LOGGING = "";
pub const WASMTIME_FEATURE_COREDUMP = "";
pub const WASMTIME_FEATURE_ADDR2LINE = "";
pub const WASMTIME_FEATURE_DEMANGLE = "";
pub const WASMTIME_FEATURE_THREADS = "";
pub const WASMTIME_FEATURE_GC = "";
pub const WASMTIME_FEATURE_GC_DRC = "";
pub const WASMTIME_FEATURE_GC_NULL = "";
pub const WASMTIME_FEATURE_ASYNC = "";
pub const WASMTIME_FEATURE_CRANELIFT = "";
pub const WASMTIME_FEATURE_WINCH = "";
pub const WASMTIME_FEATURE_DEBUG_BUILTINS = "";
pub const WASMTIME_FEATURE_POOLING_ALLOCATOR = "";
pub const WASMTIME_FEATURE_COMPONENT_MODEL = "";
pub const WASMTIME_FEATURE_COMPONENT_MODEL_ASYNC = "";
pub const WASMTIME_FEATURE_PULLEY = "";
pub const WASMTIME_FEATURE_COMPILER = "";
pub const WASI_API_EXTERN = "";
pub const WASI_DECLARE_OWN = @compileError("unable to translate macro: undefined identifier `wasi_`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasi.h:30:9
pub const WASMTIME_API_H = "";
pub const WASMTIME_ANYREF_H = "";
pub const WASMTIME_TYPES_VAL_H = "";
pub const WASMTIME_TYPES_ARRAYREF_H = "";
pub const WASMTIME_TYPES_STRUCTREF_H = "";
pub const WASMTIME_STORAGE_TYPE_KIND_I8 = @as(c_int, 0);
pub const WASMTIME_STORAGE_TYPE_KIND_I16 = @as(c_int, 1);
pub const WASMTIME_STORAGE_TYPE_KIND_VALTYPE = @as(c_int, 2);
pub const WASMTIME_TYPES_EXNREF_H = "";
pub const WASMTIME_ERROR_H = "";
pub const WASMTIME_HEAPTYPE_KIND_EXTERN = @as(c_int, 0);
pub const WASMTIME_HEAPTYPE_KIND_NOEXTERN = @as(c_int, 1);
pub const WASMTIME_HEAPTYPE_KIND_FUNC = @as(c_int, 2);
pub const WASMTIME_HEAPTYPE_KIND_CONCRETE_FUNC = @as(c_int, 3);
pub const WASMTIME_HEAPTYPE_KIND_NOFUNC = @as(c_int, 4);
pub const WASMTIME_HEAPTYPE_KIND_ANY = @as(c_int, 5);
pub const WASMTIME_HEAPTYPE_KIND_NONE = @as(c_int, 6);
pub const WASMTIME_HEAPTYPE_KIND_EQ = @as(c_int, 7);
pub const WASMTIME_HEAPTYPE_KIND_I31 = @as(c_int, 8);
pub const WASMTIME_HEAPTYPE_KIND_ARRAY = @as(c_int, 9);
pub const WASMTIME_HEAPTYPE_KIND_CONCRETE_ARRAY = @as(c_int, 10);
pub const WASMTIME_HEAPTYPE_KIND_STRUCT = @as(c_int, 11);
pub const WASMTIME_HEAPTYPE_KIND_CONCRETE_STRUCT = @as(c_int, 12);
pub const WASMTIME_HEAPTYPE_KIND_EXN = @as(c_int, 13);
pub const WASMTIME_HEAPTYPE_KIND_CONCRETE_EXN = @as(c_int, 14);
pub const WASMTIME_HEAPTYPE_KIND_NOEXN = @as(c_int, 15);
pub const WASMTIME_VALTYPE_KIND_I32 = @as(c_int, 0);
pub const WASMTIME_VALTYPE_KIND_I64 = @as(c_int, 1);
pub const WASMTIME_VALTYPE_KIND_F32 = @as(c_int, 2);
pub const WASMTIME_VALTYPE_KIND_F64 = @as(c_int, 3);
pub const WASMTIME_VALTYPE_KIND_V128 = @as(c_int, 4);
pub const WASMTIME_VALTYPE_KIND_REF = @as(c_int, 5);
pub const WASMTIME_VAL_H = "";
pub const alignas = @compileError("unable to translate C expr: unexpected token '_Alignas'");
// zig-pkg/aro-0.0.0-JSD1QtuBNwCASyBtNF3pqTl_W3oAJQGEVyFAtrBSE_Pa/include/stdalign.h:6:9
pub const alignof = @compileError("unable to translate C expr: expected '(' instead got ''");
// zig-pkg/aro-0.0.0-JSD1QtuBNwCASyBtNF3pqTl_W3oAJQGEVyFAtrBSE_Pa/include/stdalign.h:7:9
pub const __alignas_is_defined = @as(c_int, 1);
pub const __alignof_is_defined = @as(c_int, 1);
pub const WASMTIME_EXTERN_H = "";
pub const WASMTIME_MODULE_H = "";
pub const WASMTIME_SHAREDMEMORY_H = "";
pub const WASMTIME_STORE_H = "";
pub const WASMTIME_UPDATE_DEADLINE_CONTINUE = @as(c_int, 0);
pub const WASMTIME_UPDATE_DEADLINE_YIELD = @as(c_int, 1);
pub const WASMTIME_TAG_H = "";
pub const WASMTIME_EXTERN_TAG = @as(c_int, 5);
pub const WASMTIME_EXTERN_FUNC = @as(c_int, 0);
pub const WASMTIME_EXTERN_GLOBAL = @as(c_int, 1);
pub const WASMTIME_EXTERN_TABLE = @as(c_int, 2);
pub const WASMTIME_EXTERN_MEMORY = @as(c_int, 3);
pub const WASMTIME_EXTERN_SHAREDMEMORY = @as(c_int, 4);
pub const WASMTIME_I32 = @as(c_int, 0);
pub const WASMTIME_I64 = @as(c_int, 1);
pub const WASMTIME_F32 = @as(c_int, 2);
pub const WASMTIME_F64 = @as(c_int, 3);
pub const WASMTIME_V128 = @as(c_int, 4);
pub const WASMTIME_FUNCREF = @as(c_int, 5);
pub const WASMTIME_EXTERNREF = @as(c_int, 6);
pub const WASMTIME_ANYREF = @as(c_int, 7);
pub const WASMTIME_EXNREF = @as(c_int, 8);
pub const WASMTIME_ARRAYREF_H = "";
pub const WASMTIME_ASYNC_H = "";
pub const WASMTIME_CONFIG_H = "";
pub const WASMTIME_CONFIG_PROP = @compileError("unable to translate macro: undefined identifier `wasmtime_config_`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasmtime/config.h:130:9
pub const WASMTIME_POOLING_ALLOCATION_CONFIG_PROP = @compileError("unable to translate macro: undefined identifier `wasmtime_pooling_allocation_config_`");
// zig-pkg/N-V-__8AAIYrdgZbtNWh99VCphRnmvPZ4iOlnho3UCE32C-d/include/wasmtime/config.h:692:9
pub const WASMTIME_FUNC_H = "";
pub const WASMTIME_LINKER_H = "";
pub const WASMTIME_INSTANCE_H = "";
pub const WASMTIME_COMPONENT_H = "";
pub const WASMTIME_COMPONENT_COMPONENT_H = "";
pub const WASMTIME_COMPONENT_TYPES_COMPONENT_H = "";
pub const WASMTIME_COMPONENT_TYPES_FUNC_H = "";
pub const WASMTIME_COMPONENT_TYPES_VAL_H = "";
pub const WASMTIME_COMPONENT_TYPES_RESOURCE_H = "";
pub const WASMTIME_COMPONENT_VALTYPE_BOOL = @as(c_int, 0);
pub const WASMTIME_COMPONENT_VALTYPE_S8 = @as(c_int, 1);
pub const WASMTIME_COMPONENT_VALTYPE_S16 = @as(c_int, 2);
pub const WASMTIME_COMPONENT_VALTYPE_S32 = @as(c_int, 3);
pub const WASMTIME_COMPONENT_VALTYPE_S64 = @as(c_int, 4);
pub const WASMTIME_COMPONENT_VALTYPE_U8 = @as(c_int, 5);
pub const WASMTIME_COMPONENT_VALTYPE_U16 = @as(c_int, 6);
pub const WASMTIME_COMPONENT_VALTYPE_U32 = @as(c_int, 7);
pub const WASMTIME_COMPONENT_VALTYPE_U64 = @as(c_int, 8);
pub const WASMTIME_COMPONENT_VALTYPE_F32 = @as(c_int, 9);
pub const WASMTIME_COMPONENT_VALTYPE_F64 = @as(c_int, 10);
pub const WASMTIME_COMPONENT_VALTYPE_CHAR = @as(c_int, 11);
pub const WASMTIME_COMPONENT_VALTYPE_STRING = @as(c_int, 12);
pub const WASMTIME_COMPONENT_VALTYPE_LIST = @as(c_int, 13);
pub const WASMTIME_COMPONENT_VALTYPE_RECORD = @as(c_int, 14);
pub const WASMTIME_COMPONENT_VALTYPE_TUPLE = @as(c_int, 15);
pub const WASMTIME_COMPONENT_VALTYPE_VARIANT = @as(c_int, 16);
pub const WASMTIME_COMPONENT_VALTYPE_ENUM = @as(c_int, 17);
pub const WASMTIME_COMPONENT_VALTYPE_OPTION = @as(c_int, 18);
pub const WASMTIME_COMPONENT_VALTYPE_RESULT = @as(c_int, 19);
pub const WASMTIME_COMPONENT_VALTYPE_FLAGS = @as(c_int, 20);
pub const WASMTIME_COMPONENT_VALTYPE_OWN = @as(c_int, 21);
pub const WASMTIME_COMPONENT_VALTYPE_BORROW = @as(c_int, 22);
pub const WASMTIME_COMPONENT_VALTYPE_FUTURE = @as(c_int, 23);
pub const WASMTIME_COMPONENT_VALTYPE_STREAM = @as(c_int, 24);
pub const WASMTIME_COMPONENT_VALTYPE_ERROR_CONTEXT = @as(c_int, 25);
pub const WASMTIME_COMPONENT_VALTYPE_MAP = @as(c_int, 26);
pub const WASMTIME_COMPONENT_TYPES_INSTANCE_H = "";
pub const WASMTIME_COMPONENT_TYPES_MODULE_H = "";
pub const WASMTIME_COMPONENT_ITEM_COMPONENT = @as(c_int, 0);
pub const WASMTIME_COMPONENT_ITEM_COMPONENT_INSTANCE = @as(c_int, 1);
pub const WASMTIME_COMPONENT_ITEM_MODULE = @as(c_int, 2);
pub const WASMTIME_COMPONENT_ITEM_COMPONENT_FUNC = @as(c_int, 3);
pub const WASMTIME_COMPONENT_ITEM_RESOURCE = @as(c_int, 4);
pub const WASMTIME_COMPONENT_ITEM_CORE_FUNC = @as(c_int, 5);
pub const WASMTIME_COMPONENT_ITEM_TYPE = @as(c_int, 6);
pub const WASMTIME_COMPONENT_FUNC_H = "";
pub const WASMTIME_COMPONENT_VAL_H = "";
pub const WASMTIME_COMPONENT_BOOL = @as(c_int, 0);
pub const WASMTIME_COMPONENT_S8 = @as(c_int, 1);
pub const WASMTIME_COMPONENT_U8 = @as(c_int, 2);
pub const WASMTIME_COMPONENT_S16 = @as(c_int, 3);
pub const WASMTIME_COMPONENT_U16 = @as(c_int, 4);
pub const WASMTIME_COMPONENT_S32 = @as(c_int, 5);
pub const WASMTIME_COMPONENT_U32 = @as(c_int, 6);
pub const WASMTIME_COMPONENT_S64 = @as(c_int, 7);
pub const WASMTIME_COMPONENT_U64 = @as(c_int, 8);
pub const WASMTIME_COMPONENT_F32 = @as(c_int, 9);
pub const WASMTIME_COMPONENT_F64 = @as(c_int, 10);
pub const WASMTIME_COMPONENT_CHAR = @as(c_int, 11);
pub const WASMTIME_COMPONENT_STRING = @as(c_int, 12);
pub const WASMTIME_COMPONENT_LIST = @as(c_int, 13);
pub const WASMTIME_COMPONENT_RECORD = @as(c_int, 14);
pub const WASMTIME_COMPONENT_TUPLE = @as(c_int, 15);
pub const WASMTIME_COMPONENT_VARIANT = @as(c_int, 16);
pub const WASMTIME_COMPONENT_ENUM = @as(c_int, 17);
pub const WASMTIME_COMPONENT_OPTION = @as(c_int, 18);
pub const WASMTIME_COMPONENT_RESULT = @as(c_int, 19);
pub const WASMTIME_COMPONENT_FLAGS = @as(c_int, 20);
pub const WASMTIME_COMPONENT_RESOURCE = @as(c_int, 21);
pub const WASMTIME_COMPONENT_MAP = @as(c_int, 22);
pub const WASMTIME_COMPONENT_INSTANCE_H = "";
pub const WASMTIME_COMPONENT_LINKER_H = "";
pub const WASMTIME_COMPONENT_TYPES_H = "";
pub const WASMTIME_ENGINE_H = "";
pub const WASMTIME_EQREF_H = "";
pub const WASMTIME_EXNREF_H = "";
pub const WASMTIME_EXTERNREF_H = "";
pub const WASMTIME_GLOBAL_H = "";
pub const WASMTIME_MEMORY_H = "";
pub const WASMTIME_PROFILING_H = "";
pub const WASMTIME_STRUCTREF_H = "";
pub const WASMTIME_TABLE_H = "";
pub const WASMTIME_TRAP_H = "";
pub const WASMTIME_TYPES_H = "";
pub const WASMTIME_WAT_H = "";
pub const WASMTIME_VERSION = "50.0.0-rc.1";
pub const WASMTIME_VERSION_MAJOR = @as(c_int, 50);
pub const WASMTIME_VERSION_MINOR = @as(c_int, 0);
pub const WASMTIME_VERSION_PATCH = @as(c_int, 0);
pub const __locale_struct = struct___locale_struct;
pub const wasm_mutability_enum = enum_wasm_mutability_enum;
pub const wasm_valkind_enum = enum_wasm_valkind_enum;
pub const wasm_externkind_enum = enum_wasm_externkind_enum;
pub const wasmtime_storage_type = struct_wasmtime_storage_type;
pub const wasmtime_field_type = struct_wasmtime_field_type;
pub const wasmtime_struct_type = struct_wasmtime_struct_type;
pub const wasmtime_array_type = struct_wasmtime_array_type;
pub const wasmtime_error = struct_wasmtime_error;
pub const wasmtime_exn_type = struct_wasmtime_exn_type;
pub const wasmtime_heaptype_union = union_wasmtime_heaptype_union;
pub const wasmtime_heaptype = struct_wasmtime_heaptype;
pub const wasmtime_reftype = struct_wasmtime_reftype;
pub const wasmtime_valtype = struct_wasmtime_valtype;
pub const wasmtime_module = struct_wasmtime_module;
pub const wasmtime_sharedmemory = struct_wasmtime_sharedmemory;
pub const wasmtime_store = struct_wasmtime_store;
pub const wasmtime_context = struct_wasmtime_context;
pub const wasmtime_tag = struct_wasmtime_tag;
pub const wasmtime_func = struct_wasmtime_func;
pub const wasmtime_table = struct_wasmtime_table;
pub const wasmtime_memory = struct_wasmtime_memory;
pub const wasmtime_global = struct_wasmtime_global;
pub const wasmtime_extern_union = union_wasmtime_extern_union;
pub const wasmtime_extern = struct_wasmtime_extern;
pub const wasmtime_anyref = struct_wasmtime_anyref;
pub const wasmtime_exnref = struct_wasmtime_exnref;
pub const wasmtime_externref = struct_wasmtime_externref;
pub const wasmtime_eqref = struct_wasmtime_eqref;
pub const wasmtime_structref = struct_wasmtime_structref;
pub const wasmtime_arrayref = struct_wasmtime_arrayref;
pub const wasmtime_valunion = union_wasmtime_valunion;
pub const wasmtime_val_raw = union_wasmtime_val_raw;
pub const wasmtime_val = struct_wasmtime_val;
pub const wasmtime_array_ref_pre = struct_wasmtime_array_ref_pre;
pub const wasmtime_strategy_enum = enum_wasmtime_strategy_enum;
pub const wasmtime_opt_level_enum = enum_wasmtime_opt_level_enum;
pub const wasmtime_profiling_strategy_enum = enum_wasmtime_profiling_strategy_enum;
pub const wasmtime_regalloc_algorithm_enum = enum_wasmtime_regalloc_algorithm_enum;
pub const wasmtime_linear_memory = struct_wasmtime_linear_memory;
pub const wasmtime_memory_creator = struct_wasmtime_memory_creator;
pub const wasmtime_caller = struct_wasmtime_caller;
pub const wasmtime_instance = struct_wasmtime_instance;
pub const wasmtime_instance_pre = struct_wasmtime_instance_pre;
pub const wasmtime_linker = struct_wasmtime_linker;
pub const wasmtime_call_future = struct_wasmtime_call_future;
pub const wasmtime_component_resource_type = struct_wasmtime_component_resource_type;
pub const wasmtime_component_list_type = struct_wasmtime_component_list_type;
pub const wasmtime_component_record_type = struct_wasmtime_component_record_type;
pub const wasmtime_component_tuple_type = struct_wasmtime_component_tuple_type;
pub const wasmtime_component_variant_type = struct_wasmtime_component_variant_type;
pub const wasmtime_component_enum_type = struct_wasmtime_component_enum_type;
pub const wasmtime_component_option_type = struct_wasmtime_component_option_type;
pub const wasmtime_component_result_type = struct_wasmtime_component_result_type;
pub const wasmtime_component_flags_type = struct_wasmtime_component_flags_type;
pub const wasmtime_component_future_type = struct_wasmtime_component_future_type;
pub const wasmtime_component_stream_type = struct_wasmtime_component_stream_type;
pub const wasmtime_component_map_type = struct_wasmtime_component_map_type;
pub const wasmtime_component_valtype_union = union_wasmtime_component_valtype_union;
pub const wasmtime_component_instance_type = struct_wasmtime_component_instance_type;
pub const wasmtime_module_type = struct_wasmtime_module_type;
pub const wasmtime_component_item_union = union_wasmtime_component_item_union;
pub const wasmtime_component_resource_any = struct_wasmtime_component_resource_any;
pub const wasmtime_component_resource_host = struct_wasmtime_component_resource_host;
pub const wasmtime_component_val = struct_wasmtime_component_val;
pub const wasmtime_component_valrecord_entry = struct_wasmtime_component_valrecord_entry;
pub const wasmtime_component_valmap_entry = struct_wasmtime_component_valmap_entry;
pub const wasmtime_component_vallist = struct_wasmtime_component_vallist;
pub const wasmtime_component_valrecord = struct_wasmtime_component_valrecord;
pub const wasmtime_component_valtuple = struct_wasmtime_component_valtuple;
pub const wasmtime_component_valflags = struct_wasmtime_component_valflags;
pub const wasmtime_component_valmap = struct_wasmtime_component_valmap;
pub const wasmtime_component_func = struct_wasmtime_component_func;
pub const wasmtime_component_instance = struct_wasmtime_component_instance;
pub const wasmtime_guestprofiler = struct_wasmtime_guestprofiler;
pub const wasmtime_guestprofiler_modules = struct_wasmtime_guestprofiler_modules;
pub const wasmtime_struct_ref_pre = struct_wasmtime_struct_ref_pre;
pub const wasmtime_trap_code_enum = enum_wasmtime_trap_code_enum;
