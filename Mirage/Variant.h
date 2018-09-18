#ifndef Variant_h
#define Variant_h
#import <Foundation/Foundation.h>




@interface Variant: NSObject

typedef NS_ENUM(NSInteger, Type)
{
    Integer, Double, String
};

- (Variant*) initWithDouble: (double) value;
- (Variant*) initWithString: (NSString*) value;
- (enum Type) type;
- (int)       asInteger;
- (double)    asDouble;
- (NSString*) asString;

@end

#endif /* Variant_h */
