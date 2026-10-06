const Device = @This();

instance: *Gpu.Instance,
pdev: vk.PhysicalDevice,
props: vk.PhysicalDeviceProperties,
wrapper: vk.DeviceWrapper,
proxy: vk.DeviceProxy,
mem_props: vk.PhysicalDeviceMemoryProperties,
vulkan11_props: vk.PhysicalDeviceVulkan11Properties,
indexing_props: vk.PhysicalDeviceDescriptorIndexingProperties,
graphics_queue: Gpu.Queue,
present: ?struct {
    surface: Gpu.Surface,
    queue: Gpu.Queue,
},

pub fn init(instance: *Gpu.Instance, surface: ?Gpu.Surface) !*Device {
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

    self.graphics_queue = Gpu.Queue.init(self.proxy, candidate.queues.graphics_family);
    if (candidate.queues.present_family) |fam|
        self.present.?.queue = Gpu.Queue.init(self.proxy, fam);

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

const base = @import("../base.zig");
const vk = @import("../vulkan.zig");
const vma = @import("../vma.zig");
const Gpu = @import("../Gpu.zig");

const mem = base.mem;
const math = base.math;
const meta = base.meta;
const debug = base.debug;

const log = base.log.scoped(.Gpu);
