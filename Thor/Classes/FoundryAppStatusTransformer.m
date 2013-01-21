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
    return FoundryAppStateStringFromState(intValue);
}

@end

@implementation FoundryAppStatusColorTransformer

+ (Class)transformedValueClass {
    return [NSColor class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value {
    int intValue = [value intValue];
    
    switch (intValue) {
        case FoundryAppStateStarted:
            return [NSColor greenColor];
            break;
        case FoundryAppStateStopped:
        case FoundryAppStateUnknown:
            return [NSColor redColor];
            break;
        default:
            return [NSColor orangeColor];
            break;
    }
}

@end

@implementation FoundryAppStatusIsTransientTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value {
    int intValue = [value intValue];
    return [NSNumber numberWithBool:FoundryAppStateIsTransient(intValue)];
}

@end
