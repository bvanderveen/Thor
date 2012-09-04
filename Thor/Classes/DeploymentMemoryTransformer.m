#import "DeploymentMemoryTransformer.h"

@implementation DeploymentMemoryTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value {
    int intValue = [value intValue];
    
    switch (intValue) {
        case 0:
            return @"64MB";
        case 1:
            return @"128MB";
        case 2:
            return @"256MB";
        case 3:
            return @"512MB";
        case 4:
            return @"1GB";
        case 5:
            return @"2GB";
        default:
            return @"??";
    }
}

- (id)reverseTransformedValue:(id)value {
    if ([value isEqual:@"64MB"])
        return @0;
    else if ([value isEqual:@"128MB"])
        return @1;
    else if ([value isEqual:@"256MB"])
        return @2;
    else if ([value isEqual:@"512MB"])
        return @3;
    else if ([value isEqual:@"1GB"])
        return @4;
    else if ([value isEqual:@"2GB"])
        return @5;
    else
        return @-1;
}

@end
