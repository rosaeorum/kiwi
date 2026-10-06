const Instance = @This();

base_wrapper: vk.BaseWrapper,
wrapper: vk.InstanceWrapper,
proxy: vk.InstanceProxy,
debug_messenger: vk.DebugUtilsMessengerEXT = .null_handle,

const std = @import("std");
pub const GetInstanceProcAddr: vk.PfnGetInstanceProcAddr = if (base.build_info.target.os.tag == .windows) windows_proc_wrapper: {
    const vk_proc = struct {
        pub var dll: ?std.os.windows.HMODULE = null;
        pub var loader: vk.PfnGetInstanceProcAddr = undefined;
    };

    break :windows_proc_wrapper &struct {
        pub fn getProcAddress(instance: ?vk.Instance, name: [*:0]const u8) callconv(vk.vulkan_call_conv) vk.PfnVoidFunction {
            const loader = if (vk_proc.dll != null) vk_proc.loader else init_dll: {
                @branchHint(.unlikely);

                vk_proc.dll = base.kernel32.LoadLibraryW(base.unicode.utf8ToUtf16LeStringLiteral("vulkan-1.dll")) orelse @panic("failed to load vulkan-1.dll");

                vk_proc.loader = @ptrCast(base.kernel32.GetProcAddress(vk_proc.dll.?, "vkGetInstanceProcAddr") orelse @panic("failed to load vulkan-1.dll symbol"));

                break :init_dll vk_proc.loader;
            };

            return loader(instance, name);
        }
    }.getProcAddress;
} else posix_proc_wrapper: {
    const so_names = [_][:0]const u8{
        "libvulkan.so.1",
        "libvulkan.so",
    };

    const vk_proc = struct {
        pub var so: ?std.DynLib = null;
        pub var loader: vk.PfnGetInstanceProcAddr = undefined;
    };

    break :posix_proc_wrapper &struct {
        pub fn getProcAddress(instance: ?vk.Instance, name: [*:0]const u8) callconv(vk.vulkan_call_conv) vk.PfnVoidFunction {
            const loader = if (vk_proc.so != null) vk_proc.loader else init_so: {
                @branchHint(.unlikely);

                vk_proc.so = for (so_names) |so_name| {
                    const lib = std.DynLib.openZ(so_name) catch continue;
                    break lib;
                } else @panic("failed to load libvulkan");

                vk_proc.loader = vk_proc.so.?.lookup(vk.PfnGetInstanceProcAddr, "vkGetInstanceProcAddr") orelse @panic("failed to load libvulkan symbol");

                break :init_so vk_proc.loader;
            };

            return loader(instance, name);
        }
    }.getProcAddress;
};

