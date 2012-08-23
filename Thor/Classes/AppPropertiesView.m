#import "AppPropertiesView.h"

@implementation AppPropertiesView

@synthesize windowLabel, confirmButton, browseButton;

- (NSSize)intrinsicContentSize {
    return NSMakeSize(480, 200);
}

@end
