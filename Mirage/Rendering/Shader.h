#ifndef ShaderTypes_h
#define ShaderTypes_h
#include <simd/simd.h>


typedef enum VertexInputIndex
{
    VertexInputVertices          = 0,
    VertexInputColors            = 1,
    VertexInputModelMatrix       = 3,
    VertexInputViewMatrix        = 4,
    VertexInputProjMatrix        = 5,
} VertexInputIndex;


typedef enum FramgentInputIndex
{
    FragmentInputOptions         = 0,
    FragmentInputTexture2D       = 1,
} FramgentInputIndex;


typedef struct FragmentOptions
{
    bool isTextureActive;
} FragmentOptions;

#endif /* ShaderTypes_h */
