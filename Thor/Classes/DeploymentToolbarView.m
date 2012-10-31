#import "DeploymentToolbarView.h"

@implementation DeploymentToolbarView

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        
    }
    return self;
}

- (void)layout {
    [super layout];
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 44);
}

- (void)drawRect:(NSRect)dirtyRect {
    NSImage *background = [NSImage imageNamed:@"CollectionViewBackground"];
    [[NSColor colorWithPatternImage:background] set];
    NSRectFill(dirtyRect);
}

@end
