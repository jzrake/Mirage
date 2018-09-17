#include "Variant.h"




@implementation Variant
{
    enum Type _type;

    int       _i_value;
    double    _d_value;
    NSString* _s_value;
}

- (Variant*) initWithString:(NSString *)value
{
    self = [super init];
    _type = String;
    _s_value = value;
    return self;
}

- (Variant*) initWithDouble:(double)value
{
    self = [super init];
    _type = Double;
    _d_value = value;
    return self;
}

- (enum Type) type
{
    return _type;
}

- (int) asInteger
{
    return _type == Integer ? _i_value : 0;
}

- (double) asDouble
{
    return _type == Double ? _d_value : 0.0;
}

- (NSString*) asString
{
    return _type == String ? _s_value : nil;
}

@end
