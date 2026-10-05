//! The base rendering and gpu compute layer for the kiwi engine.

const Gpu = @This();

device: *Device,

allocator: *vma.Allocator,

max_images: u32,
max_samplers: u32,

descriptor_set: vk.DescriptorSet,
descriptor_pool: vk.DescriptorPool,
descriptor_layout: vk.DescriptorSetLayout,

command_pool: vk.CommandPool,
command_buffers: frame.InFlightArray(CommandBuffer),

store: struct {
    buffer: *Buffer.Store,
    sampler: *Sampler.Store,
    image: *Image.Store,
},

pub fn init(device: *Device) !*Gpu {
    const self = try base.gpa.create(Gpu);
    errdefer base.gpa.destroy(self);

    self.device = device;

    self.max_samplers = @min(
        Sampler.Store.max_capacity,
        self.device.indexing_props.max_per_stage_descriptor_update_after_bind_samplers,
        self.device.indexing_props.max_descriptor_set_update_after_bind_samplers,
    );

    self.max_images = @min(
        Image.Store.max_capacity,
        self.device.indexing_props.max_per_stage_descriptor_update_after_bind_sampled_images,
        self.device.indexing_props.max_descriptor_set_update_after_bind_sampled_images,
    );

    const global_limit = self.device.indexing_props.max_update_after_bind_descriptors_in_all_pools;

    while (self.max_samplers + self.max_images > global_limit) {
        self.max_images = @divFloor(self.max_images, 2);
    }

    self.descriptor_pool = try self.device.proxy.createDescriptorPool(
        &vk.DescriptorPoolCreateInfo{
            .flags = .{ .update_after_bind_bit = true },
            .max_sets = 1,
            .pool_size_count = 2,
            .p_pool_sizes = &[_]vk.DescriptorPoolSize{
                .{
                    .type = .sampled_image,
                    .descriptor_count = self.max_images,
                },
                .{
                    .type = .sampler,
                    .descriptor_count = self.max_samplers,
                },
            },
        },
        null,
    );
    errdefer self.device.proxy.destroyDescriptorPool(self.descriptor_pool, null);

    self.descriptor_layout = try self.device.proxy.createDescriptorSetLayout(
        &vk.DescriptorSetLayoutCreateInfo{
            .flags = .{ .update_after_bind_pool_bit = true },
            .binding_count = 2,
            .p_bindings = &[_]vk.DescriptorSetLayoutBinding{
                .{
                    .binding = 0,
                    .descriptor_type = .sampled_image,
                    .descriptor_count = self.max_images,
                    .stage_flags = .{ .fragment_bit = true },
                    .p_immutable_samplers = null,
                },
                .{
                    .binding = 1,
                    .descriptor_type = .sampler,
                    .descriptor_count = self.max_samplers,
                    .stage_flags = .{ .fragment_bit = true },
                    .p_immutable_samplers = null,
                },
            },
            .p_next = &vk.DescriptorSetLayoutBindingFlagsCreateInfo{
                .binding_count = 2,
                .p_binding_flags = &[_]vk.DescriptorBindingFlags{
                    .{
                        .partially_bound_bit = true,
                        .update_after_bind_bit = true,
                    },
                    .{
                        .partially_bound_bit = true,
                        .update_after_bind_bit = true,
                    },
                },
            },
        },
        null,
    );
    errdefer self.device.proxy.destroyDescriptorSetLayout(
        self.descriptor_layout,
        null,
    );

    try self.device.proxy.allocateDescriptorSets(
        &.{
            .descriptor_pool = self.descriptor_pool,
            .descriptor_set_count = 1,
            .p_set_layouts = &.{self.descriptor_layout},
        },
        @ptrCast(&self.descriptor_set), // * -> [*]
    );

    self.command_pool = try self.device.proxy.createCommandPool(
        &.{
            .flags = .{ .reset_command_buffer_bit = true },
            .queue_family_index = self.device.graphics_queue.family,
        },
        null,
    );
    errdefer self.device.proxy.destroyCommandPool(self.command_pool, null);

    var vma_vulkan_functions = mem.zeroes(vma.VulkanFunctions);
    vma_vulkan_functions.vkGetInstanceProcAddr = device.instance.base_wrapper.dispatch.vkGetInstanceProcAddr.?;
    vma_vulkan_functions.vkGetDeviceProcAddr = device.instance.wrapper.dispatch.vkGetDeviceProcAddr.?;

    self.allocator = vma.createAllocator(.{
        .flags = .{ .buffer_device_address_bit = true }, // required for bda
        .physicalDevice = device.pdev,
        .device = device.proxy.handle,
        .instance = device.instance.proxy.handle,
        .vulkanApiVersion = vk.API_VERSION_1_3.toU32(),
        .pVulkanFunctions = &vma_vulkan_functions,
    }) catch {
        log.err("Failed to initialize VMA", .{});
        return error.VmaInitFailed;
    };
    errdefer vma.destroyAllocator(self.allocator);

    self.store.buffer = try Buffer.Store.init(self);
    errdefer self.store.buffer.deinit();

    self.store.sampler = try Sampler.Store.init(self);
    errdefer self.store.sampler.deinit();

    self.store.image = try Image.Store.init(self);
    errdefer self.store.image.deinit();

    for (&self.command_buffers) |*cmd| {
        cmd.* = try CommandBuffer.init(self);
    }
    errdefer for (&self.command_buffers) |*cmd| cmd.deinit();

    return self;
}

pub fn deinit(self: *Gpu) void {
    for (&self.command_buffers) |*cmd| cmd.deinit();

    self.store.image.deinit();
    self.store.sampler.deinit();
    self.store.buffer.deinit();

    vma.destroyAllocator(self.allocator);

    self.device.proxy.destroyCommandPool(self.command_pool, null);
    self.device.proxy.destroyDescriptorSetLayout(self.descriptor_layout, null);
    self.device.proxy.destroyDescriptorPool(self.descriptor_pool, null);

    base.gpa.destroy(self);
}

pub fn waitDeviceIdle(self: *Gpu) void {
    self.device.proxy.deviceWaitIdle() catch |err| {
        log.err("Failed to wait for device idle: {s}", .{@errorName(err)});
    };
}

pub fn getCommandBuffer(self: *Gpu, frame_id: frame.Id) *CommandBuffer {
    const cmd = &self.command_buffers[frame_id];
    cmd.reset() catch |err| {
        log.err("failed to reset command buffer: {s}", .{@errorName(err)});
    };
    return cmd;
}

pub const Queue = struct {
    handle: vk.Queue,
    family: u32,

    pub fn init(devprox: vk.DeviceProxy, family: u32) Queue {
        return .{
            .handle = devprox.getDeviceQueue(family, 0),
            .family = family,
        };
    }
};

pub const DeviceCandidate = struct {
    pdev: vk.PhysicalDevice,
    props: vk.PhysicalDeviceProperties,
    queues: QueueAllocation,
};

pub const QueueAllocation = struct {
    graphics_family: u32,
    present_family: ?u32,
};

