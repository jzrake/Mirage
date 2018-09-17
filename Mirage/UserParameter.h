#ifndef UserParameter_h
#define UserParameter_h
#import <Foundation/Foundation.h>




@interface UserParameter: NSObject

typedef NS_ENUM(NSInteger, ControlType)
{
    slider, text
};

- (UserParameter*) init;
- (bool) setControl: (NSString*) control;
- (void) setName: (NSString*) name;
- (ControlType) control;
- (NSString*) name;

@end

#endif /* UserParameter_h */
