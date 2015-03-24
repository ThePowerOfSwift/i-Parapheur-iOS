
#import <Foundation/Foundation.h>
#import <Mantle.h>


@interface StringUtils : NSObject

+ (NSDictionary *) nilifyValuesOfDictionary:(NSDictionary *)dictionary;

+ (NSString *)getErrorMessage:(NSError *)error;

+ (void)logErrorMessage:(NSError *)message;

+ (MTLValueTransformer *)getNullToFalseValueTransformer;

+ (MTLValueTransformer *)getNullToNilValueTransformer;

+ (MTLValueTransformer *)getNullToZeroValueTransformer;

+ (MTLValueTransformer *)getNullToEmptyDictionaryValueTransformer;

+ (MTLValueTransformer *)getNullToEmptyArrayValueTransformer;

@end
