#import "AppsController.h"

@implementation AppsController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSZeroRect];
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSZeroRect];
    label.editable = NO;
    label.stringValue = @"Apps";
    [label sizeToFit];
    [self.view addSubview:label];
    self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
}

@end
