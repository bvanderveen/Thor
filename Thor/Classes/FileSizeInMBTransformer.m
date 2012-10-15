#import "FileSizeInMBTransformer.h"

@implementation FileSizeInMBTransformer

+ (Class)transformedValueClass;
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation;
{
    return NO;
}

- (id)transformedValue:(id)value;
{
    if (![value isKindOfClass:[NSNumber class]])
        return nil;
    
    double convertedValue = [value doubleValue];
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"MB",@"GB",@"TB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    if (multiplyFactor < 3)
        return [NSString stringWithFormat:@"%4.2f %@", convertedValue, [tokens objectAtIndex:multiplyFactor]];
    else
        return [NSString stringWithFormat:@"%f MB", [value doubleValue]];
}

@end