pub const PDevType = enum(u8) {
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

pub const Extension = meta.DeclEnum(vk.extensions);

pub const vk_extension_names = get_extension_names: {
    const field_names = meta.fieldNames(Extension);
    var extension_names: [field_names.len][*:0]const u8 = undefined;
    for (field_names, 0..) |field_name, i| extension_names[i] = @field(vk.extensions, field_name).name;
    break :get_extension_names extension_names;
};

threadlocal var extension_map: base.StringArrayMap(Extension) = .empty;
pub fn getExtensionByName(name: []const u8) !Extension {
    @setEvalBranchQuota(100_000);
    const field_names = comptime meta.fieldNames(Extension);
    const keys, const vals = comptime gen_table: {
        var extension_names: [field_names.len][]const u8 = undefined;
        var extensions: [field_names.len]Extension = undefined;
        for (field_names, 0..) |field_name, field_index| {
            extension_names[field_index] = mem.span(vk_extension_names[field_index]);
            extensions[field_index] = @field(Extension, field_name);
        }
        break :gen_table .{ extension_names, extensions };
    };

    if (extension_map.count() == 0) {
        extension_map = base.StringArrayMap(Extension).init(base.gpa, keys[0..], vals[0..]) catch {
            log.err("OOM creating extension map", .{});
            return error.InvalidExtensionName;
        };
    }

    return extension_map.get(name) orelse error.InvalidExtensionName;
}

pub fn vkSemanticVersion(v: base.SemanticVersion) vk.Version {
    return vk.makeApiVersion(
        0,
        @intCast(v.major),
        @intCast(v.minor),
        @intCast(v.patch),
    );
}

pub const Instance = struct {
    base_wrapper: vk.BaseWrapper,
    wrapper: vk.InstanceWrapper,
    proxy: vk.InstanceProxy,
    debug_messenger: vk.DebugUtilsMessengerEXT = .null_handle,

    pub fn init(
        enable_validation: bool,
        application_name: [*:0]const u8,
        application_version: base.SemanticVersion,
        extensions: []const Extension,
    ) !*Instance {
        const self = try base.gpa.create(Instance);
        errdefer base.gpa.destroy(self);

        self.* = Instance{
            .base_wrapper = vk.BaseWrapper.load(vk.GetInstanceProcAddr),
            .wrapper = undefined,
            .proxy = undefined,
        };

        var extension_set: base.ArraySet([*:0]const u8) = .empty;
        defer extension_set.deinit(base.temp);

        try extension_set.ensureTotalCapacity(base.temp, 1024);
        for (extensions) |ext| {
            try extension_set.put(base.temp, vk_extension_names[@backingInt(ext)], {});
        }

        if (enable_validation) {
            extension_set.putAssumeCapacity(vk_extension_names[@backingInt(Extension.ext_debug_utils)], {});
        }

        const extension_names = extension_set.keys();

        for (extension_names, 0..) |ext, i| log.debug("ext {d}: {s}", .{ i, ext });

        const app_info: vk.ApplicationInfo = .{
            .p_application_name = application_name,
            .application_version = vkSemanticVersion(application_version).toU32(),
            .p_engine_name = "kiwi_vk",
            .engine_version = vkSemanticVersion(@import("static_config").engine_version).toU32(),
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
                    .error_bit_ext = true,
                    .warning_bit_ext = true,
                },
                .message_type = .{
                    .general_bit_ext = true,
                    .validation_bit_ext = true,
                    .performance_bit_ext = true,
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
                            if (message_severity.error_bit_ext)
                                log.err("{s}", .{msg})
                            else if (message_severity.warning_bit_ext)
                                log.warn("{s}", .{msg})
                            else if (message_severity.info_bit_ext)
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

    fn pickPhysicalDevice(
        self: *Instance,
        surface: ?Surface,
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
        surface: ?Surface,
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
        surface: ?Surface,
    ) !?QueueAllocation {
        const families =
            try self.proxy.getPhysicalDeviceQueueFamilyPropertiesAlloc(pdevice, base.temp);

        var graphics_family: ?u32 = null;
        var present_family: ?u32 = null;

        for (families, 0..) |properties, i| {
            const family: u32 = @intCast(i);

            if (graphics_family == null and properties.queue_flags.graphics_bit) {
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

    fn checkSurfaceSupport(self: *Instance, pdevice: vk.PhysicalDevice, surface: Surface) !bool {
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
};

pub const Device = struct {
    instance: *Instance,
    pdev: vk.PhysicalDevice,
    props: vk.PhysicalDeviceProperties,
    wrapper: vk.DeviceWrapper,
    proxy: vk.DeviceProxy,
    mem_props: vk.PhysicalDeviceMemoryProperties,
    vulkan11_props: vk.PhysicalDeviceVulkan11Properties,
    indexing_props: vk.PhysicalDeviceDescriptorIndexingProperties,
    graphics_queue: Queue,
    present: ?struct {
        surface: Surface,
        queue: Queue,
    },

    pub fn init(instance: *Instance, surface: ?Surface) !*Device {
        const self = try base.gpa.create(Device);
        errdefer base.gpa.destroy(self);

        self.instance = instance;
        self.present = if (surface) |surf| .{ .surface = surf, .queue = undefined } else null;

        const required_device_features =
            [_]meta.FieldEnum(vk.PhysicalDeviceFeatures){
                .sampler_anisotropy,

                // required for zig shaders
                .shader_int_64,
            };

        const required_device_features_12 =
            [_]meta.FieldEnum(vk.PhysicalDeviceVulkan12Features){
                // core of modern vk
                .buffer_device_address,

                // required for bindless combined image sampler array
                .descriptor_indexing,
                .runtime_descriptor_array,
                .descriptor_binding_partially_bound,
                .descriptor_binding_update_unused_while_pending,
                .descriptor_binding_sampled_image_update_after_bind,
                .shader_sampled_image_array_non_uniform_indexing,

                // better memory bandwidth utilization
                .scalar_block_layout,
            };

        const required_device_features_13 =
            [_]meta.FieldEnum(vk.PhysicalDeviceVulkan13Features){
                // required for no renderpass
                .dynamic_rendering,
            };

        const required_device_extensions =
            [_][*:0]const u8{
                vk.extensions.khr_storage_buffer_storage_class.name,
                vk.extensions.khr_variable_pointers.name,
                vk.extensions.khr_swapchain.name,
            };

        const candidate = try self.instance.pickPhysicalDevice(
            surface,
            &required_device_features,
            &required_device_features_12,
            &required_device_features_13,
            required_device_extensions[0..if (self.present == null)
                required_device_extensions.len - 1
            else
                required_device_extensions.len],
        );
        self.pdev = candidate.pdev;
        self.props = candidate.props;

        log.info("Using device: {s}", .{self.getName()});

        const priority = [_]f32{1};
        var qci: [2]vk.DeviceQueueCreateInfo = undefined;

        qci[0] = .{
            .queue_family_index = candidate.queues.graphics_family,
            .queue_count = 1,
            .p_queue_priorities = &priority,
        };

        if (candidate.queues.present_family) |fam| {
            qci[1] = .{
                .queue_family_index = fam,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            };
        }

        const queue_count: u32 =
            if (candidate.queues.present_family == null or candidate.queues.graphics_family == candidate.queues.present_family)
                1
            else
                2;

        var features_12 = vk.PhysicalDeviceVulkan12Features{};
        inline for (required_device_features_12) |feat| @field(features_12, @tagName(feat)) = .true;

        var features_13 = vk.PhysicalDeviceVulkan13Features{};
        inline for (required_device_features_13) |feat| @field(features_13, @tagName(feat)) = .true;
        features_13.p_next = &features_12;

        var features = vk.PhysicalDeviceFeatures{};
        inline for (required_device_features) |feat| @field(features, @tagName(feat)) = .true;

        const dev = try self.instance.proxy.createDevice(
            candidate.pdev,
            &.{
                .queue_create_info_count = queue_count,
                .p_next = &features_13,
                .p_queue_create_infos = &qci,
                .enabled_extension_count = if (self.present == null) required_device_extensions.len - 1 else required_device_extensions.len,
                .pp_enabled_extension_names = @ptrCast(&required_device_extensions),
                .p_enabled_features = &features,
            },
            null,
        );

        self.wrapper = vk.DeviceWrapper.load(dev, self.instance.wrapper.dispatch.vkGetDeviceProcAddr.?);
        self.proxy = vk.DeviceProxy.init(dev, &self.wrapper);
        errdefer self.proxy.destroyDevice(null);

        self.graphics_queue = Queue.init(self.proxy, candidate.queues.graphics_family);
        if (candidate.queues.present_family) |fam|
            self.present.?.queue = Queue.init(self.proxy, fam);

        self.mem_props = self.instance.proxy.getPhysicalDeviceMemoryProperties(self.pdev);

        self.vulkan11_props = mem.zeroes(vk.PhysicalDeviceVulkan11Properties);
        self.vulkan11_props.s_type = .physical_device_vulkan_1_1_properties;

        self.indexing_props = mem.zeroes(vk.PhysicalDeviceDescriptorIndexingProperties);
        self.indexing_props.s_type = .physical_device_descriptor_indexing_properties;
        self.indexing_props.p_next = &self.vulkan11_props;

        var p_props: vk.PhysicalDeviceProperties2 = .{
            .p_next = &self.indexing_props,
            .properties = mem.zeroes(vk.PhysicalDeviceProperties),
        };
        self.instance.proxy.getPhysicalDeviceProperties2(self.pdev, &p_props);

        return self;
    }

    pub fn deinit(self: *Device) void {
        self.proxy.destroyDevice(null);
        base.gpa.destroy(self);
    }

    pub fn getName(self: *Device) []const u8 {
        return mem.sliceTo(&self.props.device_name, 0);
    }

    fn memoryTypes(self: *Device) []const vk.MemoryType {
        return self.mem_props.memory_types[0..self.mem_props.memory_type_count];
    }
};

pub const Buffer = packed struct(u64) {
    storage_index: u32,
    generation: u32,

    pub fn init(gpu: *Gpu, size: u32) !Buffer {
        return initAdvanced(
            gpu,
            size,
            .{ .transfer_dst_bit = true, .shader_device_address_bit = true },
            .{ .device_local_bit = true },
        );
    }

    pub fn initAdvanced(gpu: *Gpu, size: u32, usage: vk.BufferUsageFlags, flags: vk.MemoryPropertyFlags) !Buffer {
        return gpu.store.buffer.create(size, usage, flags);
    }

    pub fn getDeviceAddress(self: Buffer, gpu: *Gpu) DeviceAddress {
        return gpu.store.buffer.getAddress(self);
    }

    pub fn getHandle(self: Buffer, gpu: *Gpu) vk.Buffer {
        return gpu.store.buffer.getHandle(self);
    }

    pub fn getAllocation(self: Buffer, gpu: *Gpu) *vma.Allocation {
        return gpu.store.buffer.getAllocation(self);
    }

    pub fn getAllocationInfo(self: Buffer, gpu: *Gpu) *const vma.AllocationInfo {
        return gpu.store.buffer.getAllocationInfo(self);
    }

    pub fn deinit(self: Buffer, gpu: *Gpu) void {
        gpu.store.buffer.destroy(self) catch |err| {
            log.err("memory leak: failed to properly free buffer {any} ({s})", .{ self, @errorName(err) });
        };
    }

    pub const Data = struct {
        generation: u32 = 0,
        state: ?State = null,
        barrier: ?vk.BufferMemoryBarrier = null,
        size: u32 = 0,
    };

    pub const State = struct {
        handle: vk.Buffer,
        allocation: *vma.Allocation,
        allocation_info: vma.AllocationInfo,
    };

    pub const Store = struct {
        gpu: *Gpu,
        storage: base.VMultiArray(Data) = .empty,
        freelist: base.VArray(u32) = .empty,

        const max_capacity = math.maxInt(u32);

        pub fn init(gpu: *Gpu) !*Store {
            const self = try base.gpa.create(Store);
            self.* = Store{ .gpu = gpu };
            return self;
        }

        pub fn deinit(self: *Store) void {
            for (0..self.storage.count) |storage_index| {
                if (self.storage.fieldMut(.state, storage_index).*) |*state| {
                    vma.destroyBuffer(self.gpu.allocator, state.handle, state.allocation);
                }
            }
            base.gpa.destroy(self);
        }

        pub fn create(self: *Store, size: u32, usage: vk.BufferUsageFlags, flags: vk.MemoryPropertyFlags) !Buffer {
            debug.assert(size > 0);

            const storage_index = storage_index: {
                if (self.freelist.isEmpty()) {
                    const index = self.storage.count;

                    if (self.storage.count >= max_capacity) return error.OutOfMemory;

                    try self.storage.push(Data{});

                    break :storage_index index;
                } else {
                    break :storage_index self.freelist.pop();
                }
            };
            errdefer self.freelist.push(@intCast(storage_index)) catch |err| {
                log.debug("memory leak: failed to restore buffer freelist index {any} after failed allocation ({s})", .{ storage_index, @errorName(err) });
            };

            const state: *?State = self.storage.fieldMut(.state, storage_index);
            debug.assert(state.* == null);

            var alloc_flags = vma.AllocationCreateFlags{};
            if (flags.host_visible_bit) {
                alloc_flags.mapped_bit = true;
                alloc_flags.host_access_sequential_write_bit = true;
            }

            const result = vma.createBuffer(self.gpu.allocator, .{
                .size = size,
                .usage = usage,
                .sharing_mode = .exclusive,
            }, .{
                .usage = .auto,
                .flags = alloc_flags,
                .requiredFlags = flags,
            }) catch {
                log.err("Failed to allocate buffer", .{});
                return error.OutOfMemory;
            };

            state.* = State{
                .handle = result.buffer,
                .allocation = result.allocation,
                .allocation_info = result.allocation_info,
            };

            return Buffer{
                .storage_index = @intCast(storage_index),
                .generation = self.storage.field(.generation, storage_index),
            };
        }

        pub fn getSize(self: *Store, buffer: Buffer) u32 {
            debug.assert(buffer.generation == self.storage.field(.generation, buffer.storage_index));
            return self.storage.field(.size, buffer.storage_index);
        }

        pub fn getHandle(self: *Store, buffer: Buffer) vk.Buffer {
            debug.assert(buffer.generation == self.storage.field(.generation, buffer.storage_index));
            return self.storage.fieldPtr(.state, buffer.storage_index).*.?.handle;
        }

        pub fn getAllocation(self: *Store, buffer: Buffer) *vma.Allocation {
            debug.assert(buffer.generation == self.storage.field(.generation, buffer.storage_index));
            return self.storage.fieldPtr(.state, buffer.storage_index).*.?.allocation;
        }

        pub fn getAllocationInfo(self: *Store, buffer: Buffer) *const vma.AllocationInfo {
            debug.assert(buffer.generation == self.storage.field(.generation, buffer.storage_index));
            return &self.storage.fieldPtr(.state, buffer.storage_index).*.?.allocation_info;
        }

        pub fn getAddress(self: *Store, buffer: Buffer) DeviceAddress {
            return self.gpu.device.proxy.getBufferDeviceAddress(&.{ .buffer = self.getHandle(buffer) });
        }

        pub fn destroy(self: *Store, buffer: Buffer) !void {
            if (buffer.generation != self.storage.field(.generation, buffer.storage_index)) {
                @branchHint(.cold);
                return error.UseAfterFree;
            }

            self.storage.fieldMut(.generation, buffer.storage_index).* += 1;
            const state: *?State = self.storage.fieldMut(.state, buffer.storage_index);
            const old_state = &state.*.?;
            vma.destroyBuffer(self.gpu.allocator, old_state.handle, old_state.allocation);
            state.* = null;

            try self.freelist.push(buffer.storage_index);
        }
    };
};

pub const Image = packed struct(u64) {
    storage_index: u32,
    generation: u32,

    pub fn init(gpu: *Gpu, width: u32, height: u32) !Image {
        return initAdvanced(
            gpu,
            width,
            height,
            .r8g8b8a8_unorm,
            .{
                .transfer_dst_bit = true,
                .sampled_bit = true,
                .color_attachment_bit = true,
            },
            .{ .device_local_bit = true },
        );
    }

    pub fn initAdvanced(
        gpu: *Gpu,
        width: u32,
        height: u32,
        format: vk.Format,
        usage: vk.ImageUsageFlags,
        flags: vk.MemoryPropertyFlags,
    ) !Image {
        return gpu.store.image.create(
            width,
            height,
            format,
            usage,
            flags,
        );
    }

    pub fn deinit(image: Image, gpu: *Gpu) void {
        gpu.store.image.destroy(image) catch |err| {
            log.err("memory leak: failed to properly free image {any} ({s})", .{ image, @errorName(err) });
        };
    }

    pub fn getIndex(self: Image) u32 {
        return self.storage_index;
    }

    pub fn getHandle(self: Image, gpu: *Gpu) vk.Image {
        return gpu.store.image.storage.fieldPtr(.state, self.storage_index).*.?.handle;
    }

    pub const Data = struct {
        generation: u32 = 0,
        state: ?State = null,
        width: u32 = 0,
        height: u32 = 0,
        format: vk.Format = .undefined,
    };

    pub const State = struct {
        handle: vk.Image,
        view: ImageView,
        layout: vk.ImageLayout,
        allocation: *vma.Allocation,
    };

    pub const Store = struct {
        gpu: *Gpu,
        storage: base.VMultiArray(Data) = .empty,
        freelist: base.VArray(u32) = .empty,

        const max_capacity = math.maxInt(u16);

        pub fn init(gpu: *Gpu) !*Store {
            const self = try base.gpa.create(Store);

            self.* = .{ .gpu = gpu };

            return self;
        }

        pub fn deinit(self: *Store) void {
            for (0..self.storage.count) |storage_index| {
                if (self.storage.fieldPtr(.state, storage_index).*) |*state| {
                    self.gpu.device.proxy.destroyImageView(state.view, null);
                    vma.destroyImage(self.gpu.allocator, state.handle, state.allocation);
                }
            }

            self.storage.deinit();
            self.freelist.deinit();

            base.gpa.destroy(self);
        }

        pub fn create(
            self: *Store,
            width: u32,
            height: u32,
            format: vk.Format,
            usage: vk.ImageUsageFlags,
            flags: vk.MemoryPropertyFlags,
        ) !Image {
            const storage_index = storage_index: {
                if (self.freelist.isEmpty()) {
                    const index = self.storage.count;
                    if (index >= self.gpu.max_images) return error.OutOfMemory;

                    try self.storage.push(Data{});

                    break :storage_index index;
                } else {
                    break :storage_index self.freelist.pop();
                }
            };

            const state: *?State = self.storage.fieldMut(.state, storage_index);

            debug.assert(state.* == null);

            self.storage.fieldMut(.width, storage_index).* = width;
            self.storage.fieldMut(.height, storage_index).* = height;
            self.storage.fieldMut(.format, storage_index).* = format;

            const result = vma.createImage(self.gpu.allocator, .{
                .image_type = .@"2d",
                .format = format,
                .extent = .{ .width = width, .height = height, .depth = 1 },
                .mip_levels = 1,
                .array_layers = 1,
                .samples = .{ .@"1_bit" = true },
                .tiling = .optimal,
                .usage = usage,
                .sharing_mode = .exclusive,
                .initial_layout = .undefined,
            }, .{
                .usage = .auto,
                .requiredFlags = flags,
            }) catch {
                log.err("Failed to allocate image", .{});
                return error.OutOfMemory;
            };

            const view = try self.gpu.device.proxy.createImageView(&.{
                .image = result.image,
                .view_type = .@"2d",
                .format = format,
                .components = .{
                    .r = .identity,
                    .g = .identity,
                    .b = .identity,
                    .a = .identity,
                },
                .subresource_range = .{
                    .aspect_mask = .{ .color_bit = true },
                    .base_mip_level = 0,
                    .level_count = 1,
                    .base_array_layer = 0,
                    .layer_count = 1,
                },
            }, null);
            errdefer self.gpu.device.proxy.destroyImageView(view, null);

            const image_info = vk.DescriptorImageInfo{
                .sampler = .null_handle,
                .image_view = view,
                .image_layout = .shader_read_only_optimal, // What it will be after sync
            };

            const write = vk.WriteDescriptorSet{
                .dst_set = self.gpu.descriptor_set,
                .dst_binding = 0,
                .dst_array_element = @intCast(storage_index),
                .descriptor_count = 1,
                .descriptor_type = .sampled_image,
                .p_image_info = @ptrCast(&image_info),
                .p_buffer_info = undefined,
                .p_texel_buffer_view = undefined,
            };
            self.gpu.device.proxy.updateDescriptorSets(&.{write}, null);

            state.* = .{
                .handle = result.image,
                .view = view,
                .allocation = result.allocation,
                .layout = .undefined,
            };

            return Image{
                .storage_index = @intCast(storage_index),
                .generation = self.storage.field(.generation, storage_index),
            };
        }

        pub fn destroy(self: *Store, image: Image) !void {
            if (image.storage_index >= self.storage.count) {
                @branchHint(.cold);
                return error.UseAfterFree;
            }

            if (image.generation != self.storage.field(.generation, image.storage_index)) {
                @branchHint(.cold);
                return error.UseAfterFree;
            }

            self.storage.fieldMut(.generation, image.storage_index).* += 1;
            const state: *?State = self.storage.fieldMut(.state, image.storage_index);
            const old_state = &state.*.?;

            self.gpu.device.proxy.destroyImageView(old_state.view, null);
            vma.destroyImage(self.gpu.allocator, old_state.handle, old_state.allocation);

            state.* = null;

            try self.freelist.push(image.storage_index);
        }
    };
};

pub const Sampler = packed struct(u32) {
    storage_index: Index,

    pub fn nearest(gpu: *Gpu) !Sampler {
        return custom(gpu, &.{
            .mag_filter = .nearest,
            .min_filter = .nearest,
            .mipmap_mode = .nearest,
        });
    }

    pub fn linear(gpu: *Gpu) !Sampler {
        return custom(gpu, &.{
            .mag_filter = .linear,
            .min_filter = .linear,
            .mipmap_mode = .linear,
            .max_anisotropy = 0.0, // TODO: mipmaps
        });
    }

    pub fn custom(gpu: *Gpu, config: *const Sampler.Config) !Sampler {
        return gpu.store.sampler.fetch(config);
    }

    pub fn getIndex(self: Sampler) u32 {
        return self.storage_index;
    }

    pub const Index = u32;

    pub const Config = struct {
        unnormalized_coordinates: bool = false,
        mag_filter: Filter,
        min_filter: Filter,
        mipmap_mode: MipmapMode,
        address_mode_u: AddressMode = .repeat,
        address_mode_v: AddressMode = .repeat,
        address_mode_w: AddressMode = .repeat,
        compare_op: CompareOp = .none,
        border_color: BorderColor = .int_opaque_white,
        min_lod: f32 = 0.0,
        max_lod: f32 = 0.0,
        mip_lod_bias: f32 = 0.0,
        max_anisotropy: f32 = 0.0,

        fn toData(self: Config) Data {
            return Data{
                .bits = .{
                    .unnormalized_coordinates = self.unnormalized_coordinates,
                    .mag_filter = self.mag_filter,
                    .min_filter = self.min_filter,
                    .mipmap_mode = self.mipmap_mode,
                    .address_mode_u = self.address_mode_u,
                    .address_mode_v = self.address_mode_v,
                    .address_mode_w = self.address_mode_w,
                    .compare_op = self.compare_op,
                    .border_color = self.border_color,
                },
                .min_lod = .fromF32(self.min_lod),
                .max_lod = .fromF32(self.max_lod),
                .mip_lod_bias = .fromF32(self.mip_lod_bias),
                .max_anisotropy = .fromF32(self.max_anisotropy),
            };
        }
    };

    pub const Data = extern struct {
        bits: Packed = .{},
        min_lod: CanonFloat = .zero,
        max_lod: CanonFloat = .zero,
        mip_lod_bias: CanonFloat = .zero,
        max_anisotropy: CanonFloat = .zero,

        pub const Packed = packed struct(u32) {
            unnormalized_coordinates: bool = false, // 1
            mag_filter: Filter = .nearest, // 2
            min_filter: Filter = .nearest, // 2
            mipmap_mode: MipmapMode = .nearest, // 1
            address_mode_u: AddressMode = .clamp_to_edge, // 3
            address_mode_v: AddressMode = .clamp_to_edge, // 3
            address_mode_w: AddressMode = .clamp_to_edge, // 3
            compare_op: CompareOp = .none, // 4
            border_color: BorderColor = .float_opaque_black, // 3
            // 1 + 2 + 2 + 1 + 3 + 3 + 3 + 4 + 3 = 22
            _unused: u10 = 0,

            // TODO: support extensions?
            // subsampled_bit_ext: bool = false,
            // subsampled_coarse_reconstruction_bit_ext: bool = false,
            // non_seamless_cube_map_bit_ext: bool = false,
            // descriptor_buffer_capture_replay_bit_ext: bool = false,
            // image_processing_bit_qcom: bool = false,
        };
    };

    pub const Store = struct {
        gpu: *Gpu,
        key_page_count: u32 = 0,
        keys: base.VMultiArray(Key) = .empty,
        storage: base.VArray(vk.Sampler) = .empty,

        const max_capacity = math.maxInt(u8);

        const Key = struct {
            hash: u64 = 0,
            index: u32 = sentinel(u32),
            data: Data = .{},

            pub const uninit = Key{};
        };

        const key_page_size = 8192;
        const max_probes = 16;
        const max_pages = @divFloor(max_capacity, key_page_size);

        pub fn init(gpu: *Gpu) !*Store {
            const self = try base.gpa.create(Store);

            self.* = .{ .gpu = gpu };

            return self;
        }

        pub fn deinit(self: *Store) void {
            for (self.storage.slice()) |handle| {
                self.gpu.device.proxy.destroySampler(handle, null);
            }
            self.keys.deinit();
            self.storage.deinit();
            self.* = undefined;
        }

        pub fn fetch(self: *Store, config: *const Config) !Sampler {
            const key = Data{
                .bits = .{
                    .unnormalized_coordinates = config.unnormalized_coordinates,
                    .mag_filter = config.mag_filter,
                    .min_filter = config.min_filter,
                    .mipmap_mode = config.mipmap_mode,
                    .address_mode_u = config.address_mode_u,
                    .address_mode_v = config.address_mode_v,
                    .address_mode_w = config.address_mode_w,
                    .compare_op = config.compare_op,
                    .border_color = config.border_color,
                },
                .min_lod = .fromF32(config.min_lod),
                .max_lod = .fromF32(config.max_lod),
                .mip_lod_bias = .fromF32(config.mip_lod_bias),
                .max_anisotropy = .fromF32(config.max_anisotropy),
            };

            const hash = base.wyhash(mem.asBytes(&key));
            const hash_index = hash % key_page_size;

            var page_probe_index: u64 = 0;

            const key_index: u64 = page_loop: while (page_probe_index < self.key_page_count) : (page_probe_index += 1) {
                const page_index_offset = page_probe_index * key_page_size;

                var key_probe_count: u32 = 0;
                var key_index_offset: u64 = hash_index;

                while (key_probe_count < max_probes) : ({
                    key_index_offset = (key_index_offset + 1) % key_page_size;
                    key_probe_count += 1;
                }) {
                    const key_index = page_index_offset + key_index_offset;

                    if (isSentinel(self.keys.field(.index, key_index))) {
                        break :page_loop key_index;
                    }

                    if (self.keys.field(.hash, key_index) == hash) {
                        if (mem.eql(u8, mem.asBytes(self.keys.fieldPtr(.data, key_index)), mem.asBytes(&key))) {
                            break :page_loop key_index;
                        }
                    }
                }
            } else new_page: {
                const old_key_count = self.keys.count;
                self.key_page_count += 1;
                try self.keys.ensureCapacity(self.key_page_count * key_page_size);
                self.keys.count = key_page_size;
                @memset(self.keys.sliceMut(.hash)[old_key_count..], Key.uninit.hash);
                @memset(self.keys.sliceMut(.index)[old_key_count..], Key.uninit.index);
                @memset(self.keys.sliceMut(.data)[old_key_count..], Key.uninit.data);
                break :new_page hash_index;
            };

            const storage_index = self.keys.fieldMut(.index, key_index);

            if (!isSentinel(storage_index.*)) {
                return .{ .storage_index = storage_index.* };
            }

            const new_index = self.storage.count;
            if (new_index >= self.gpu.max_samplers) return error.OutOfMemory;

            const compare_op = config.compare_op.toVk();

            const handle = try self.gpu.device.proxy.createSampler(&.{
                .mag_filter = config.mag_filter.toVk(),
                .min_filter = config.min_filter.toVk(),
                .mipmap_mode = config.mipmap_mode.toVk(),
                .address_mode_u = config.address_mode_u.toVk(),
                .address_mode_v = config.address_mode_v.toVk(),
                .address_mode_w = config.address_mode_w.toVk(),
                .anisotropy_enable = if (config.max_anisotropy > 0) .true else .false,
                .max_anisotropy = config.max_anisotropy,
                .compare_enable = if (compare_op != null) .true else .false,
                .compare_op = compare_op orelse .always,
                .min_lod = config.min_lod,
                .max_lod = config.max_lod,
                .mip_lod_bias = config.mip_lod_bias,
                .border_color = config.border_color.toVk(),
                .unnormalized_coordinates = if (config.unnormalized_coordinates) .true else .false,
            }, null);
            errdefer self.gpu.device.proxy.destroySampler(handle, null);

            try self.storage.push(handle);

            storage_index.* = @intCast(new_index);

            self.keys.fieldMut(.hash, key_index).* = hash;
            self.keys.fieldMut(.data, key_index).* = key;

            self.gpu.device.proxy.updateDescriptorSets(&.{
                vk.WriteDescriptorSet{
                    .dst_set = self.gpu.descriptor_set,
                    .dst_binding = 1,
                    .dst_array_element = storage_index.*,
                    .descriptor_count = 1,
                    .descriptor_type = .sampler,
                    .p_image_info = &.{
                        vk.DescriptorImageInfo{
                            .sampler = handle,
                            .image_view = .null_handle,
                            .image_layout = .undefined,
                        },
                    },
                    .p_buffer_info = undefined,
                    .p_texel_buffer_view = undefined,
                },
            }, null);

            return .{ .storage_index = storage_index.* };
        }
    };
};

pub fn RingBuffer(comptime T: type) type {
    return struct {
        managed_buffer: Buffer,
        base_ptr: [*]T,
        base_device_address: DeviceAddress,

        const Self = @This();

        const frame_size = @sizeOf(T);

        pub fn init(gpu: *Gpu) !Self {
            const total_size = frame_size * frame.max_in_flight;

            const managed_buffer = try Buffer.initAdvanced(
                gpu,
                @intCast(total_size),
                .{ .shader_device_address_bit = true }, // We need the GPU address!
                .{ .host_visible_bit = true, .host_coherent_bit = true },
            );
            errdefer managed_buffer.deinit(gpu);

            const alloc_info = managed_buffer.getAllocationInfo(gpu);

            return .{
                .managed_buffer = managed_buffer,
                .base_ptr = @ptrCast(@alignCast(alloc_info.pMappedData.?)),
                .base_device_address = managed_buffer.getDeviceAddress(gpu),
            };
        }

        pub fn deinit(self: *Self, gpu: *Gpu) void {
            self.managed_buffer.deinit(gpu);
            self.* = undefined;
        }

        pub fn getPtr(self: *Self, frame_id: frame.Id) *T {
            return &self.base_ptr[frame_id];
        }

        pub fn getDeviceAddress(self: *Self, frame_id: frame.Id) DeviceAddress {
            const offset = @as(u64, frame_id) * frame_size;
            return self.base_device_address + offset;
        }
    };
}

pub const StagingBuffer = struct {
    managed_buffer: Buffer,
    ptr: [*]u8,
    offset: u64,
    capacity: u64,

    pub fn init(gpu: *Gpu, capacity: u32) !StagingBuffer {
        var self: StagingBuffer = undefined;

        self.offset = 0;
        self.capacity = capacity;

        self.managed_buffer = try Buffer.initAdvanced(
            gpu,
            capacity,
            .{ .transfer_src_bit = true },
            .{ .host_visible_bit = true, .host_coherent_bit = true },
        );
        errdefer self.managed_buffer.deinit(gpu);

        const alloc_info = self.managed_buffer.getAllocationInfo(gpu);
        self.ptr = @ptrCast(alloc_info.pMappedData.?);

        return self;
    }

    pub fn deinit(self: *StagingBuffer, gpu: *Gpu) void {
        self.managed_buffer.deinit(gpu);
        self.* = undefined;
    }

    pub fn reset(self: *StagingBuffer) void {
        self.offset = 0;
    }

    pub fn push(self: *StagingBuffer, bytes: []const u8) ![]const u8 {
        const a = self.offset;
        if (a + bytes.len > self.capacity) return error.OutOfMemory;
        self.offset += bytes.len;
        const buf = self.ptr[a..self.offset];
        @memcpy(buf, bytes);
        return buf;
    }
};

pub const SwapChain = struct {
    gpu: *Gpu,
    surface_format: vk.SurfaceFormatKHR,
    present_mode: vk.PresentModeKHR,
    extent: vec2u,
    handle: vk.SwapchainKHR,

    swap_images: []vk.Image,
    swap_views: []ImageView,
    swap_semaphores: []vk.Semaphore,
    image_index: u32,

    avail_semaphores: frame.InFlightArray(vk.Semaphore),
    fences: frame.InFlightArray(vk.Fence),

    pub const PresentState = enum {
        optimal,
        suboptimal,
    };

    pub fn init(gpu: *Gpu, extent: vec2u) !SwapChain {
        var self = SwapChain{
            .gpu = gpu,
            .surface_format = undefined,
            .present_mode = undefined,
            .extent = extent,
            .handle = .null_handle,
            .swap_images = &.{},
            .swap_views = &.{},
            .swap_semaphores = &.{},
            .avail_semaphores = undefined,
            .fences = undefined,
            .image_index = 0,
        };

        var j: usize = 0;
        errdefer for (0..j) |index| {
            self.gpu.device.proxy.destroySemaphore(self.avail_semaphores[index], null);
        };

        for (0..frame.max_in_flight) |slot_index| {
            self.avail_semaphores[slot_index] = try self.gpu.device.proxy.createSemaphore(&.{}, null);
            errdefer self.gpu.device.proxy.destroySemaphore(self.avail_semaphores[slot_index], null);

            self.fences[slot_index] = try self.gpu.device.proxy.createFence(
                &.{ .flags = .{ .signaled_bit = true } },
                null,
            );
            errdefer self.gpu.device.proxy.destroyFence(self.fences[slot_index], null);

            j += 1;
        }

        try self.initRecycle();

        return self;
    }

    pub fn initRecycle(self: *SwapChain) !void {
        const caps =
            try self.gpu.device.instance.proxy.getPhysicalDeviceSurfaceCapabilitiesKHR(self.gpu.device.pdev, self.gpu.device.present.?.surface);
        self.extent = findActualExtent(caps, self.extent);
        if (@reduce(.Or, linalg.zero(linalg.vec2u) == self.extent)) {
            return error.InvalidSurfaceDimensions;
        }

        const surface_format = try self.findSurfaceFormat();
        const present_mode = try self.findPresentMode();

        var image_count = caps.min_image_count + 1;
        if (caps.max_image_count > 0) {
            image_count = @min(image_count, caps.max_image_count);
        }

        const qfi = [_]u32{
            self.gpu.device.graphics_queue.family,
            self.gpu.device.present.?.queue.family,
        };
        const sharing_mode: vk.SharingMode =
            if (self.gpu.device.graphics_queue.family != self.gpu.device.present.?.queue.family)
                .concurrent
            else
                .exclusive;

        const handle = try self.gpu.device.proxy.createSwapchainKHR(&.{
            .surface = self.gpu.device.present.?.surface,
            .min_image_count = image_count,
            .image_format = surface_format.format,
            .image_color_space = surface_format.color_space,
            .image_extent = .{ .width = self.extent[0], .height = self.extent[1] },
            .image_array_layers = 1,
            .image_usage = .{ .color_attachment_bit = true, .transfer_dst_bit = true },
            .image_sharing_mode = sharing_mode,
            .queue_family_index_count = qfi.len,
            .p_queue_family_indices = &qfi,
            .pre_transform = caps.current_transform,
            .composite_alpha = .{ .opaque_bit_khr = true },
            .present_mode = present_mode,
            .clipped = .true,
            .old_swapchain = self.handle,
        }, null);
        errdefer self.gpu.device.proxy.destroySwapchainKHR(handle, null);

        if (self.handle != .null_handle) {
            self.gpu.device.proxy.destroySwapchainKHR(self.handle, null);
        }

        self.handle = handle;
        self.surface_format = surface_format;
        self.present_mode = present_mode;
        self.image_index = 0;

        self.swap_images = try self.gpu.device.proxy.getSwapchainImagesAllocKHR(self.handle, base.gpa);
        errdefer base.gpa.free(self.swap_images);

        self.swap_views = try base.gpa.alloc(ImageView, self.swap_images.len);
        errdefer base.gpa.free(self.swap_views);

        self.swap_semaphores = try base.gpa.alloc(vk.Semaphore, self.swap_images.len);
        errdefer base.gpa.free(self.swap_semaphores);

        var i: usize = 0;
        errdefer for (0..i) |index| {
            self.gpu.device.proxy.destroyImageView(self.swap_views[index], null);
            self.gpu.device.proxy.destroySemaphore(self.swap_semaphores[index], null);
        };

        for (0..self.swap_images.len) |index| {
            self.swap_views[index] = try self.gpu.device.proxy.createImageView(
                &.{
                    .image = self.swap_images[index],
                    .view_type = .@"2d",
                    .format = surface_format.format,
                    .components = .{
                        .r = .identity,
                        .g = .identity,
                        .b = .identity,
                        .a = .identity,
                    },
                    .subresource_range = .{
                        .aspect_mask = .{ .color_bit = true },
                        .base_mip_level = 0,
                        .level_count = 1,
                        .base_array_layer = 0,
                        .layer_count = 1,
                    },
                },
                null,
            );
            errdefer self.gpu.device.proxy.destroyImageView(self.swap_views[index], null);

            self.swap_semaphores[index] = try self.gpu.device.proxy.createSemaphore(&.{}, null);
            errdefer self.gpu.device.proxy.destroySemaphore(self.swap_semaphores[index], null);

            i += 1;
        }
    }

    pub fn deinit(self: *SwapChain) void {
        for (0..self.swap_images.len) |index| {
            self.gpu.device.proxy.destroySemaphore(self.swap_semaphores[index], null);
            self.gpu.device.proxy.destroyImageView(self.swap_views[index], null);
        }

        for (0..frame.max_in_flight) |index| {
            self.gpu.device.proxy.destroySemaphore(self.avail_semaphores[index], null);
            self.gpu.device.proxy.destroyFence(self.fences[index], null);
        }

        base.gpa.free(self.swap_images);
        base.gpa.free(self.swap_views);
        base.gpa.free(self.swap_semaphores);

        self.gpu.device.proxy.destroySwapchainKHR(self.handle, null);
    }

    pub fn recreate(self: *SwapChain, new_extent: linalg.vec2u) !void {
        // NOTE: Just because present has returned does not mean the gpu is done with this frame;
        //       in order to avoid an invalid free of the existing swapchain semaphore, we must wait for idle.
        try self.gpu.device.proxy.deviceWaitIdle();

        for (0..self.swap_images.len) |index| {
            self.gpu.device.proxy.destroySemaphore(self.swap_semaphores[index], null);
            self.gpu.device.proxy.destroyImageView(self.swap_views[index], null);
        }

        base.gpa.free(self.swap_images);
        base.gpa.free(self.swap_views);
        base.gpa.free(self.swap_semaphores);

        self.swap_images = &.{};
        self.swap_views = &.{};
        self.swap_semaphores = &.{};

        self.extent = new_extent;

        try self.initRecycle();
    }

    fn currentImage(self: *const SwapChain) vk.Image {
        return self.swap_images[self.image_index].image;
    }

    pub fn beginFrame(self: *SwapChain, frame_id: frame.Id, size: linalg.vec2u, commands: *CommandBuffer) ?ImageView {
        if (size[0] == 0 or size[1] == 0) {
            log.debug("cannot create 0-sized swap frame, skipping.", .{});
            return null;
        }

        if (size[0] != self.extent[0] or size[1] != self.extent[1] or self.swap_images.len == 0) {
            self.recreate(size) catch |err| {
                log.warn("failed to begin swapchain frame: {s}", .{@errorName(err)});
            };
            return null;
        }

        if (self.acquireNextImage(frame_id) catch |err| {
            log.warn("failed to begin swapchain frame: {s}", .{@errorName(err)});
            return null;
        }) {
            commands.wait_semas.append(base.gpa, self.avail_semaphores[frame_id]) catch |err| {
                log.warn("failed to begin swapchain frame: {s}", .{@errorName(err)});
                return null;
            };

            const swap_image = self.swap_images[self.image_index];
            const swap_view = self.swap_views[self.image_index];

            commands.transitionImageLayout(
                swap_image,

                // NOTE: passing .undefined as the old_layout discards the previous
                // contents of the image. For a swapchain, this is exactly what we
                // want, since we overwrite the whole screen anyway. Later
                // implementations referencing this one should note that this is
                // not always desired, for example in overdraw effects, but
                // discarding the previous frame's data is intentional here,
                // as it helps the rasterizer optimize memory bandwidth.

                .undefined,
                .color_attachment_optimal,
                .{ .color_attachment_output_bit = true },
                .{},
                .{ .color_attachment_output_bit = true },
                .{ .color_attachment_write_bit = true },
            );
            return swap_view;
        }

        self.recreate(size) catch |err| {
            log.warn("failed to begin swapchain frame: {s}", .{@errorName(err)});
        };
        return null;
    }

    pub fn endFrame(self: *SwapChain, commands: *CommandBuffer) void {
        const swap_image = self.swap_images[self.image_index];
        commands.transitionImageLayout(
            swap_image,
            .color_attachment_optimal,
            .present_src_khr,
            .{ .color_attachment_output_bit = true },
            .{ .color_attachment_write_bit = true },
            .{ .bottom_of_pipe_bit = true },
            .{},
        );

        const swap_semaphore = self.swap_semaphores[self.image_index];
        commands.signal_semas.append(base.gpa, swap_semaphore) catch {
            log.err("failed to add swap chain semaphore to frame signal queue; window will miss an update", .{});
        };
    }

    fn acquireNextImage(self: *SwapChain, frame_id: frame.Id) !bool {
        const result = try self.gpu.device.proxy.acquireNextImageKHR(
            self.handle,
            math.maxInt(u64),
            self.avail_semaphores[frame_id],
            .null_handle,
        );

        // NOTE: Only return false if the swapchain is completely out of date.
        //       If it's suboptimal, we've still acquired an image and the semaphore
        //       will be signaled, so we must proceed and render to it.
        if (result.result == .error_out_of_date_khr) {
            return false;
        }

        self.image_index = result.image_index;

        return true;
    }

    pub fn presentImage(self: *SwapChain) PresentState {
        const swap_semaphore = self.swap_semaphores[self.image_index];

        const present_result = self.gpu.device.proxy.queuePresentKHR(
            self.gpu.device.present.?.queue.handle,
            &.{
                .wait_semaphore_count = 1,
                .p_wait_semaphores = (&swap_semaphore)[0..1],
                .swapchain_count = 1,
                .p_swapchains = (&self.handle)[0..1],
                .p_image_indices = (&self.image_index)[0..1],
            },
        ) catch |err| switch (err) {
            error.OutOfDateKHR => return .suboptimal,
            else => |narrow| {
                log.err("Failed to present swapchain image: {s}", .{@errorName(narrow)});
                return .suboptimal;
            },
        };

        return switch (present_result) {
            .success => .optimal,
            .suboptimal_khr => .suboptimal,
            else => unreachable,
        };
    }

    fn findSurfaceFormat(self: *SwapChain) !vk.SurfaceFormatKHR {
        const preferred = vk.SurfaceFormatKHR{
            .format = .b8g8r8a8_srgb,
            .color_space = .srgb_nonlinear_khr,
        };

        const surface_formats = try self.gpu.device.instance.proxy.getPhysicalDeviceSurfaceFormatsAllocKHR(
            self.gpu.device.pdev,
            self.gpu.device.present.?.surface,
            base.gpa,
        );
        defer base.gpa.free(surface_formats);

        for (surface_formats) |sfmt| {
            if (meta.eql(sfmt, preferred)) {
                return preferred;
            }
        }

        return surface_formats[0]; // There must always be at least one supported surface format
    }

    fn findPresentMode(self: *SwapChain) !vk.PresentModeKHR {
        const present_modes = try self.gpu.device.instance.proxy.getPhysicalDeviceSurfacePresentModesAllocKHR(
            self.gpu.device.pdev,
            self.gpu.device.present.?.surface,
            base.gpa,
        );
        defer base.gpa.free(present_modes);

        const preferred = [_]vk.PresentModeKHR{
            .mailbox_khr,
            .immediate_khr,
        };

        for (preferred) |present_mode| {
            if (mem.indexOfScalar(vk.PresentModeKHR, present_modes, present_mode) != null) {
                return present_mode;
            }
        }

        return .fifo_khr;
    }

    fn findActualExtent(caps: vk.SurfaceCapabilitiesKHR, extent: linalg.vec2u) linalg.vec2u {
        if (caps.current_extent.width != 0xFFFF_FFFF) {
            return .{ caps.current_extent.width, caps.current_extent.height };
        } else {
            return .{
                math.clamp(extent[0], caps.min_image_extent.width, caps.max_image_extent.width),
                math.clamp(extent[1], caps.min_image_extent.height, caps.max_image_extent.height),
            };
        }
    }
};

pub const ShaderModule = struct {
    handle: vk.ShaderModule,

    pub fn init(gpu: *Gpu, bytecode: Spirv) !ShaderModule {
        var self: ShaderModule = undefined;

        self.handle = try gpu.device.proxy.createShaderModule(
            &vk.ShaderModuleCreateInfo{
                .code_size = bytecode.len * 4,
                .p_code = bytecode.ptr,
            },
            null,
        );

        return self;
    }

    pub fn deinit(self: *ShaderModule, gpu: *Gpu) void {
        gpu.device.proxy.destroyShaderModule(self.handle, null);
        self.* = undefined;
    }
};

pub const Pipeline = struct {
    kind: Kind,
    handle: vk.Pipeline,
    layout: vk.PipelineLayout,
    push_constants: []const PushConstantRange,

    pub const Kind = enum { @"2d", @"3d", compute };

    pub fn graphics(
        gpu: *Gpu,
        vertex_mod: ShaderModule,
        fragment_mod: ShaderModule,
        dimensions: enum { @"2d", @"3d" },
        format: vk.Format,
        samples: SampleCount,
        push_constants: []const PushConstantRange,
    ) !Pipeline {
        var self: Pipeline = undefined;

        self.kind, const stencil_state = switch (dimensions) {
            .@"2d" => .{ .@"2d", &stencil_state_2d },
            .@"3d" => .{ .@"3d", &stencil_state_3d },
        };
        self.push_constants = try base.gpa.dupe(PushConstantRange, push_constants);
        errdefer base.gpa.free(self.push_constants);

        // TODO: ensure total push constants size not too large?
        // TODO: maybe like, a comptime system for just passing it (a) type(s)? e.g. something like std.mutliarraylist

        self.layout = try gpu.device.proxy.createPipelineLayout(
            &vk.PipelineLayoutCreateInfo{
                .set_layout_count = 1,
                .p_set_layouts = &.{gpu.descriptor_layout},
                .push_constant_range_count = @intCast(self.push_constants.len),
                .p_push_constant_ranges = self.push_constants.ptr,
            },
            null,
        );
        errdefer gpu.device.proxy.destroyPipelineLayout(self.layout, null);

        const vk_result = try gpu.device.proxy.createGraphicsPipelines(
            .null_handle,
            &.{
                vk.GraphicsPipelineCreateInfo{
                    .flags = .{},

                    .layout = self.layout,

                    .p_next = &vk.PipelineRenderingCreateInfo{
                        .view_mask = 0,
                        .color_attachment_count = 1,
                        .p_color_attachment_formats = @ptrCast(&format), // * -> [*]
                        .depth_attachment_format = .undefined,
                        .stencil_attachment_format = .undefined,
                    },

                    .p_input_assembly_state = &vk.PipelineInputAssemblyStateCreateInfo{
                        .flags = .{},
                        .topology = .triangle_list,
                        .primitive_restart_enable = .false,
                    },

                    .p_vertex_input_state = &vk.PipelineVertexInputStateCreateInfo{
                        .flags = .{},
                        .vertex_binding_description_count = 0,
                        .p_vertex_binding_descriptions = null,
                        .vertex_attribute_description_count = 0,
                        .p_vertex_attribute_descriptions = null,
                    },

                    .p_dynamic_state = &vk.PipelineDynamicStateCreateInfo{
                        .flags = .{},
                        .dynamic_state_count = 2,
                        .p_dynamic_states = &[_]vk.DynamicState{ .viewport, .scissor },
                    },

                    .p_viewport_state = &vk.PipelineViewportStateCreateInfo{
                        .flags = .{},
                        .viewport_count = 1,
                        .p_viewports = null,
                        .scissor_count = 1,
                        .p_scissors = null,
                    },

                    .p_rasterization_state = &vk.PipelineRasterizationStateCreateInfo{
                        .flags = .{},

                        .rasterizer_discard_enable = .false,

                        .depth_clamp_enable = .false,

                        .polygon_mode = .fill,

                        .cull_mode = .{ .back_bit = true },
                        .front_face = .counter_clockwise,

                        .depth_bias_enable = .false,
                        .depth_bias_constant_factor = 0,
                        .depth_bias_clamp = 0,
                        .depth_bias_slope_factor = 0,

                        .line_width = 1,
                    },

                    .p_multisample_state = &samples.createInfo(),

                    .p_depth_stencil_state = stencil_state,

                    .p_color_blend_state = &vk.PipelineColorBlendStateCreateInfo{
                        .flags = .{},

                        .blend_constants = @splat(0),

                        .logic_op_enable = .false,
                        .logic_op = .copy,

                        .attachment_count = 1,
                        .p_attachments = &.{
                            vk.PipelineColorBlendAttachmentState{
                                .blend_enable = .true,
                                .src_color_blend_factor = .one,
                                .dst_color_blend_factor = .one_minus_src_alpha,
                                .color_blend_op = .add,
                                .src_alpha_blend_factor = .one,
                                .dst_alpha_blend_factor = .one_minus_src_alpha,
                                .alpha_blend_op = .add,
                                .color_write_mask = .{
                                    .r_bit = true,
                                    .g_bit = true,
                                    .b_bit = true,
                                    .a_bit = true,
                                },
                            },
                        },
                    },

                    .stage_count = 2,
                    .p_stages = &[_]vk.PipelineShaderStageCreateInfo{
                        .{
                            .stage = .{ .vertex_bit = true },
                            .module = vertex_mod.handle,
                            .p_name = "main",
                        },
                        .{
                            .stage = .{ .fragment_bit = true },
                            .module = fragment_mod.handle,
                            .p_name = "main",
                        },
                    },

                    .subpass = 0,
                    .render_pass = .null_handle,
                    .base_pipeline_handle = .null_handle,
                    .base_pipeline_index = -1,
                },
            },
            null,
            @ptrCast(&self.handle), // * -> []
        );

        if (vk_result != .success) {
            log.err("Failed to create pipeline: {s}", .{@tagName(vk_result)});
            return error.FailedToCreatePipeline;
        }

        return self;
    }

    pub fn deinit(self: *Pipeline, gpu: *Gpu) void {
        gpu.device.proxy.destroyPipelineLayout(self.layout, null);
        gpu.device.proxy.destroyPipeline(self.handle, null);
        self.* = undefined;
    }

    const stencil_state_2d = vk.PipelineDepthStencilStateCreateInfo{
        .depth_test_enable = .false,
        .depth_write_enable = .false,
        .depth_compare_op = .always,
        .depth_bounds_test_enable = .false,
        .stencil_test_enable = .false,
        .front = .{
            .fail_op = .keep,
            .pass_op = .keep,
            .depth_fail_op = .keep,
            .compare_op = .never,
            .compare_mask = 0,
            .write_mask = 0,
            .reference = 0,
        },
        .back = .{
            .fail_op = .keep,
            .pass_op = .keep,
            .depth_fail_op = .keep,
            .compare_op = .never,
            .compare_mask = 0,
            .write_mask = 0,
            .reference = 0,
        },
        .min_depth_bounds = 0.0,
        .max_depth_bounds = 1.0,
    };

    const stencil_state_3d = vk.PipelineDepthStencilStateCreateInfo{
        .depth_test_enable = .true,
        .depth_write_enable = .true,
        .depth_compare_op = .less,
        .depth_bounds_test_enable = .false,
        .stencil_test_enable = .false,
        .front = .{
            .fail_op = .keep,
            .pass_op = .keep,
            .depth_fail_op = .keep,
            .compare_op = .never,
            .compare_mask = 0,
            .write_mask = 0,
            .reference = 0,
        },
        .back = .{
            .fail_op = .keep,
            .pass_op = .keep,
            .depth_fail_op = .keep,
            .compare_op = .never,
            .compare_mask = 0,
            .write_mask = 0,
            .reference = 0,
        },
        .min_depth_bounds = 0.0,
        .max_depth_bounds = 1.0,
    };
};

// TODO: Implement an automatic fallback that issues a vkCmdPipelineBarrier,
// submits the current command buffer, waits for it, resets the staging offset, and
// resumes recording. This would allow us to handle big asset uploads transparently.
pub const CommandBuffer = struct {
    gpu: *Gpu,
    handle: vk.CommandBuffer,
    staging: StagingBuffer,

    area: ?vk.Rect2D,
    pipeline: ?struct { state: *Pipeline, push_constant_index: u32 = 0 },

    wait_semas: base.ArrayList(vk.Semaphore),
    signal_semas: base.ArrayList(vk.Semaphore),
    image_barriers: base.ArrayMap(Image, vk.ImageMemoryBarrier),

    in_flight_fence: vk.Fence,

    flushed: bool,

    pub fn init(gpu: *Gpu) !CommandBuffer {
        var self: CommandBuffer = undefined;
        self.gpu = gpu;
        self.flushed = false;

        try self.gpu.device.proxy.allocateCommandBuffers(
            &.{
                .command_pool = self.gpu.command_pool,
                .level = .primary,
                .command_buffer_count = 1,
            },
            @ptrCast(&self.handle),
        );
        errdefer self.gpu.device.proxy.freeCommandBuffers(self.gpu.command_pool, &.{self.handle});

        self.staging = try StagingBuffer.init(
            self.gpu,
            (@import("static_config").gpu_staging_capacity * 1024 * 1024),
        );
        errdefer self.staging.deinit(self.gpu);

        self.area = null;
        self.pipeline = null;

        self.wait_semas = try .initCapacity(base.gpa, 4096);
        errdefer self.wait_semas.deinit(base.gpa);

        self.signal_semas = try .initCapacity(base.gpa, 4096);
        errdefer self.signal_semas.deinit(base.gpa);

        self.image_barriers = .empty;
        try self.image_barriers.ensureTotalCapacity(base.gpa, 4096);
        errdefer self.image_barriers.deinit(base.gpa);

        self.in_flight_fence = try self.gpu.device.proxy.createFence(
            &.{ .flags = .{ .signaled_bit = true } },
            null,
        );

        return self;
    }

    pub fn deinit(self: *CommandBuffer) void {
        self.wait_semas.deinit(base.gpa);
        self.signal_semas.deinit(base.gpa);
        self.image_barriers.deinit(base.gpa);
        self.gpu.device.proxy.destroyFence(self.in_flight_fence, null);

        self.gpu.device.proxy.freeCommandBuffers(self.gpu.command_pool, &.{self.handle});
        self.staging.deinit(self.gpu);
    }

    pub fn reset(self: *CommandBuffer) !void {
        _ = try self.gpu.device.proxy.waitForFences(
            &.{self.in_flight_fence},
            .true,
            base.math.maxInt(u64),
        );
        try self.gpu.device.proxy.resetFences(&.{self.in_flight_fence});

        self.wait_semas.clearRetainingCapacity();
        self.signal_semas.clearRetainingCapacity();

        try self.gpu.device.proxy.resetCommandBuffer(self.handle, .{});
        try self.gpu.device.proxy.beginCommandBuffer(self.handle, &.{});
        self.staging.reset();

        self.flushed = false;
    }

    pub fn submit(self: *CommandBuffer) void {
        self.flush();

        self.gpu.device.proxy.endCommandBuffer(self.handle) catch |err| {
            log.err("Failed to submit commandbuffer: {s}", .{@errorName(err)});
            return;
        };

        const wait_stages = base.temp.alloc(vk.PipelineStageFlags, self.wait_semas.items.len) catch |err| {
            log.err("Failed to submit commandbuffer: {s}", .{@errorName(err)});
            return;
        };
        for (wait_stages) |*stage| stage.* = .{ .color_attachment_output_bit = true };

        self.gpu.device.proxy.queueSubmit(
            self.gpu.device.graphics_queue.handle,
            &[_]vk.SubmitInfo{.{
                .wait_semaphore_count = @intCast(self.wait_semas.items.len),
                .p_wait_semaphores = self.wait_semas.items.ptr,
                .p_wait_dst_stage_mask = wait_stages.ptr,
                .command_buffer_count = 1,
                .p_command_buffers = &.{self.handle},
                .signal_semaphore_count = @intCast(self.signal_semas.items.len),
                .p_signal_semaphores = self.signal_semas.items.ptr,
            }},
            self.in_flight_fence,
        ) catch |err| {
            log.err("Failed to submit commandbuffer: {s}", .{@errorName(err)});
            return;
        };
    }

    pub fn setViewports(self: *CommandBuffer, viewports: []const vk.Viewport) void {
        self.gpu.device.proxy.cmdSetViewport(self.handle, 0, viewports);
    }

    pub fn setViewport(self: *CommandBuffer, viewport: vk.Viewport) void {
        self.gpu.device.proxy.cmdSetViewport(self.handle, 0, &.{viewport});
    }

    pub fn setScissors(self: *CommandBuffer, scissors: []const vk.Rect2D) void {
        self.gpu.device.proxy.cmdSetScissor(self.handle, 0, scissors);
    }

    pub fn setScissor(self: *CommandBuffer, scissor: vk.Rect2D) void {
        self.gpu.device.proxy.cmdSetScissor(self.handle, 0, &.{scissor});
    }

    pub fn transitionImageLayout(
        self: *CommandBuffer,
        image: vk.Image,
        old_layout: vk.ImageLayout,
        new_layout: vk.ImageLayout,
        src_stage: vk.PipelineStageFlags,
        src_access: vk.AccessFlags,
        dst_stage: vk.PipelineStageFlags,
        dst_access: vk.AccessFlags,
    ) void {
        const barrier = vk.ImageMemoryBarrier{
            .src_access_mask = src_access,
            .dst_access_mask = dst_access,
            .old_layout = old_layout,
            .new_layout = new_layout,
            .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .image = image,
            .subresource_range = .{
                .aspect_mask = .{ .color_bit = true }, // TODO: Extend for depth buffers
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
        };

        self.gpu.device.proxy.cmdPipelineBarrier(
            self.handle,
            src_stage,
            dst_stage,
            .{},
            null,
            null,
            &.{barrier},
        );
    }

    pub fn beginRendering(
        self: *CommandBuffer,
        color_view: ?ImageView,
        depth_view: ?ImageView,
        area: vk.Rect2D,
        clear_color: ?linalg.vec4,
        clear_depth_stencil: ?vk.ClearDepthStencilValue,
    ) void {
        debug.assert(self.area == null);

        self.flush();

        var color_attachment = if (color_view) |cv| vk.RenderingAttachmentInfo{
            .image_view = cv,
            .image_layout = .color_attachment_optimal,
            .resolve_mode = .{},
            .resolve_image_view = .null_handle,
            .resolve_image_layout = .undefined,
            .load_op = if (clear_color != null) .clear else .load,
            .store_op = .store,
            .clear_value = if (clear_color) |c|
                .{ .color = .{ .float_32 = linalg.arrayVectorSwap(c) } }
            else
                undefined,
        } else undefined;

        var depth_attachment = if (depth_view) |dv| vk.RenderingAttachmentInfo{
            .image_view = dv,
            .image_layout = .depth_stencil_attachment_optimal,
            .resolve_mode = .{},
            .resolve_image_view = .null_handle,
            .resolve_image_layout = .undefined,
            .load_op = if (clear_depth_stencil != null) .clear else .load,
            .store_op = .store,
            .clear_value = if (clear_depth_stencil) |c|
                .{ .depth_stencil = c }
            else
                undefined,
        } else undefined;

        const rendering_info = vk.RenderingInfo{
            .flags = .{},
            .render_area = area,
            .layer_count = 1,
            .view_mask = 0,
            .color_attachment_count = if (color_view != null) 1 else 0,
            .p_color_attachments = if (color_view != null)
                @ptrCast(&color_attachment)
            else
                null,
            .p_depth_attachment = if (depth_view != null)
                @ptrCast(&depth_attachment)
            else
                null,
            .p_stencil_attachment = null,
        };

        self.gpu.device.proxy.cmdBeginRendering(self.handle, &rendering_info);
        self.area = area;
    }

    pub fn endRendering(self: *CommandBuffer) void {
        debug.assert(self.area != null);
        self.gpu.device.proxy.cmdEndRendering(self.handle);
        self.area = null;
    }

    pub fn getOffset(self: *CommandBuffer) linalg.vec2i {
        return .{ self.area.offset.x, self.area.offset.y };
    }

    pub fn getOffsetF(self: *CommandBuffer) linalg.vec2 {
        return @floatFromInt(self.getOffset());
    }

    pub fn getSize(self: *CommandBuffer) linalg.vec2u {
        return .{ self.area.extent.width, self.area.extent.height };
    }

    pub fn getSizeF(self: *CommandBuffer) linalg.vec2 {
        return @floatFromInt(self.getSize());
    }

    pub fn bindPipeline(self: *CommandBuffer, pipeline: *Pipeline) void {
        debug.assert(self.area != null);
        debug.assert(self.pipeline == null);

        self.gpu.device.proxy.cmdBindDescriptorSets(
            self.handle,
            .graphics,
            pipeline.layout,
            0,
            @ptrCast(&self.gpu.descriptor_set),
            null,
        );

        self.gpu.device.proxy.cmdBindPipeline(
            self.handle,
            .graphics,
            pipeline.handle,
        );

        self.pipeline = .{ .state = pipeline };
    }

    pub fn unbindPipeline(self: *CommandBuffer, pipeline: *Pipeline) void {
        debug.assert(self.pipeline.?.state == pipeline);
        self.pipeline = null;
    }

    pub fn pushConstants(self: *CommandBuffer, constants: anytype) void {
        const current_constant = self.pipeline.?.state.push_constants[self.pipeline.?.push_constant_index];
        self.pipeline.?.push_constant_index += 1;

        debug.assert(@sizeOf(@TypeOf(constants)) == current_constant.size);

        self.gpu.device.proxy.cmdPushConstants(
            self.handle,
            self.pipeline.?.state.layout,
            current_constant.stage_flags,
            0,
            current_constant.size,
            &constants,
        );
    }

    pub fn draw(self: *CommandBuffer, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32) void {
        debug.assert(self.pipeline != null);

        self.gpu.device.proxy.cmdDraw(
            self.handle,
            vertex_count,
            instance_count,
            first_vertex,
            first_instance,
        );
    }

    pub fn flush(self: *CommandBuffer) void {
        if (self.flushed) return;
        defer self.flushed = true;

        const memory_barrier = vk.MemoryBarrier{
            .src_access_mask = .{ .transfer_write_bit = true },
            .dst_access_mask = .{ .shader_read_bit = true }, // Or vertex_attribute_read_bit if using standard VBOs
        };

        self.gpu.device.proxy.cmdPipelineBarrier(
            self.handle,
            .{ .transfer_bit = true },
            .{ .vertex_shader_bit = true, .fragment_shader_bit = true },
            .{},
            &[_]vk.MemoryBarrier{memory_barrier}, // <-- Added global memory barrier here!
            null,
            self.image_barriers.values(),
        );

        self.image_barriers.clearRetainingCapacity();
    }

    pub fn syncImage(
        self: *CommandBuffer,
        image: Image,
        bytes: []const u8,
    ) !void {
        if (bytes.len == 0) return;
        debug.assert(image.generation == self.gpu.store.image.storage.field(.generation, image.storage_index));

        const width = self.gpu.store.image.storage.field(.width, image.storage_index);
        const height = self.gpu.store.image.storage.field(.height, image.storage_index);
        if (width == 0 or height == 0) return;

        const gop = self.image_barriers.getOrPut(base.gpa, image) catch |err| {
            log.err("failed to queue image barrier: {s}", .{@errorName(err)});
            return err;
        };

        // Align offset to 16 bytes minimum
        const alignment: u64 = 16;
        self.staging.offset = (self.staging.offset + alignment - 1) & ~(alignment - 1);

        if (self.staging.offset + bytes.len > self.staging.capacity) {
            return error.StagingBufferOverflow;
        }

        const dst_ptr = self.staging.ptr + self.staging.offset;
        @memcpy(dst_ptr[0..bytes.len], bytes);

        if (!gop.found_existing) {
            // Pre-copy barrier (Executed immediately)
            self.gpu.device.proxy.cmdPipelineBarrier(
                self.handle,
                .{ .top_of_pipe_bit = true },
                .{ .transfer_bit = true },
                .{},
                null,
                null,
                &[_]vk.ImageMemoryBarrier{.{
                    .src_access_mask = .{},
                    .dst_access_mask = .{ .transfer_write_bit = true },
                    .old_layout = self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).*.?.layout,
                    .new_layout = .transfer_dst_optimal,
                    .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                    .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                    .image = image.getHandle(self.gpu),
                    .subresource_range = .{
                        .aspect_mask = .{ .color_bit = true },
                        .base_mip_level = 0,
                        .level_count = 1,
                        .base_array_layer = 0,
                        .layer_count = 1,
                    },
                }},
            );

            // Post-copy barrier (Queued for later)
            gop.value_ptr.* = vk.ImageMemoryBarrier{
                .src_access_mask = .{ .transfer_write_bit = true },
                .dst_access_mask = .{ .shader_read_bit = true },
                .old_layout = .transfer_dst_optimal,
                .new_layout = .shader_read_only_optimal,
                .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .image = image.getHandle(self.gpu),
                .subresource_range = .{
                    .aspect_mask = .{ .color_bit = true },
                    .base_mip_level = 0,
                    .level_count = 1,
                    .base_array_layer = 0,
                    .layer_count = 1,
                },
            };

            self.gpu.store.image.storage.fieldMut(.state, image.storage_index).*.?.layout = .shader_read_only_optimal;
        }

        // Perform copy
        self.gpu.device.proxy.cmdCopyBufferToImage(
            self.handle,
            self.staging.managed_buffer.getHandle(self.gpu),
            image.getHandle(self.gpu),
            .transfer_dst_optimal,
            &[_]vk.BufferImageCopy{.{
                .buffer_offset = self.staging.offset,
                .buffer_row_length = 0,
                .buffer_image_height = 0,
                .image_subresource = .{
                    .aspect_mask = .{ .color_bit = true },
                    .mip_level = 0,
                    .base_array_layer = 0,
                    .layer_count = 1,
                },
                .image_offset = .{ .x = 0, .y = 0, .z = 0 },
                .image_extent = .{
                    .width = width,
                    .height = height,
                    .depth = 1,
                },
            }},
        );

        self.staging.offset += bytes.len;
        self.flushed = false;
    }

    pub fn syncImageRegion(
        self: *CommandBuffer,
        image: Image,
        bytes: []const u8,
        dest_pos: linalg.vec2u,
        dest_dims: linalg.vec2u,
    ) !void {
        if (dest_dims[0] == 0 or dest_dims[1] == 0 or bytes.len == 0) return;
        debug.assert(image.generation == self.gpu.store.image.storage.field(.generation, image.storage_index));

        // Align offset to 16 bytes minimum
        const alignment: u64 = 16;
        self.staging.offset = (self.staging.offset + alignment - 1) & ~(alignment - 1);

        if (self.staging.offset + bytes.len > self.staging.capacity) {
            return error.StagingBufferOverflow;
        }

        const dst_ptr = self.staging.ptr + self.staging.offset;
        @memcpy(dst_ptr[0..bytes.len], bytes);

        if (self.gpu.store.image.storage.field(.barrier, image.storage_index) == null) {
            // Pre-copy barrier (Executed immediately)
            self.gpu.device.proxy.cmdPipelineBarrier(
                self.handle,
                .{ .top_of_pipe_bit = true },
                .{ .transfer_bit = true },
                .{},
                null,
                null,
                &[_]vk.ImageMemoryBarrier{.{
                    .src_access_mask = .{},
                    .dst_access_mask = .{ .transfer_write_bit = true },
                    .old_layout = self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.layout,
                    .new_layout = .transfer_dst_optimal,
                    .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                    .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                    .image = self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.handle,
                    .subresource_range = .{
                        .aspect_mask = .{ .color_bit = true },
                        .base_mip_level = 0,
                        .level_count = 1,
                        .base_array_layer = 0,
                        .layer_count = 1,
                    },
                }},
            );

            // Post-copy barrier (Queued for later)
            self.gpu.store.image.storage.fieldMut(.barrier, image.storage_index).* = vk.ImageMemoryBarrier{
                .src_access_mask = .{ .transfer_write_bit = true },
                .dst_access_mask = .{ .shader_read_bit = true },
                .old_layout = .transfer_dst_optimal,
                .new_layout = .shader_read_only_optimal,
                .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
                .image = self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.handle,
                .subresource_range = .{
                    .aspect_mask = .{ .color_bit = true },
                    .base_mip_level = 0,
                    .level_count = 1,
                    .base_array_layer = 0,
                    .layer_count = 1,
                },
            };

            self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.layout = .shader_read_only_optimal;
        }

        self.gpu.device.proxy.cmdCopyBufferToImage(
            self.handle,
            self.staging.managed_buffer,
            self.gpu.store.image.storage.fieldPtr(.state, image.storage_index).?.handle,
            .transfer_dst_optimal,
            &[_]vk.BufferImageCopy{.{
                .buffer_offset = self.staging.offset,
                .buffer_row_length = 0,
                .buffer_image_height = 0,
                .image_subresource = .{
                    .aspect_mask = .{ .color_bit = true },
                    .mip_level = 0,
                    .base_array_layer = 0,
                    .layer_count = 1,
                },
                .image_offset = .{
                    .x = @intCast(dest_pos[0]),
                    .y = @intCast(dest_pos[1]),
                    .z = 0,
                },
                .image_extent = .{
                    .width = dest_dims[0],
                    .height = dest_dims[1],
                    .depth = 1,
                },
            }},
        );

        self.staging.offset += bytes.len;
        self.flushed = false;
    }

    pub fn syncBuffer(
        self: *CommandBuffer,
        buffer: Buffer,
        bytes: []const u8,
    ) !void {
        if (buffer.generation != self.gpu.store.buffer.storage.field(.generation, buffer.storage_index)) return error.InvalidBuffer;

        // Align offset to 16 bytes to satisfy Vulkan copy requirements
        const alignment: u64 = 16;
        self.staging.offset = (self.staging.offset + alignment - 1) & ~(alignment - 1);

        if (self.staging.offset + bytes.len > self.staging.capacity) {
            return error.StagingBufferOverflow;
        }

        const dst_ptr = self.staging.ptr + self.staging.offset;
        @memcpy(dst_ptr[0..bytes.len], bytes);

        self.gpu.device.proxy.cmdCopyBuffer(
            self.handle,
            self.gpu.store.buffer.getHandle(self.staging.managed_buffer),
            self.gpu.store.buffer.getHandle(buffer),
            &[_]vk.BufferCopy{
                .{
                    .src_offset = self.staging.offset,
                    .dst_offset = 0,
                    .size = bytes.len,
                },
            },
        );

        self.staging.offset += bytes.len;
        self.flushed = false;
    }

    pub fn syncBufferRegion(
        self: *CommandBuffer,
        buffer: Buffer,
        dst_offset: u64,
        bytes: []const u8,
    ) !void {
        if (buffer.generation != self.gpu.store.buffer.storage.field(.generation, buffer.storage_index)) return error.InvalidBuffer;

        // Align offset to 16 bytes to satisfy Vulkan copy requirements
        const alignment: u64 = 16;
        self.staging.offset = (self.staging.offset + alignment - 1) & ~(alignment - 1);

        if (self.staging.offset + bytes.len > self.staging.capacity) {
            return error.StagingBufferOverflow;
        }

        const dst_ptr = self.staging.ptr + self.staging.offset;
        @memcpy(dst_ptr[0..bytes.len], bytes);

        self.gpu.device.proxy.cmdCopyBuffer(
            self.handle,
            self.staging.managed_buffer,
            self.gpu.store.buffer.storage.field(.state, buffer.storage_index).?.handle,
            &[_]vk.BufferCopy{
                .{
                    .src_offset = self.staging.offset,
                    .dst_offset = dst_offset,
                    .size = bytes.len,
                },
            },
        );

        self.staging.offset += bytes.len;
        self.flushed = false;
    }
};

pub const Spirv = []const u32;

pub const SampleCount = enum(u32) {
    @"1",
    @"2",
    @"4",
    @"8",
    @"16",

    pub fn toVk(self: SampleCount) vk.SampleCountFlags {
        return switch (self) {
            .@"1" => vk.SampleCountFlags{ .@"1_bit" = true },
            .@"2" => vk.SampleCountFlags{ .@"2_bit" = true },
            .@"4" => vk.SampleCountFlags{ .@"4_bit" = true },
            .@"8" => vk.SampleCountFlags{ .@"8_bit" = true },
            .@"16" => vk.SampleCountFlags{ .@"16_bit" = true },
        };
    }

    pub fn fromVk(flags: vk.SampleCountFlags) SampleCount {
        if (flags.@"16_bit") return .@"16";
        if (flags.@"8_bit") return .@"8";
        if (flags.@"4_bit") return .@"4";
        if (flags.@"2_bit") return .@"2";
        if (flags.@"1_bit") return .@"1";
        debug.panic("Unsupported vk.SampleCountFlags; expected 1, 2, 4, 8 or 16, got: {any}", .{flags});
    }

    pub fn createInfo(self: SampleCount) vk.PipelineMultisampleStateCreateInfo {
        return vk.PipelineMultisampleStateCreateInfo{
            .flags = .{},

            .rasterization_samples = self.toVk(),

            .sample_shading_enable = .false,
            .min_sample_shading = 1,

            .alpha_to_coverage_enable = .false,
            .alpha_to_one_enable = .false,

            .p_sample_mask = null,
        };
    }
};

pub const CanonFloat = packed struct(u32) {
    bits: u32 = @bitCast(@as(f32, 0.0)),

    pub const zero = CanonFloat{};
    pub const one = fromF32(f32, 1.0);
    pub const inf = fromF32(math.inf(f32));
    pub const neg_one = fromF32(-1.0);
    pub const neg_inf = fromF32(-math.inf(f32));

    pub fn fromF32(f: f32) CanonFloat {
        debug.assert(!math.isNan(f));

        if (f == 0.0) return .zero;

        return @bitCast(f);
    }

    pub fn toF32(self: CanonFloat) f32 {
        return @bitCast(self);
    }
};

pub const Filter = enum(u2) {
    nearest,
    linear,
    cubic,

    pub fn fromVk(f: vk.Filter) Filter {
        return switch (f) {
            _ => |u| debug.panic("unsupported vulkan value: {s}", .{@tagName(u)}),
            inline else => |comptime_tag| if (@hasField(Filter, @tagName(comptime_tag)))
                @field(vk.Filter, @tagName(comptime_tag))
            else
                @compileError("unsupported vulkan value: vk.Filter." ++ @tagName(comptime_tag)),
        };
    }

    pub fn toVk(self: Filter) vk.Filter {
        return switch (self) {
            inline else => |comptime_tag| return if (@hasField(vk.Filter, @tagName(comptime_tag))) @field(vk.Filter, @tagName(comptime_tag)) else @field(vk.Filter, @tagName(comptime_tag) ++ "_ext"),
        };
    }
};

pub const MipmapMode = enum(u1) {
    nearest,
    linear,

    pub fn fromVk(f: vk.SamplerMipmapMode) MipmapMode {
        return switch (f) {
            _ => |u| debug.panic("unsupported vulkan value: {s}", .{@tagName(u)}),
            inline else => |comptime_tag| if (@hasField(MipmapMode, @tagName(comptime_tag)))
                @field(vk.SamplerMipmapMode, @tagName(comptime_tag))
            else
                @compileError("unsupported vulkan value: vk.SamplerMipmapMode." ++ @tagName(comptime_tag)),
        };
    }

    pub fn toVk(self: MipmapMode) vk.SamplerMipmapMode {
        return switch (self) {
            inline else => |comptime_tag| return @field(vk.SamplerMipmapMode, @tagName(comptime_tag)),
        };
    }
};

pub const AddressMode = enum(u3) {
    repeat,
    mirrored_repeat,
    clamp_to_edge,
    clamp_to_border,
    mirror_clamp_to_edge,

    pub fn fromVk(f: vk.SamplerAddressMode) AddressMode {
        return switch (f) {
            _ => |u| debug.panic("unsupported vulkan value: {s}", .{@tagName(u)}),
            inline else => |comptime_tag| if (@hasField(AddressMode, @tagName(comptime_tag)))
                @field(vk.SamplerAddressMode, @tagName(comptime_tag))
            else
                @compileError("unsupported vulkan value: vk.SamplerAddressMode." ++ @tagName(comptime_tag)),
        };
    }

    pub fn toVk(self: AddressMode) vk.SamplerAddressMode {
        return switch (self) {
            inline else => |comptime_tag| return @field(vk.SamplerAddressMode, @tagName(comptime_tag)),
        };
    }
};

pub const CompareOp = enum(u4) {
    none,
    never,
    less,
    equal,
    less_or_equal,
    greater,
    not_equal,
    greater_or_equal,
    always,

    pub fn fromVk(f: vk.CompareOp) CompareOp {
        return switch (f) {
            _ => |u| debug.panic("unsupported vulkan value: {s}", .{@tagName(u)}),
            inline else => |comptime_tag| if (@hasField(CompareOp, @tagName(comptime_tag)))
                @field(vk.CompareOp, @tagName(comptime_tag))
            else
                @compileError("unsupported vulkan value: vk.CompareOp." ++ @tagName(comptime_tag)),
        };
    }

    pub fn toVk(self: CompareOp) ?vk.CompareOp {
        return switch (self) {
            .none => null,
            inline else => |comptime_tag| return @field(vk.CompareOp, @tagName(comptime_tag)),
        };
    }
};

pub const BorderColor = enum(u3) {
    float_transparent_black,
    int_transparent_black,
    float_opaque_black,
    int_opaque_black,
    float_opaque_white,
    int_opaque_white,

    // TODO: support custom color ext?

    pub fn fromVk(f: vk.BorderColor) ?BorderColor {
        return switch (f) {
            .float_custom_ext, .int_custom_ext, _ => |u| {
                debug.panic("unsupported vulkan value: {s}", .{@tagName(u)});
            },
            inline else => |comptime_tag| if (@hasField(BorderColor, @tagName(comptime_tag)))
                @field(vk.BorderColor, @tagName(comptime_tag))
            else
                @compileError("unsupported vulkan value: vk.BorderColor." ++ @tagName(comptime_tag)),
        };
    }

    pub fn toVk(self: BorderColor) vk.BorderColor {
        return switch (self) {
            inline else => |comptime_tag| return @field(vk.BorderColor, @tagName(comptime_tag)),
        };
    }
};

test Gpu {
    const instance = try Instance.init(
        true,
        "gpu headless test",
        @import("static_config").engine_version,
        &.{},
    );
    defer instance.deinit();

    const device = try Device.init(instance, null);
    defer device.deinit();

    const gpu = try init(device);
    defer gpu.deinit();

    const linear = try Sampler.linear(gpu);
    const nearest = try Sampler.nearest(gpu);

    try testing.expectEqual(Sampler{ .storage_index = 0 }, linear);
    try testing.expectEqual(Sampler{ .storage_index = 1 }, nearest);

    const image_0 = try Image.init(gpu, 1024, 1024);
    image_0.deinit(gpu);

    // leave this to be freed by the system at the end
    const image_1 = try Image.initAdvanced(
        gpu,
        1024,
        1024,
        .r12x4_unorm_pack16,
        .{
            .transfer_dst_bit = true,
            .sampled_bit = true,
            .color_attachment_bit = true,
        },
        .{ .device_local_bit = true },
    );

    try testing.expectEqual(Image{ .generation = 0, .storage_index = 0 }, image_0);
    try testing.expectEqual(Image{ .generation = 1, .storage_index = 0 }, image_1);

    const buffer_0 = try Buffer.init(gpu, 1024);
    buffer_0.deinit(gpu);

    // leave this to be freed by the system at the end
    const buffer_1 = try Buffer.init(gpu, 1024);

    try testing.expectEqual(Buffer{ .generation = 0, .storage_index = 2 }, buffer_0);
    try testing.expectEqual(Buffer{ .generation = 1, .storage_index = 2 }, buffer_1);

    var staging = try StagingBuffer.init(gpu, 1024);
    defer staging.deinit(gpu);

    _ = try staging.push(&.{ 1, 2, 3, 4 });
}

pub const Surface = vk.SurfaceKHR;
pub const DeviceAddress = vk.DeviceAddress;
pub const PushConstantRange = vk.PushConstantRange;
pub const ImageView = vk.ImageView;

pub const vk = @import("vulkan.zig");
pub const vma = @import("vma.zig");

const linalg = @import("linalg.zig");
const frame = @import("frame.zig");
const Window = @import("Window.zig");
const vec2u = linalg.vec2u;
const base = @import("base.zig");
const mem = base.mem;
const math = base.math;
const meta = base.meta;
const debug = base.debug;
const testing = base.testing;
const log = base.log.scoped(.gpu);
const assert_norecover = base.assert_norecover;
const norecover = base.norecover;
const sentinel = base.sentinel;
const isSentinel = base.isSentinel;
const Io = base.Io;
const Alignment = base.Alignment;

test {
    _ = vk;
    _ = vma;
    _ = Buffer;
    _ = Image;
    _ = Sampler;
}
