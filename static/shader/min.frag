#version 450
#extension GL_EXT_nonuniform_qualifier : require

layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec2 fragUV;
layout(location = 2) flat in uint fragImg;
layout(location = 3) flat in uint fragSamp;

layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 0) uniform texture2D global_images[];
layout(set = 0, binding = 1) uniform sampler global_samplers[];

void main() {
    vec4 texColor = texture(
        sampler2D(
            global_images[nonuniformEXT(fragImg)], 
            global_samplers[nonuniformEXT(fragSamp)]
        ), 
        fragUV
    );
    
    vec3 finalRGB = texColor.rgb * fragColor * texColor.a;
    outColor = vec4(finalRGB, texColor.a);
}