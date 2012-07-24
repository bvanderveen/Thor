#import "BottomBar.h"

#define PADDING 10

@implementation BottomBar

@synthesize barButton;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.barButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        barButton.bezelStyle = NSTexturedRoundedBezelStyle;
        [self addSubview:barButton];
        [self setNeedsLayout:YES];
    }
    return self;
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, barButton.intrinsicContentSize.height + PADDING * 2);
}

- (void)layout {
    barButton.frame = NSMakeRect(PADDING, PADDING, barButton.intrinsicContentSize.width, barButton.intrinsicContentSize.height);
    [super layout];
}

- (void)drawRect:(NSRect)dirtyRect {
    // TODO draw a gradient
    [[NSColor grayColor] set];
    NSRectFill(dirtyRect);
}

@end
