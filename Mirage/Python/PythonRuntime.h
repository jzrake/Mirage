#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "Scene.hpp"




// ============================================================================
@interface PythonRuntime : NSObject
+ (void) initializeInterpreter;
+ (void) finalizeInterpreter;
+ (bool) evalFile: (NSURL*) filename;

+ (int) numberOfScenes;
+ (NSString*) sceneName: (int) sceneIndex;

+ (struct Node*) rootNode: (int) sceneIndex;
+ (id<MTLBuffer>) nodeVertexData: (struct Node*) node;
+ (id<MTLBuffer>) nodeColorsData: (struct Node*) node;
@end
