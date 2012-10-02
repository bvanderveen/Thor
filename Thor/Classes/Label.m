#import "Label.h"

@implementation Label

+ (NSTextField *)label {
    NSTextField *result = [[NSTextField alloc] initWithFrame:NSZeroRect];
    result.editable = NO;
    result.bordered = NO;
    result.translatesAutoresizingMaskIntoConstraints = NO;
    result.drawsBackground = NO;
    result.alignment = NSRightTextAlignment;
    return  result;
}

@end