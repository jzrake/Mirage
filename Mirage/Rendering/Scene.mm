#include "Scene.h"




// ============================================================================
Node::Node()
{
    textureW = 1;
    textureH = 1;
    texture.resize(4, 0);
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

id<MTLTexture> Node::makeTexture (id<MTLDevice> device) const
{
    MTLTextureDescriptor* d = [[MTLTextureDescriptor alloc] init];
    [d setUsage:MTLTextureUsageShaderRead];
    [d setWidth:textureW];
    [d setHeight:textureH];
    [d setPixelFormat:MTLPixelFormatRGBA8Unorm];
    MTLRegion region;
    region.origin.x = 0;
    region.origin.y = 0;
    region.origin.z = 0;
    region.size.width = textureW;
    region.size.height = textureH;
    region.size.depth = 1;
    id<MTLTexture> t = [device newTextureWithDescriptor:d];
    [t replaceRegion:region mipmapLevel:0 withBytes:texture.data() bytesPerRow:textureW * 4 * sizeof (uint8)];
    return t;
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

void Node::setTexture(const std::vector<unsigned char> &data, const std::vector<int> shape)
{
    if (shape.size() != 3 || shape[2] != 4)
    {
        throw std::invalid_argument("node.texture data must have shape [W, H, 4]");
    }
    if (shape[0] <= 1 || shape[1] <= 1)
    {
        throw std::invalid_argument("node.texture must have width and height greater than 1");
    }
    texture = data;
    textureW = shape[0];
    textureH = shape[1];
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
+ (id<MTLTexture>) nodeTexture: (struct Node*) node forDevice: (id<MTLDevice>) device { return node->makeTexture (device); }
+ (int) nodeTextureW: (struct Node*) node { return node->textureW; }
+ (int) nodeTextureH: (struct Node*) node { return node->textureH; }
+ (bool) nodeHasTexture: (struct Node*) node { return node->textureW > 1 && node->textureH > 1; }
+ (size_t) nodeNumVertices: (struct Node*) node { return node->numVertices(); }
+ (MTLPrimitiveType) nodeType: (struct Node*) node { return node->type; }
+ (NSString*) nodeValidate: (struct Node*) node { return [[NSString alloc] initWithUTF8String:node->validate().data()]; }

@end
