#import "DeploymentMemoryTransformer.h"
#import "ThorBackend.h"

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
        case DeploymentMemoryAmount64:
            return @"64MB";
        case DeploymentMemoryAmount128:
            return @"128MB";
        case DeploymentMemoryAmount256:
            return @"256MB";
        case DeploymentMemoryAmount512:
            return @"512MB";
        case DeploymentMemoryAmount1024:
            return @"1GB";
        case DeploymentMemoryAmount2048:
            return @"2GB";
        default:
            return @"??";
    }
}

- (id)reverseTransformedValue:(id)value {
    if ([value isEqual:@"64MB"])
        return [NSNumber numberWithInteger:DeploymentMemoryAmount64];
    else if ([value isEqual:@"128MB"])
        return [NSNumber numberWithInteger:DeploymentMemoryAmount128];
    else if ([value isEqual:@"256MB"])
        return [NSNumber numberWithInteger:DeploymentMemoryAmount256];
    else if ([value isEqual:@"512MB"])
        return [NSNumber numberWithInteger:DeploymentMemoryAmount512];
    else if ([value isEqual:@"1GB"])
        return [NSNumber numberWithInteger:DeploymentMemoryAmount1024];
    else if ([value isEqual:@"2GB"])
        return [NSNumber numberWithInteger:DeploymentMemoryAmount2048];
    else
        return @-1;
}

@end
