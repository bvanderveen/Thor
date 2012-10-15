#import "FoundryAppStatusTransformer.h"
#import "ThorCore.h"

@implementation FoundryAppStatusTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value {
    int intValue = [value intValue];
    
    switch (intValue) {
        case FoundryAppStateStarted:
            return @"Started";
            break;
        case FoundryAppStateStopped:
            return @"Stopped";
            break;
        case FoundryAppStateUnknown:
        default:
            return @"Unknown";
            break;
    }
}

@end
