#ifndef ShaderTypes_h
#define ShaderTypes_h
#include <simd/simd.h>


typedef enum VertexInputIndex
{
    VertexInputVertices          = 0,
    VertexInputNormals           = 1,
    VertexInputColors            = 2,
    VertexInputModelMatrix       = 3,
    VertexInputViewMatrix        = 4,
    VertexInputProjMatrix        = 5,
    VertexInputOptions           = 6,
} VertexInputIndex;


typedef enum FramgentInputIndex
{
    FragmentInputOptions         = 0,
    FragmentInputTexture2D       = 1,
} FramgentInputIndex;


typedef struct ShaderOptions
{
    bool isTextureActive;
    bool hasNormals;
} ShaderOptions;

#endif /* ShaderTypes_h */
