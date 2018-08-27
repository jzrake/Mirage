#import <Foundation/Foundation.h>




// ============================================================================
@interface PythonRuntime : NSObject
+ (void) initializeInterpreter;
+ (void) finalizeInterpreter;
+ (bool) evalFile: (NSURL*) filename;

+ (int) numberOfScenes;
+ (NSString*) sceneName: (int) sceneIndex;
@end
