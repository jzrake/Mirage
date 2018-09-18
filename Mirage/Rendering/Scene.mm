#include "Scene.h"
#include <Cocoa/Cocoa.h>
#include <Metal/Metal.h>
#include <simd/simd.h>




// ============================================================================
UserParameterCpp::UserParameterCpp()
{
    objc = [[UserParameter alloc] init];
}

UserParameterCpp::~UserParameterCpp()
{
    objc = nil;
}

void UserParameterCpp::setName(std::string name)
{
    objc.name = [[NSString alloc] initWithUTF8String:name.data()];
}

void UserParameterCpp::setControl(std::string control)
{
    if (![objc setControlTypeName:[[NSString alloc] initWithUTF8String:control.data()]])
    {
        throw std::invalid_argument("unknown control name '" + control + "'");
    }
}

void UserParameterCpp::setDoubleValue(double value)
{
    objc.value = [[Variant alloc] initWithDouble:value];
}

void UserParameterCpp::setStringValue(std::string value)
{
    objc.value = [[Variant alloc] initWithString:[[NSString alloc] initWithUTF8String:value.data()]];
}




// ============================================================================
Node::Node()
{
    device = MTLCreateSystemDefaultDevice();
}

std::string Node::validate() const
{
    if (vertexArraySize == 0)
    {
        return "node has no vertices";
    }
    if (type == MTLPrimitiveTypeTriangle && vertexArraySize % (4 * 3) != 0)
    {
        return "triangle node vertex data not divisible by (4 * 3)";
    }
    if (type == MTLPrimitiveTypeLine && vertexArraySize % (4 * 2) != 0)
    {
        return "line node vertex data not divisible by (4 * 2)";
    }
    if (vertexArraySize != colorsArraySize)
    {
        return "color data did not have the same size as vertex data";
    }
    return std::string();
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

bool Node::hasNormals() const
{
    return type == MTLPrimitiveTypeTriangle;
}

size_t Node::numVertices() const
{
    return vertexArraySize / 4;
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

Node Node::withVertices(const float* data, size_t size) const
{
    auto n = *this;
    n.setVertices(data, size);
    return n;
}

Node Node::withColors(const float* data, size_t size) const
{
    auto n = *this;
    n.setColors(data, size);
    return n;
}

Node Node::withImageTexture(const Image& imageTextureToUse) const
{
    auto n = *this;
    n.setImageTexture(imageTextureToUse);
    return n;
}

Node Node::withPosition(std::array<float, 3> position) const
{
    auto n = *this;
    n.setPosition(position);
    return n;
}

Node Node::withRotation(std::array<float, 4> rotation) const
{
    auto n = *this;
    n.setRotation(rotation);
    return n;
}

Node Node::withType(std::string typeString) const
{
    auto n = *this;
    n.setType(typeString);
    return n;
}

void Node::setVertices(const float* data, size_t size)
{
    if (size == 0)
    {
        vertexBuffer = nil;
        normalBuffer = nil;
        vertexArraySize = 0;
        normalArraySize = 0;
    }
    else
    {
        auto normals = computeTriangleNormals(data, size);
        vertexBuffer = [device newBufferWithBytes:data length:size * sizeof(float) options:MTLResourceStorageModeManaged];
        normalBuffer = [device newBufferWithBytes:normals.data() length:normals.size() * sizeof(float) options:MTLResourceStorageModeManaged];
        vertexArraySize = size;
        normalArraySize = normals.size();
    }
}

void Node::setColors(const float* data, size_t size)
{
    if (size == 0)
    {
        colorsBuffer = nil;
        colorsArraySize = 0;
    }
    else
    {
        colorsBuffer = [device newBufferWithBytes:data length:size * sizeof(float) options:MTLResourceStorageModeManaged];
        colorsArraySize = size;
    }
}

void Node::setImageTexture(const Image& imageTextureToUse)
{
    imageTexture = imageTextureToUse.image;
}

void Node::setPosition (std::array<float, 3> position)
{
    x = position[0];
    y = position[1];
    z = position[2];
}

void Node::setRotation (std::array<float, 4> rotation)
{
    ex = rotation[0];
    ey = rotation[1];
    ez = rotation[2];
    et = rotation[3];
}

void Node::setType(std::string typeString)
{
    if (false) {}
    else if (typeString == "point")          type = MTLPrimitiveTypePoint;
    else if (typeString == "line")           type = MTLPrimitiveTypeLine;
    else if (typeString == "line strip")     type = MTLPrimitiveTypeLineStrip;
    else if (typeString == "triangle")       type = MTLPrimitiveTypeTriangle;
    else if (typeString == "triangle strip") type = MTLPrimitiveTypeTriangleStrip;
    else throw std::invalid_argument("Node: invalid primitive type string '" + typeString + "'");
}

std::vector<float> Node::computeTriangleNormals(const float* vertices, size_t size)
{
    if (size % 12 != 0)
        return {0, 0, 0, 0}; // return a single vector so the buffer is not empty

    std::vector<float> normals(size);

    for (size_t n = 0; n < size; n += 12)
    {
        auto a = simd_make_float3(vertices[n + 0], vertices[n + 1], vertices[n + 2]);
        auto b = simd_make_float3(vertices[n + 4], vertices[n + 5], vertices[n + 6]);
        auto c = simd_make_float3(vertices[n + 8], vertices[n + 9], vertices[n + 10]);
        auto N = simd_cross(b - a, c - b);
        normals[n + 0] = normals[n + 4] = normals[n + 8]  = N.x;
        normals[n + 1] = normals[n + 5] = normals[n + 9]  = N.y;
        normals[n + 2] = normals[n + 6] = normals[n + 10] = N.z;
        normals[n + 3] = normals[n + 7] = normals[n + 11] = 0.f;
    }
    return normals;
}




// ============================================================================
Scene::Scene() : name ("Scene")
{
}

Scene::Scene(std::string name) : name(name)
{
}

NSArray<UserParameter*>* Scene::getUserParameters() const
{
    NSMutableArray<UserParameter*>* params = [[NSMutableArray<UserParameter*> alloc] init];

    for (const auto& p : parameters)
    {
        [params addObject:p.objc];
    }
    return params;
}




// ============================================================================
@implementation SceneAPI

+ (int) numNodes: (struct Scene*) scene { return int(scene->nodes.size()); }
+ (struct Node*) node: (struct Scene*) scene atIndex: (int) i { return i >=0 && i < scene->nodes.size() ? &scene->nodes[i] : nil; }
+ (NSString*) name: (struct Scene*) scene { return [[NSString alloc] initWithUTF8String:scene->name.data()]; }
+ (NSArray<UserParameter*>*) userParameters: (struct Scene*) scene { return scene->getUserParameters(); }
+ (float) nodePositionX: (struct Node*) node { return node->x; }
+ (float) nodePositionY: (struct Node*) node { return node->y; }
+ (float) nodePositionZ: (struct Node*) node { return node->z; }
+ (float) nodeRotationVectorX: (struct Node*)  node { return node->ex; }
+ (float) nodeRotationVectorY: (struct Node*)  node { return node->ey; }
+ (float) nodeRotationVectorZ: (struct Node*)  node { return node->ez; }
+ (float) nodeRotationVectorT: (struct Node*)  node { return node->et; }
+ (id<MTLBuffer>) nodeVertices: (struct Node*) node { return node->vertexBuffer; }
+ (id<MTLBuffer>) nodeColors: (struct Node*)   node { return node->colorsBuffer; }
+ (id<MTLBuffer>) nodeNormals: (struct Node*)  node { return node->normalBuffer; }
+ (bool) nodeHasNormals: (struct Node*) node { return node->hasNormals(); }
+ (NSBitmapImageRep*) nodeImageTexture: (struct Node*) node { return node->imageTexture; }
+ (size_t) nodeNumVertices: (struct Node*) node { return node->numVertices(); }
+ (MTLPrimitiveType) nodeType: (struct Node*) node { return node->type; }
+ (NSString*) nodeValidate: (struct Node*) node { return [[NSString alloc] initWithUTF8String:node->validate().data()]; }

@end
