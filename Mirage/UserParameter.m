#import "UserParameter.h"




@implementation UserParameter
{
    ControlType _control;
    NSString* _name;
    Variant* _value;
}

- (UserParameter*) init
{
    self = [super init];
    _control = slider;
    _name = nil;
    return self;
}

- (bool) setControlTypeName:(NSString *)controlTypeName
{
    if ([controlTypeName isEqualToString:@"slider"]) { _control = slider; return true; }
    if ([controlTypeName isEqualToString:@"text"])   { _control = text; return true; }
    return false;
}

@end
