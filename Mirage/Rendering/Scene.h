#ifndef Scene_hpp
#define Scene_hpp



#include <Cocoa/Cocoa.h>

#ifdef __cplusplus
#include <Metal/Metal.h>
#include <vector>
#include <array>
#include <string>




// ============================================================================
struct Node
{
    Node();

    /** Return an empty string if this node has valid vertex data. Otherwise, return
        an error message describing the problem.
     */
    std::string validate() const;

    void setPosition (std::array<float, 3> position);
    void setRotation (std::array<float, 4> rotation);

    std::string getType() const;

    void setType (std::string typeString);

    /** Assign bitmap texture data to the node.
     */
    void setImageTexture (NSBitmapImageRep* image);

    /** Return the number of vertices in this node.
     */
    size_t numVertices() const;

    /** Return the number of primitives in this node. Depends on the primitive type
        and the number of vertices.
     */
    size_t numPrimitives() const;

    /** Return data, one float4 per vertex, describing normal vectors for triangles.
        Currently this method is only implemented for triangle primitives. For other
        types, it returns and empty vector.
     */
    std::vector<float> computeNormals() const;

    /** Return a buffer of the vertex data. Do not call this function unless you're
        sure the node is valid.
     */
    id<MTLBuffer> vertexBuffer (id<MTLDevice> device) const;

    /** Return a buffer of the color data. Do not call this function unless you're
        sure the node is valid.
     */
    id<MTLBuffer> colorBuffer (id<MTLDevice> device) const;

    // ========================================================================
    MTLPrimitiveType type = MTLPrimitiveTypeTriangle;
    
    std::vector<float> vertices;
    std::vector<float> colors;
    NSBitmapImageRep* imageTexture;

    float x = 0.f;
    float y = 0.f;
    float z = 0.f;

    float ex = 0.f;
    float ey = 0.f;
    float ez = 1.f;
    float et = 0.f;
};




// ============================================================================
struct Scene
{
    Scene();
    Scene(std::string name);
    std::string name;
    std::vector<Node> nodes;
    Node root;
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
+ (float) nodePositionX: (struct Node*) node;
+ (float) nodePositionY: (struct Node*) node;
+ (float) nodePositionZ: (struct Node*) node;
+ (float) nodeRotationVectorX: (struct Node*) node;
+ (float) nodeRotationVectorY: (struct Node*) node;
+ (float) nodeRotationVectorZ: (struct Node*) node;
+ (float) nodeRotationVectorT: (struct Node*) node;
+ (id<MTLBuffer>) nodeVertices: (struct Node*) node forDevice: (id<MTLDevice>) device;
+ (id<MTLBuffer>) nodeColors: (struct Node*) node forDevice: (id<MTLDevice>) device;
+ (NSBitmapImageRep*) nodeImageTexture: (struct Node*) node;
+ (size_t) nodeNumVertices: (struct Node*) node;
+ (MTLPrimitiveType) nodeType: (struct Node*) node;
+ (NSString*) nodeValidate: (struct Node*) node;

@end

#endif // Scene_hpp
