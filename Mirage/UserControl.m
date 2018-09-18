#import "UserControl.h"




@implementation UserControl
{
    ControlType _type;
    NSString* _name;
    Variant* _value;
}

- (UserControl*) init
{
    self = [super init];
    _type = slider;
    _name = nil;
    return self;
}

- (bool) setControlTypeName:(NSString *)controlTypeName
{
    if ([controlTypeName isEqualToString:@"slider"]) { _type = slider; return true; }
    if ([controlTypeName isEqualToString:@"text"])   { _type = text; return true; }
    return false;
}

@end
