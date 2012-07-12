#import "CloudsController.h"

@implementation CloudsController

@synthesize title, breadcrumbController;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.title = @"Apps";
    }
    return self;
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSZeroRect];
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSZeroRect];
    label.editable = NO;
    label.stringValue = @"Clouds";
    label.textColor = [NSColor blackColor];
    [label sizeToFit];
    [self.view addSubview:label];
    self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
}

@end
