#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "Scene.h"




// ============================================================================
@interface PythonRuntime : NSObject
+ (void) initializeInterpreter;
+ (void) finalizeInterpreter;
+ (void) addToSystemPath: (NSURL*) directory;
+ (bool) evalFile: (NSURL*) filename;
+ (int) numberOfScenes;
+ (struct Scene*) scene: (int) atIndex;
@end
