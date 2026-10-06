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
    buffer: *buffer.Store,
    sampler: *sampler.Store,
    image: *image.Store,
},

pub fn init(device: *Device) !*Gpu {
    const self = try base.gpa.create(Gpu);
    errdefer base.gpa.destroy(self);

    self.device = device;

    self.max_samplers = @min(
        sampler.Store.max_capacity,
        self.device.indexing_props.max_per_stage_descriptor_update_after_bind_samplers,
        self.device.indexing_props.max_descriptor_set_update_after_bind_samplers,
    );

    self.max_images = @min(
        image.Store.max_capacity,
        self.device.indexing_props.max_per_stage_descriptor_update_after_bind_sampled_images,
        self.device.indexing_props.max_descriptor_set_update_after_bind_sampled_images,
    );

    const global_limit = self.device.indexing_props.max_update_after_bind_descriptors_in_all_pools;

    while (self.max_samplers + self.max_images > global_limit) {
        self.max_images = @divFloor(self.max_images, 2);
    }

    self.descriptor_pool = try self.device.proxy.createDescriptorPool(
        &vk.DescriptorPoolCreateInfo{
            .flags = .{ .update_after_bind = true },
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
            .flags = .{ .update_after_bind_pool = true },
            .binding_count = 2,
            .p_bindings = &[_]vk.DescriptorSetLayoutBinding{
                .{
                    .binding = 0,
                    .descriptor_type = .sampled_image,
                    .descriptor_count = self.max_images,
                    .stage_flags = .{ .fragment = true },
                    .p_immutable_samplers = null,
                },
                .{
                    .binding = 1,
                    .descriptor_type = .sampler,
                    .descriptor_count = self.max_samplers,
                    .stage_flags = .{ .fragment = true },
                    .p_immutable_samplers = null,
                },
            },
            .p_next = &vk.DescriptorSetLayoutBindingFlagsCreateInfo{
                .binding_count = 2,
                .p_binding_flags = &[_]vk.DescriptorBindingFlags{
                    .{
                        .partially_bound = true,
                        .update_after_bind = true,
                    },
                    .{
                        .partially_bound = true,
                        .update_after_bind = true,
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
            .flags = .{ .reset_command_buffer = true },
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

    self.store.buffer = try buffer.Store.init(self);
    errdefer self.store.buffer.deinit();

    self.store.sampler = try sampler.Store.init(self);
    errdefer self.store.sampler.deinit();

    self.store.image = try image.Store.init(self);
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

pub const Instance = @import("Gpu/Instance.zig");

pub const Device = @import("Gpu/Device.zig");

pub const buffer = @import("Gpu/buffer.zig");
pub const Buffer = buffer.Buffer;

pub const image = @import("Gpu/image.zig");
pub const Image = image.Image;

pub const sampler = @import("Gpu/sampler.zig");
pub const Sampler = sampler.Sampler;

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
                .{ .shader_device_address = true }, // We need the GPU address!
                .{ .host_visible = true, .host_coherent = true },
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

pub const StagingBuffer = @import("Gpu/StagingBuffer.zig");

pub const SwapChain = @import("Gpu/SwapChain.zig");

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

pub const Pipeline = @import("Gpu/Pipeline.zig");

pub const CommandBuffer = @import("Gpu/CommandBuffer.zig");

pub const Spirv = []const u32;

pub const SampleCount = enum(u32) {
    @"1",
    @"2",
    @"4",
    @"8",
    @"16",

    pub fn toVk(self: SampleCount) vk.SampleCountFlags {
        return switch (self) {
            .@"1" => vk.SampleCountFlags{ .@"1" = true },
            .@"2" => vk.SampleCountFlags{ .@"2" = true },
            .@"4" => vk.SampleCountFlags{ .@"4" = true },
            .@"8" => vk.SampleCountFlags{ .@"8" = true },
            .@"16" => vk.SampleCountFlags{ .@"16" = true },
        };
    }

    pub fn fromVk(flags: vk.SampleCountFlags) SampleCount {
        if (flags.@"16") return .@"16";
        if (flags.@"8") return .@"8";
        if (flags.@"4") return .@"4";
        if (flags.@"2") return .@"2";
        if (flags.@"1") return .@"1";
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