pub fn init(
    enable_validation: bool,
    application_name: [*:0]const u8,
    application_version: base.SemanticVersion,
    extensions: []const Gpu.Extension,
) !*Instance {
    const self = try base.gpa.create(Instance);
    errdefer base.gpa.destroy(self);

    self.* = Instance{
        .base_wrapper = vk.BaseWrapper.load(GetInstanceProcAddr),
        .wrapper = undefined,
        .proxy = undefined,
    };

    var extension_set: base.ArraySet([*:0]const u8) = .empty;
    defer extension_set.deinit(base.temp);

    try extension_set.ensureTotalCapacity(base.temp, 1024);
    for (extensions) |ext| {
        try extension_set.put(base.temp, Gpu.vk_extension_names[@backingInt(ext)], {});
    }

    if (enable_validation) {
        extension_set.putAssumeCapacity(Gpu.vk_extension_names[@backingInt(Gpu.Extension.ext_debug_utils)], {});
    }

    const extension_names = extension_set.keys();

    for (extension_names, 0..) |ext, i| log.debug("ext {d}: {s}", .{ i, ext });

    const app_info: vk.ApplicationInfo = .{
        .p_application_name = application_name,
        .application_version = Gpu.vkSemanticVersion(application_version).toU32(),
        .p_engine_name = "kiwi_vk",
        .engine_version = Gpu.vkSemanticVersion(@import("static_config").engine_version).toU32(),
        .api_version = vk.API_VERSION_1_3.toU32(),
    };

    const inst = self.base_wrapper.createInstance(&.{
        .p_application_info = &app_info,

        .enabled_extension_count = @intCast(extension_names.len),
        .pp_enabled_extension_names = extension_names.ptr,

        .enabled_layer_count = @intFromBool(enable_validation),
        .pp_enabled_layer_names = &[_][*:0]const u8{"VK_LAYER_KHRONOS_validation"},
    }, null) catch |err| retry: switch (err) {
        error.LayerNotPresent => {
            log.warn("Debug layer not available, trying to create Instance without...", .{});
            break :retry try self.base_wrapper.createInstance(&.{
                .p_application_info = &app_info,

                .enabled_extension_count = @intCast(extension_names.len),
                .pp_enabled_extension_names = extension_names.ptr,

                .enabled_layer_count = 0,
                .pp_enabled_layer_names = null,
            }, null);
        },
        else => return err,
    };

    self.wrapper = vk.InstanceWrapper.load(inst, self.base_wrapper.dispatch.vkGetInstanceProcAddr.?);

    self.proxy = vk.InstanceProxy.init(inst, &self.wrapper);
    errdefer self.proxy.destroyInstance(null);

    if (enable_validation) {
        self.debug_messenger = self.proxy.createDebugUtilsMessengerEXT(&.{
            .message_severity = .{
                .error_ext = true,
                .warning_ext = true,
            },
            .message_type = .{
                .general_ext = true,
                .validation_ext = true,
                .performance_ext = true,
            },
            .pfn_user_callback = &struct {
                pub fn vulkan_debug_callback(
                    message_severity: vk.DebugUtilsMessageSeverityFlagsEXT,
                    message_types: vk.DebugUtilsMessageTypeFlagsEXT,
                    p_callback_data: ?*const vk.DebugUtilsMessengerCallbackDataEXT,
                    p_user_data: ?*anyopaque,
                ) callconv(vk.vulkan_call_conv) vk.Bool32 {
                    _ = message_types;
                    _ = p_user_data;
                    b: {
                        const msg = (p_callback_data orelse break :b).p_message orelse break :b;
                        if (message_severity.error_ext)
                            log.err("{s}", .{msg})
                        else if (message_severity.warning_ext)
                            log.warn("{s}", .{msg})
                        else if (message_severity.info_ext)
                            log.info("{s}", .{msg})
                        else
                            log.debug("{s}", .{msg});
                        return .false;
                    }
                    log.err("unrecognized validation layer debug message", .{});
                    return .false;
                }
            }.vulkan_debug_callback,
        }, null) catch |err| no_messenger: {
            log.warn("Failed to set debug messenger for this session: {s}", .{@errorName(err)});
            break :no_messenger .null_handle;
        };
    }

    return self;
}

pub fn deinit(self: *Instance) void {
    if (self.debug_messenger != .null_handle) {
        self.proxy.destroyDebugUtilsMessengerEXT(
            self.debug_messenger,
            null,
        );
    }

    self.proxy.destroyInstance(null);

    base.gpa.destroy(self);
}

pub const DeviceCandidate = struct {
    pdev: vk.PhysicalDevice,
    props: vk.PhysicalDeviceProperties,
    queues: QueueAllocation,
};

pub const QueueAllocation = struct {
    graphics_family: u32,
    present_family: ?u32,
};

