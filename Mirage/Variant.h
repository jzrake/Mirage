#ifndef Variant_h
#define Variant_h
#import <Foundation/Foundation.h>




@interface Variant: NSObject

typedef NS_ENUM(NSInteger, VariantType)
{
    integerVariant, doubleVariant, stringVariant
};

- (Variant*) initWithDouble: (double) value;
- (Variant*) initWithString: (NSString*) value;
- (enum VariantType) type;
- (int)       asInteger;
- (double)    asDouble;
- (NSString*) asString;

@end

#endif /* Variant_h */
