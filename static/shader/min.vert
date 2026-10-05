#version 450
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require

struct Vertex {
    vec2 pos;
    vec2 uv;
    vec3 color;
    uint img;
    uint samp;
};

layout(buffer_reference, scalar) readonly buffer VertexBuffer {
    Vertex vertices[];
};

layout(buffer_reference, scalar) readonly buffer DynamicData {
    vec2 offset;
    float time;
};

layout(push_constant) uniform PushConstants {
    VertexBuffer vbo;
    DynamicData dyn_data;
} pc;

layout(location = 0) out vec3 fragColor;
layout(location = 1) out vec2 fragUV;
layout(location = 2) flat out uint fragImg;
layout(location = 3) flat out uint fragSamp;

void main() {
    Vertex v = pc.vbo.vertices[gl_VertexIndex];
    
    float scale = 1.0 + sin(pc.dyn_data.time) * 0.2;
    vec2 animated_pos = (v.pos * scale) + pc.dyn_data.offset;
    
    gl_Position = vec4(animated_pos, 0.0, 1.0);
    
    fragColor = v.color;
    fragUV = v.uv;
    fragImg = v.img;
    fragSamp = v.samp;
}