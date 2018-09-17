#import "UserParameter.h"




@implementation UserParameter
{
    ControlType _control;
    NSString* _name;
}

- (UserParameter*) init
{
    self = [super init];
    _control = slider;
    _name = nil;
    return self;
}

- (bool) setControl: (NSString*) control
{
    if ([control isEqualToString:@"slider"]) { _control = slider; return true; }
    if ([control isEqualToString:@"text"])   { _control = text; return true; }
    return false;
}

- (void) setName: (NSString*) name
{
    _name = name;
}

- (ControlType) control
{
    return _control;
}

- (NSString*) name
{
    return _name ? _name : @"";
}

@end
