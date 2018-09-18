#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "Scene.h"




// ============================================================================
@interface PythonRuntime : NSObject
+ (void) initializeInterpreter;
+ (void) finalizeInterpreter;
+ (void) addToSystemPath: (NSURL*) directory;
+ (bool) evalFile: (NSURL*) filename;
+ (bool) evalString: (NSString*) expression;
+ (bool) execString: (NSString*) expression;
+ (int) numberOfScenes;
+ (struct Scene*) scene: (int) atIndex;
+ (struct Scene*) currentScene;
+ (void) setCurrentSceneIndex: (int) index;
+ (void) passDictionary: (NSDictionary*) dict;
+ (NSArray<UserControl*>*) getUserControls;
@end
