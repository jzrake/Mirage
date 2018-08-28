#ifndef Scene_hpp
#define Scene_hpp




#ifdef __cplusplus
#include <Metal/Metal.h>
#include <vector>
#include <array>
#include <string>




// ============================================================================
struct Node
{
    MTLPrimitiveType type = MTLPrimitiveTypeTriangle;

    std::vector<float> vertices;
    std::vector<float> colors;
    float x = 0.f;
    float y = 0.f;
    float z = 0.f;

    /** Return an empty string if this node has valid vertex data. Otherwise, return
     an error message describing the problem.
     */
    std::string validate() const;

    std::array<float, 3> getPosition() const;

    void setPosition (std::array<float, 3> position);

    std::string getType() const;

    void setType (std::string typeString);

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
};




// ============================================================================
struct Scene
{
    Scene();
    Scene(std::string name);

    void encode (id<MTLRenderCommandEncoder> encoder, float W, float H, float rot, float zcam);

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

+ (void) encode: (struct Scene*) scene
        encoder: (id<MTLRenderCommandEncoder>) encoder
          width: (float) width
         height: (float) height
            rot: (float) rot
           zcam: (float) zcam;

+ (int) numNodes: (struct Scene*) scene;
//+ (struct Node*) node: (struct Scene*) scene atIndex: (int) index;
+ (NSString*) name: (struct Scene*) scene;

@end

#endif // Scene_hpp
