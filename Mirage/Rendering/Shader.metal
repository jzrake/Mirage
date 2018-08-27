#include <metal_stdlib>
#include <simd/simd.h>
#import "Shader.h"
using namespace metal;




// ===========================================================================
typedef struct
{
    float4 position [[position]];
    float4 color;
} RasterizerData;




// ===========================================================================
vertex RasterizerData
vertexShader(uint                   vertexID   [[ vertex_id                        ]],
             constant float4       *vertices   [[ buffer(VertexInputVertices)      ]],
             constant float4x4      &model     [[ buffer(VertexInputModelMatrix)   ]],
             constant float4x4      &view      [[ buffer(VertexInputViewMatrix)    ]],
             constant float4x4      &proj      [[ buffer(VertexInputProjMatrix)    ]])
{
    RasterizerData out;
    float4 pos = float4(vertices[vertexID].xyz, 1);
    out.position = proj * view * model * pos;
    out.color = float4(1, 0, 0, 1);
    return out;
}




// ===========================================================================
fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}