const PDevType = enum(u8) {
    discrete_gpu,
    integrated_gpu,
    virtual_gpu,
    cpu,
    other,

    pub fn fromVk(ty: vk.PhysicalDeviceType) PDevType {
        return switch (ty) {
            .other => .other,
            .integrated_gpu => .integrated_gpu,
            .discrete_gpu => .discrete_gpu,
            .virtual_gpu => .virtual_gpu,
            .cpu => .cpu,
            else => {
                @branchHint(.cold);
                @panic("Out of spec device type enum");
            },
        };
    }

    pub fn lt(a: PDevType, b: PDevType) bool {
        return @backingInt(a) < @backingInt(b);
    }

    pub fn compareDevices(instance: *Instance, a: vk.PhysicalDevice, b: vk.PhysicalDevice) bool {
        return lt(
            fromVk(instance.proxy.getPhysicalDeviceProperties(a).device_type),
            fromVk(instance.proxy.getPhysicalDeviceProperties(b).device_type),
        );
    }
};

pub fn pickPhysicalDevice(
    self: *Instance,
    surface: ?Gpu.Surface,
    comptime required_device_features: []const meta.FieldEnum(vk.PhysicalDeviceFeatures),
    comptime required_device_features_12: []const meta.FieldEnum(vk.PhysicalDeviceVulkan12Features),
    comptime required_device_features_13: []const meta.FieldEnum(vk.PhysicalDeviceVulkan13Features),
    required_device_extensions: []const [*:0]const u8,
) !DeviceCandidate {
    const pdevs = try self.proxy.enumeratePhysicalDevicesAlloc(base.temp);

    base.mem.sort(vk.PhysicalDevice, pdevs, self, PDevType.compareDevices);

    for (pdevs) |pdevice| {
        if (try self.checkSuitable(
            pdevice,
            surface,
            required_device_features,
            required_device_features_12,
            required_device_features_13,
            required_device_extensions,
        )) |candidate| {
            return candidate;
        }
    }

    return error.NoSuitableDevice;
}

fn checkSuitable(
    self: *Instance,
    pdevice: vk.PhysicalDevice,
    surface: ?Gpu.Surface,
    comptime required_device_features: []const meta.FieldEnum(vk.PhysicalDeviceFeatures),
    comptime required_device_features_12: []const meta.FieldEnum(vk.PhysicalDeviceVulkan12Features),
    comptime required_device_features_13: []const meta.FieldEnum(vk.PhysicalDeviceVulkan13Features),
    required_device_extensions: []const [*:0]const u8,
) !?DeviceCandidate {
    const dev_props = self.proxy.getPhysicalDeviceProperties(pdevice);

    log.debug("Checking device {s} for suitability ...", .{
        mem.sliceTo(&dev_props.device_name, 0),
    });

    if (!try self.checkFeatureSupport(pdevice, required_device_features, required_device_features_12, required_device_features_13)) {
        log.debug("... Does not support required vulkan features; reject", .{});
        return null;
    } else {
        log.debug("... Supports vulkan features ...", .{});
    }

    if (!try self.checkExtensionSupport(pdevice, required_device_extensions)) {
        log.debug("... Does not support required vulkan extensions; reject", .{});
        return null;
    } else {
        log.debug("... Supports required vulkan extensions ...", .{});
    }

    if (surface) |srf| {
        if (!try self.checkSurfaceSupport(pdevice, srf)) {
            log.debug("... Does not support surface mode; reject", .{});
            return null;
        } else {
            log.debug("... Supports surface mode ...", .{});
        }
    }

    if (try self.allocateQueues(pdevice, surface)) |allocation| {
        log.debug("... Supports required command queues; accept", .{});
        return DeviceCandidate{
            .pdev = pdevice,
            .props = dev_props,
            .queues = allocation,
        };
    } else {
        log.debug("... Does not support required command queues; reject", .{});
        return null;
    }
}

