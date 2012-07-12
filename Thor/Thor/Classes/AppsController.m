#import "AppsController.h"

@implementation AppsController

@synthesize title;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.title = @"Apps";
    }
    return self;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
    label.editable = NO;
    label.stringValue = @"Apps";
    [label sizeToFit];
    [self.view addSubview:label];
    self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
}

@end
