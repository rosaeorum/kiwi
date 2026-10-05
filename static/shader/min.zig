const std = @import("std");

const is_fragment: bool = @import("config").is_fragment;

const VaryingSpace: std.builtin.AddressSpace = if (is_fragment) .input else .output;

fn VaryingPtr(comptime T: type) type {
    return if (is_fragment)
        *addrspace(VaryingSpace) const T
    else
        *addrspace(VaryingSpace) T;
}

const Vertex = extern struct {
    pos: [2]f32,
    uv: [2]f32,
    color: [3]f32,
    img: u32,
    samp: u32,
};

const DynamicData = extern struct {
    offset: [2]f32,
    time: f32,
};

const VertexRuntimeArray = @SpirvType(.{ .runtime_array = Vertex });

const VertexBuffer = extern struct {
    vertices: VertexRuntimeArray,
};

const VertexBufferPtr = *addrspace(.physical_storage_buffer) const VertexBuffer;
const DynamicDataPtr = *addrspace(.physical_storage_buffer) const DynamicData;

const PushConstants = extern struct {
    vbo: VertexBufferPtr,
    dyn_data: DynamicDataPtr,
};

const ImageType = @SpirvType(.{ .image = .{
    .usage = .{ .sampled = f32 },
    .format = .unknown,
    .dim = .@"2d",
    .depth = .unknown,
    .access = .unknown,
    .arrayed = false,
    .multisampled = false,
} });
const SamplerType = @SpirvType(.sampler);
const SampledImageType = @SpirvType(.{ .sampled_image = ImageType });

const ImageRuntimeArray = @SpirvType(.{ .runtime_array = ImageType });
const SamplerRuntimeArray = @SpirvType(.{ .runtime_array = SamplerType });

const ImageElementPtr = *addrspace(.constant) const ImageType;
const SamplerElementPtr = *addrspace(.constant) const SamplerType;

const pc = @extern(*addrspace(.push_constant) const PushConstants, .{ .name = "pc" });

const global_images = @extern(*addrspace(.constant) const ImageRuntimeArray, .{
    .name = "global_images",
    .decoration = .{ .descriptor = .{ .set = 0, .binding = 0 } },
});
const global_samplers = @extern(*addrspace(.constant) const SamplerRuntimeArray, .{
    .name = "global_samplers",
    .decoration = .{ .descriptor = .{ .set = 0, .binding = 1 } },
});

const vertex_index = @extern(*addrspace(.input) const u32, .{ .name = "vertex_index" });
const position = @extern(*addrspace(.output) @Vector(4, f32), .{ .name = "position" });

const fragColor = @extern(VaryingPtr(@Vector(3, f32)), .{
    .name = "fragColor",
    .decoration = .{ .location = 0 },
});
const fragUV = @extern(VaryingPtr(@Vector(2, f32)), .{
    .name = "fragUV",
    .decoration = .{ .location = 1 },
});
const fragImg = @extern(VaryingPtr(u32), .{
    .name = "fragImg",
    .decoration = .{ .flat = 2 },
});
const fragSamp = @extern(VaryingPtr(u32), .{
    .name = "fragSamp",
    .decoration = .{ .flat = 3 },
});

const outColor = @extern(*addrspace(.output) @Vector(4, f32), .{
    .name = "outColor",
    .decoration = .{ .location = 0 },
});

fn combineAndSample(
    images: *addrspace(.constant) const ImageRuntimeArray,
    samplers: *addrspace(.constant) const SamplerRuntimeArray,
    img_index: u32,
    samp_index: u32,
    uv: @Vector(2, f32),
) @Vector(4, f32) {
    return asm volatile (
        \\%img_ptr = OpAccessChain %ImageElementPtr %images %img_index
        \\%img = OpLoad %ImageType %img_ptr
        \\%samp_ptr = OpAccessChain %SamplerElementPtr %samplers %samp_index
        \\%samp = OpLoad %SamplerType %samp_ptr
        \\%combined = OpSampledImage %SampledImageType %img %samp
        \\%ret = OpImageSampleImplicitLod %Result %combined %uv
        : [ret] "" (-> @Vector(4, f32)),
        : [ImageElementPtr] "t" (ImageElementPtr),
          [images] "" (images),
          [img_index] "" (img_index),
          [ImageType] "t" (ImageType),
          [SamplerElementPtr] "t" (SamplerElementPtr),
          [samplers] "" (samplers),
          [samp_index] "" (samp_index),
          [SamplerType] "t" (SamplerType),
          [SampledImageType] "t" (SampledImageType),
          [Result] "t" (@Vector(4, f32)),
          [uv] "" (uv),
    );
}

fn vec2(a: [2]f32) @Vector(2, f32) {
    return @Vector(2, f32){ a[0], a[1] };
}
fn vec3(a: [3]f32) @Vector(3, f32) {
    return @Vector(3, f32){ a[0], a[1], a[2] };
}

fn vertexMain() callconv(.spirv_vertex) void {
    const v = pc.vbo.vertices[vertex_index.*];

    const pos = vec2(v.pos);
    const color = vec3(v.color);

    const scale = 1.0 + @sin(pc.dyn_data.time) * 0.2;
    const offset = vec2(pc.dyn_data.offset);
    const animated_pos = (pos * @as(@Vector(2, f32), @splat(scale))) + offset;

    position.* = .{ animated_pos[0], animated_pos[1], 0.0, 1.0 };

    fragColor.* = color;
    fragUV.* = vec2(v.uv);
    fragImg.* = v.img;
    fragSamp.* = v.samp;
}

fn fragmentMain() callconv(.{ .spirv_fragment = .{} }) void {
    const texColor = combineAndSample(
        global_images,
        global_samplers,
        fragImg.*,
        fragSamp.*,
        fragUV.*,
    );

    const finalRGB = @Vector(3, f32){
        texColor[0] * fragColor.*[0] * texColor[3],
        texColor[1] * fragColor.*[1] * texColor[3],
        texColor[2] * fragColor.*[2] * texColor[3],
    };

    outColor.* = .{ finalRGB[0], finalRGB[1], finalRGB[2], texColor[3] };
}

comptime {
    if (is_fragment) {
        @export(&fragmentMain, .{
            .name = "main",
            .linkage = .strong,
        });
    } else {
        @export(&vertexMain, .{
            .name = "main",
            .linkage = .strong,
        });
    }
}