fn allocateQueues(
    self: *Instance,
    pdevice: vk.PhysicalDevice,
    surface: ?Gpu.Surface,
) !?QueueAllocation {
    const families =
        try self.proxy.getPhysicalDeviceQueueFamilyPropertiesAlloc(pdevice, base.temp);

    var graphics_family: ?u32 = null;
    var present_family: ?u32 = null;

    for (families, 0..) |properties, i| {
        const family: u32 = @intCast(i);

        if (graphics_family == null and properties.queue_flags.graphics) {
            graphics_family = family;
        }

        if (surface) |srf| {
            if (present_family == null and
                (try self.proxy.getPhysicalDeviceSurfaceSupportKHR(
                    pdevice,
                    family,
                    srf,
                )) == .true)
            {
                present_family = family;
            }
        }

        if (graphics_family != null and (present_family != null or surface == null)) break;
    }

    if (graphics_family != null and (present_family != null or surface == null)) {
        return QueueAllocation{
            .graphics_family = graphics_family.?,
            .present_family = present_family,
        };
    }

    return null;
}

fn checkSurfaceSupport(self: *Instance, pdevice: vk.PhysicalDevice, surface: Gpu.Surface) !bool {
    var format_count: u32 = undefined;
    _ = try self.proxy.getPhysicalDeviceSurfaceFormatsKHR(
        pdevice,
        surface,
        &format_count,
        null,
    );

    var present_mode_count: u32 = undefined;
    _ = try self.proxy.getPhysicalDeviceSurfacePresentModesKHR(
        pdevice,
        surface,
        &present_mode_count,
        null,
    );

    log.debug("Candidate surface formats supported: {d}", .{format_count});
    log.debug("Candidate present modes supported: {d}", .{format_count});

    return format_count > 0 and present_mode_count > 0;
}

fn checkFeatureSupport(
    self: *Instance,
    pdevice: vk.PhysicalDevice,
    comptime required_device_features: []const meta.FieldEnum(vk.PhysicalDeviceFeatures),
    comptime required_device_features_12: []const meta.FieldEnum(vk.PhysicalDeviceVulkan12Features),
    comptime required_device_features_13: []const meta.FieldEnum(vk.PhysicalDeviceVulkan13Features),
) !bool {
    var vkfeatures_12: vk.PhysicalDeviceVulkan12Features = .{};
    var vkfeatures_13: vk.PhysicalDeviceVulkan13Features = .{
        .p_next = &vkfeatures_12,
    };
    var features2: vk.PhysicalDeviceFeatures2 = .{
        .features = .{},
        .p_next = &vkfeatures_13,
    };
    self.proxy.getPhysicalDeviceFeatures2(pdevice, &features2);

    log.debug("Candidate feature support:", .{});
    log.debug("  {any}", .{vkfeatures_12});
    log.debug("  {any}", .{features2.features});

    inline for (required_device_features) |feat| {
        if (@field(features2.features, @tagName(feat)) != .true) return false;
    }

    inline for (required_device_features_12) |feat| {
        if (@field(vkfeatures_12, @tagName(feat)) != .true) return false;
    }

    inline for (required_device_features_13) |feat| {
        if (@field(vkfeatures_13, @tagName(feat)) != .true) return false;
    }

    return true;
}

fn checkExtensionSupport(
    self: *Instance,
    pdevice: vk.PhysicalDevice,
    required_device_extensions: []const [*:0]const u8,
) !bool {
    const propsv = try self.proxy.enumerateDeviceExtensionPropertiesAlloc(
        pdevice,
        null,
        base.temp,
    );

    log.debug("Candidate extension support:", .{});
    for (propsv) |ext_props| {
        log.debug("  {s}: v{d}", .{
            mem.sliceTo(&ext_props.extension_name, 0),
            ext_props.spec_version,
        });
    }

    for (required_device_extensions) |ext| {
        for (propsv) |ext_props| {
            if (mem.eql(u8, mem.span(ext), mem.sliceTo(&ext_props.extension_name, 0))) {
                break;
            }
        } else {
            return false;
        }
    }

    return true;
}

const base = @import("../base.zig");
const vk = @import("../vulkan.zig");
const vma = @import("../vma.zig");
const Gpu = @import("../Gpu.zig");

const mem = base.mem;
const math = base.math;
const meta = base.meta;
const debug = base.debug;

const log = base.log.scoped(.Gpu);
