#include "Variant.h"




@implementation Variant
{
    enum VariantType _type;

    int       _i_value;
    double    _d_value;
    NSString* _s_value;
}

- (Variant*) initWithString:(NSString *)value
{
    self = [super init];
    _type = stringVariant;
    _s_value = value;
    return self;
}

- (Variant*) initWithDouble:(double)value
{
    self = [super init];
    _type = doubleVariant;
    _d_value = value;
    return self;
}

- (enum VariantType) type
{
    return _type;
}

- (int) asInteger
{
    return _type == integerVariant ? _i_value : 0;
}

- (double) asDouble
{
    return _type == doubleVariant ? _d_value : 0.0;
}

- (NSString*) asString
{
    return _type == stringVariant ? _s_value : nil;
}

@end
