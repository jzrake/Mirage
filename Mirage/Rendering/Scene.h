#ifndef Scene_hpp
#define Scene_hpp
#include <Cocoa/Cocoa.h>
#include "UserParameter.h"

#ifdef __cplusplus
#include <Metal/Metal.h>
#include <vector>
#include <array>
#include <string>




// ============================================================================
class Image
{
public:
    Image (NSBitmapImageRep* image) : image (image) {}
    int getWidth() const { return int(image.pixelsWide); }
    int getHeight() const { return int(image.pixelsHigh); }
    NSBitmapImageRep* image;
};




// ============================================================================
struct UserParameterCpp
{
    UserParameterCpp();
    ~UserParameterCpp();
    void setName(std::string name);
    void setControl(std::string control);
    void setDoubleValue(double value);
    void setStringValue(std::string value);
    UserParameter* objc;
};




// ============================================================================
struct Node
{
    Node();

    std::string validate() const;
    std::string getType() const;
    bool hasNormals() const;
    size_t numVertices() const;
    size_t numPrimitives() const;

    Node withVertices(const float* data, size_t size) const;
    Node withColors(const float* data, size_t size) const;
    Node withImageTexture(const Image& imageTextureToUse) const;
    Node withPosition(std::array<float, 3> position) const;
    Node withRotation(std::array<float, 4> rotation) const;
    Node withType(std::string typeString) const;

    void setVertices(const float* data, size_t size);
    void setColors(const float* data, size_t size);
    void setImageTexture(const Image& imageTextureToUse);
    void setPosition (std::array<float, 3> position);
    void setRotation (std::array<float, 4> rotation);
    void setType(std::string typeString);

    // ========================================================================
    id<MTLDevice> device;
    id<MTLBuffer> vertexBuffer;
    id<MTLBuffer> normalBuffer;
    id<MTLBuffer> colorsBuffer;
    MTLPrimitiveType type = MTLPrimitiveTypeTriangle;

    NSBitmapImageRep* imageTexture = nil;
    size_t vertexArraySize = 0;
    size_t normalArraySize = 0;
    size_t colorsArraySize = 0;

    float x = 0.f;
    float y = 0.f;
    float z = 0.f;

    float ex = 0.f;
    float ey = 0.f;
    float ez = 1.f;
    float et = 0.f;

    // ========================================================================
    static std::vector<float> computeTriangleNormals(const float* vertices, size_t size);
};




// ============================================================================
struct Scene
{
    Scene();
    Scene(std::string name);
    NSArray<UserParameter*>* getUserParameters() const;
    std::string name;
    std::vector<Node> nodes;
    std::vector<UserParameterCpp> parameters;
};
#endif // __cplusplus




// ============================================================================
struct Node;
struct Scene;




// ============================================================================
@interface SceneAPI : NSObject

+ (int) numNodes: (struct Scene*) scene;
+ (struct Node*) node: (struct Scene*) scene atIndex: (int) index;
+ (NSString*) name: (struct Scene*) scene;
+ (NSArray<UserParameter*>*) userParameters: (struct Scene*) scene;
+ (float) nodePositionX: (struct Node*) node;
+ (float) nodePositionY: (struct Node*) node;
+ (float) nodePositionZ: (struct Node*) node;
+ (float) nodeRotationVectorX: (struct Node*) node;
+ (float) nodeRotationVectorY: (struct Node*) node;
+ (float) nodeRotationVectorZ: (struct Node*) node;
+ (float) nodeRotationVectorT: (struct Node*) node;
+ (id<MTLBuffer>) nodeVertices: (struct Node*) node;
+ (id<MTLBuffer>) nodeColors: (struct Node*) node;
+ (id<MTLBuffer>) nodeNormals: (struct Node*) node;
+ (bool) nodeHasNormals: (struct Node*) node;
+ (NSBitmapImageRep*) nodeImageTexture: (struct Node*) node;
+ (size_t) nodeNumVertices: (struct Node*) node;
+ (MTLPrimitiveType) nodeType: (struct Node*) node;
+ (NSString*) nodeValidate: (struct Node*) node;

@end

#endif // Scene_hpp
