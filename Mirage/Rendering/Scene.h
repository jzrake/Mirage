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

    std::array<float, 3> getPosition() const;

    void setPosition (std::array<float, 3> position);

    std::string getType() const;

    void setType (std::string typeString);

    /** Assign texture data to the node. Shape must be [W, H, 4] with RGBA data on the
        last axis.
     */
    void setTexture (const std::vector<unsigned char>& data, const std::vector<int> shape);

    void setTexture (NSBitmapImageRep* image);

    /** Return the number of vertices in this node.
     */
    size_t numVertices() const;

    /** Return the number of primitives in this node. Depends on the primitive type
        and the number of vertices.
     */
    size_t numPrimitives() const;

    /** Return a buffer of the vertex data. Do not call this function unless you're
        sure the node is valid.
     */
    id<MTLBuffer> vertexBuffer (id<MTLDevice> device) const;

    /** Return a buffer of the color data. Do not call this function unless you're
        sure the node is valid.
     */
    id<MTLBuffer> colorBuffer (id<MTLDevice> device) const;

    /** Returns a buffer of texture data, if there is any.
     */
    id<MTLTexture> makeTexture (id<MTLDevice> device) const;

    // ========================================================================
    MTLPrimitiveType type = MTLPrimitiveTypeTriangle;
    
    std::vector<float> vertices;
    std::vector<float> colors;
    NSBitmapImageRep* image;
    //std::vector<unsigned char> texture;
    //int textureW = 0;
    //int textureH = 0;
    
    float x = 0.f;
    float y = 0.f;
    float z = 0.f;
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
+ (id<MTLBuffer>) nodeVertices: (struct Node*) node forDevice: (id<MTLDevice>) device;
+ (id<MTLBuffer>) nodeColors: (struct Node*) node forDevice: (id<MTLDevice>) device;
+ (id<MTLTexture>) nodeTexture: (struct Node*) node forDevice: (id<MTLDevice>) device;
+ (NSInteger) nodeTextureW: (struct Node*) node;
+ (NSInteger) nodeTextureH: (struct Node*) node;
+ (bool) nodeHasTexture: (struct Node*) node;
+ (NSBitmapImageRep*) nodeTextureImage: (struct Node*) node;
+ (size_t) nodeNumVertices: (struct Node*) node;
+ (MTLPrimitiveType) nodeType: (struct Node*) node;
+ (NSString*) nodeValidate: (struct Node*) node;

@end

#endif // Scene_hpp
