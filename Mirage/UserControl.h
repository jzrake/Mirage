#ifndef UserControl_h
#define UserControl_h
#import <Foundation/Foundation.h>
#include "Variant.h"




@interface UserControl: NSObject

typedef NS_ENUM(NSInteger, ControlType)
{
    slider, text
};

- (UserControl*_Nonnull) init;
- (bool) setControlTypeName: (NSString*_Nonnull) typeName;

@property ControlType type;
@property (nullable) NSString* name;
@property (nullable) Variant* value;

@end

#endif /* UserControl_h */
