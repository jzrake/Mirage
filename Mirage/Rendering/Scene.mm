#include "Scene.h"
#include <Cocoa/Cocoa.h>
#include <Metal/Metal.h>




// ============================================================================
Node::Node()
{
}

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

id<MTLBuffer> Node::vertexBuffer(id<MTLDevice> device) const
{
    return [device newBufferWithBytes:&vertices[0]
                               length:vertices.size() * sizeof (float)
                              options:MTLResourceStorageModeShared];
}

id<MTLBuffer> Node::colorBuffer(id<MTLDevice> device) const
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

void Node::setType(std::string typeString)
{
    if (false) {}
    else if (typeString == "point")          type = MTLPrimitiveTypePoint;
    else if (typeString == "line")           type = MTLPrimitiveTypeLine;
    else if (typeString == "line strip")     type = MTLPrimitiveTypeLineStrip;
    else if (typeString == "triangle")       type = MTLPrimitiveTypeTriangle;
    else if (typeString == "triangle strip") type = MTLPrimitiveTypeTriangleStrip;
    else throw std::invalid_argument ("Node: invalid primitive type string '" + typeString + "'");
}

void Node::setImageTexture(NSBitmapImageRep* image)
{
    imageTexture = image;
}




// ============================================================================
Scene::Scene() : name ("Scene")
{
}

Scene::Scene(std::string name) : name(name)
{
}




// ============================================================================
@implementation SceneAPI

+ (int) numNodes: (struct Scene*) scene { return int(scene->nodes.size()); }
+ (struct Node*) node: (struct Scene*) scene atIndex: (int) i { return i >=0 && i < scene->nodes.size() ? &scene->nodes[i] : nil; }
+ (NSString*) name: (struct Scene*) scene { return [[NSString alloc] initWithUTF8String:scene->name.data()]; }
+ (float) nodePositionX: (struct Node*) node { return node->x; }
+ (float) nodePositionY: (struct Node*) node { return node->y; }
+ (float) nodePositionZ: (struct Node*) node { return node->z; }
+ (id<MTLBuffer>) nodeVertices: (struct Node*) node forDevice: (id<MTLDevice>) device { return node->vertexBuffer (device); }
+ (id<MTLBuffer>) nodeColors: (struct Node*) node forDevice: (id<MTLDevice>) device { return node->colorBuffer (device); }
+ (NSBitmapImageRep*) nodeImageTexture: (struct Node*) node { return node->imageTexture; }
+ (size_t) nodeNumVertices: (struct Node*) node { return node->numVertices(); }
+ (MTLPrimitiveType) nodeType: (struct Node*) node { return node->type; }
+ (NSString*) nodeValidate: (struct Node*) node { return [[NSString alloc] initWithUTF8String:node->validate().data()]; }

@end
