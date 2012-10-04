#import "Label.h"

@implementation Label

+ (Label *)label {
    Label *result = [[Label alloc] initWithFrame:NSZeroRect];
    result.editable = NO;
    result.bordered = NO;
    result.drawsBackground = NO;
    result.alignment = NSRightTextAlignment;
    return result;
}

@end