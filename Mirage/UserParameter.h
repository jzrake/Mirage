#ifndef UserParameter_h
#define UserParameter_h
#import <Foundation/Foundation.h>
#include "Variant.h"




@interface UserParameter: NSObject

typedef NS_ENUM(NSInteger, ControlType)
{
    slider, text
};

- (UserParameter*_Nonnull) init;
- (bool) setControlTypeName: (NSString*_Nonnull) controlTypeName;

@property ControlType control;
@property (nullable) NSString* name;
@property (nullable) Variant* value;

@end

#endif /* UserParameter_h */
