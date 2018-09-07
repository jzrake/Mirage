#include <metal_stdlib>
#include <simd/simd.h>
#import "Shader.h"
using namespace metal;




// ============================================================================
typedef struct
{
    float4 position [[position]];
    float4 normal;
    float4 color;
} RasterizerData;




// ============================================================================
vertex RasterizerData
vertexShader(uint                   vertexID   [[ vertex_id                        ]],
             device float4         *vertices   [[ buffer(VertexInputVertices)      ]],
             device float4         *normals    [[ buffer(VertexInputNormals)       ]],
             device float4         *colors     [[ buffer(VertexInputColors)        ]],
             constant float4x4      &model     [[ buffer(VertexInputModelMatrix)   ]],
             constant float4x4      &view      [[ buffer(VertexInputViewMatrix)    ]],
             constant float4x4      &proj      [[ buffer(VertexInputProjMatrix)    ]],
             constant ShaderOptions &options   [[ buffer(VertexInputOptions)       ]])
{
    RasterizerData out;
    float4 pos = float4(vertices[vertexID].xyz, 1);
    out.position = proj * view * model * pos;
    out.normal = options.hasNormals ? normalize(view * model * normals[vertexID]) : float4(1, 1, 1, 1);
    out.color = colors[vertexID];
    return out;
}




// ============================================================================
constexpr sampler textureSampler (mag_filter::linear,
                                  min_filter::linear);




// ============================================================================
fragment float4 fragmentShader(RasterizerData            in       [[ stage_in ]],
                               constant ShaderOptions    &options [[ buffer(FragmentInputOptions) ]],
                               texture2d<float>          texture  [[ texture(FragmentInputTexture2D) ]])
{
    if (! options.isTextureActive)
    {
        return float4(in.color.rgb * (0.3 + 0.7 * in.normal.z), in.color.a);
    }
    else
    {
        return texture.sample(textureSampler, in.color.xy);
    }
}
