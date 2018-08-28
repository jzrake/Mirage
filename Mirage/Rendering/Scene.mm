#import <GLKit/GLKMath.h>
#import <simd/simd.h>
#include <iostream>
#include <Metal/Metal.h>
#include "Scene.hpp"
#include "Shader.h"




// ============================================================================
size_t Node::numVertices() const
{
    return vertices.size() / 4;
}

size_t Node::numPrimitives() const
{
    switch (type)
    {
        case MTLPrimitiveTypePoint         : return numVertices();
        case MTLPrimitiveTypeLine          : return numVertices() / 2;
        case MTLPrimitiveTypeLineStrip     : return numVertices() - 1;
        case MTLPrimitiveTypeTriangle      : return numVertices() / 3;
        case MTLPrimitiveTypeTriangleStrip : return numVertices() - 2;
    }
}

std::string Node::validate() const
{
    if (vertices.empty())
    {
        return "node has no vertices";
    }
    if (type == MTLPrimitiveTypeTriangle && vertices.size() % (4 * 3) != 0)
    {
        return "triangle node vertex data not divisible by (4 * 3)";
    }
    if (type == MTLPrimitiveTypeLine && vertices.size() % (4 * 2) != 0)
    {
        return "line node vertex data not divisible by (4 * 2)";
    }
    if (vertices.size() != colors.size())
    {
        return "color data did not have the same shape as vertex data";
    }
    return std::string();
}

id<MTLBuffer> Node::vertexBuffer (id<MTLDevice> device) const
{
    return [device newBufferWithBytes:&vertices[0]
                               length:vertices.size() * sizeof (float)
                              options:MTLResourceStorageModeShared];
}

id<MTLBuffer> Node::colorBuffer (id<MTLDevice> device) const
{
    return [device newBufferWithBytes:&colors[0]
                               length:colors.size() * sizeof (float)
                              options:MTLResourceStorageModeShared];
}

std::array<float, 3> Node::getPosition() const
{
    return { x, y, z };
}

void Node::setPosition(std::array<float, 3> position)
{
    x = position[0];
    y = position[1];
    z = position[2];
}

std::string Node::getType() const
{
    switch (type)
    {
        case MTLPrimitiveTypePoint         : return "point";
        case MTLPrimitiveTypeLine          : return "line";
        case MTLPrimitiveTypeLineStrip     : return "line strip";
        case MTLPrimitiveTypeTriangle      : return "triangle";
        case MTLPrimitiveTypeTriangleStrip : return "triangle strip";
    }
}

void Node::setType (std::string typeString)
{
    if (false) {}
    else if (typeString == "point")          type = MTLPrimitiveTypePoint;
    else if (typeString == "line")           type = MTLPrimitiveTypeLine;
    else if (typeString == "line strip")     type = MTLPrimitiveTypeLineStrip;
    else if (typeString == "triangle")       type = MTLPrimitiveTypeTriangle;
    else if (typeString == "triangle strip") type = MTLPrimitiveTypeTriangleStrip;
    else throw std::invalid_argument ("Node: invalid primitive type string '" + typeString + "'");
}




// ============================================================================
Scene::Scene() : name ("Scene")
{
}

Scene::Scene(std::string name) : name(name)
{
}

void Scene::encode (id<MTLRenderCommandEncoder> encoder, float W, float H, float rot, float zcam)
{
    for (const auto& node : nodes)
    {
        auto error = node.validate();

        if (! error.empty())
        {
            std::cout << "Warning: " << error << std::endl;
            continue;
        }

        GLKMatrix4 model = GLKMatrix4MakeTranslation (node.x, node.y, node.z);
        GLKMatrix4 view  = GLKMatrix4Rotate (GLKMatrix4MakeTranslation (0, 0, -zcam), rot, 0, 1, 0);
        GLKMatrix4 proj  = GLKMatrix4MakePerspective (1.f, W / H, 0.1f, 1024.f);

        id<MTLBuffer> vbuf = node.vertexBuffer (encoder.device);
        id<MTLBuffer> cbuf = node.colorBuffer (encoder.device);

        [encoder setVertexBuffer:vbuf offset:0 atIndex:VertexInputVertices];
        [encoder setVertexBuffer:cbuf offset:0 atIndex:VertexInputColors];
        [encoder setVertexBytes:&model length:sizeof (GLKMatrix4) atIndex:VertexInputModelMatrix];
        [encoder setVertexBytes:&view  length:sizeof (GLKMatrix4) atIndex:VertexInputViewMatrix];
        [encoder setVertexBytes:&proj  length:sizeof (GLKMatrix4) atIndex:VertexInputProjMatrix];
        [encoder drawPrimitives:node.type vertexStart:0 vertexCount:node.numVertices()];
    }
}




// ============================================================================
void scene_encode (struct Scene* scene, id<MTLRenderCommandEncoder> encoder, float W, float H, float rot, float zcam)
{
    scene->encode (encoder, W, H, rot, zcam);
}
