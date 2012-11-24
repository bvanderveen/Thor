#import "DeploymentMemoryTransformer.h"
#import "ThorCore.h"

@implementation FoundryAppMemoryAmountTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value {
    FoundryAppMemoryAmount amount = [value intValue];
    return FoundryAppMemoryAmountStringFromAmount(amount);
}

@end

@implementation FoundryAppMemoryAmountIntegerTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value {
    FoundryAppMemoryAmount amount = FoundryAppMemoryAmountAmountFromInteger([value intValue]);
    return FoundryAppMemoryAmountStringFromAmount(amount);
}

@end

//
//- (id)reverseTransformedValue:(id)value {
//    if ([value isEqual:@"64MB"])
//        return [NSNumber numberWithInteger:FoundryAppMemoryAmount64];
//    else if ([value isEqual:@"128MB"])
//        return [NSNumber numberWithInteger:FoundryAppMemoryAmount128];
//    else if ([value isEqual:@"256MB"])
//        return [NSNumber numberWithInteger:FoundryAppMemoryAmount256];
//    else if ([value isEqual:@"512MB"])
//        return [NSNumber numberWithInteger:FoundryAppMemoryAmount512];
//    else if ([value isEqual:@"1GB"])
//        return [NSNumber numberWithInteger:FoundryAppMemoryAmount1024];
//    else if ([value isEqual:@"2GB"])
//        return [NSNumber numberWithInteger:FoundryAppMemoryAmount2048];
//    else
//        return @-1;
//}
