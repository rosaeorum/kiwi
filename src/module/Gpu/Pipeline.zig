const Pipeline = @This();

kind: Kind,
handle: vk.Pipeline,
layout: vk.PipelineLayout,
push_constants: []const Gpu.PushConstantRange,

pub const Kind = enum { @"2d", @"3d", compute };

pub fn graphics(
    gpu: *Gpu,
    vertex_mod: Gpu.ShaderModule,
    fragment_mod: Gpu.ShaderModule,
    dimensions: enum { @"2d", @"3d" },
    format: vk.Format,
    samples: Gpu.SampleCount,
    push_constants: []const Gpu.PushConstantRange,
) !Pipeline {
    var self: Pipeline = undefined;

    self.kind, const stencil_state = switch (dimensions) {
        .@"2d" => .{ .@"2d", &stencil_state_2d },
        .@"3d" => .{ .@"3d", &stencil_state_3d },
    };
    self.push_constants = try base.gpa.dupe(Gpu.PushConstantRange, push_constants);
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

                    .cull_mode = .{ .back = true },
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
                                .r = true,
                                .g = true,
                                .b = true,
                                .a = true,
                            },
                        },
                    },
                },

                .stage_count = 2,
                .p_stages = &[_]vk.PipelineShaderStageCreateInfo{
                    .{
                        .stage = .{ .vertex = true },
                        .module = vertex_mod.handle,
                        .p_name = "main",
                    },
                    .{
                        .stage = .{ .fragment = true },
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

const base = @import("../base.zig");
const vk = @import("../vulkan.zig");
const Gpu = @import("../Gpu.zig");
const log = base.log.scoped(.Gpu);
