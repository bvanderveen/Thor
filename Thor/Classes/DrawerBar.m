#import "DrawerBar.h"

@interface DrawerBarBar : NSView

@property (nonatomic, strong) NSButton *button;

@end

@implementation DrawerBarBar

@synthesize button;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.button = [[NSButton alloc] initWithFrame:NSZeroRect];
        button.bezelStyle = NSTexturedRoundedBezelStyle;
        button.title = @"Deploy…";
        [self addSubview:button];
    }
    return self;
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 50);
}

- (void)layout {
    [button sizeToFit];
    button.frame = NSMakeRect(20, (self.bounds.size.height - button.frame.size.height) / 2, button.frame.size.width, button.frame.size.height);
    [super layout];
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithCalibratedWhite:.65 alpha:1] set];
    NSRectFill(NSMakeRect(0, self.bounds.size.height - 1, self.bounds.size.width, .5));
    [[NSColor colorWithCalibratedWhite:.97 alpha:1] set];
    NSRectFill(NSMakeRect(0, self.bounds.size.height - 2, self.bounds.size.width, .5));
}

@end

@interface DrawerContainer : NSView

@end

@implementation DrawerContainer

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    return self;
}

- (void)layout {
    if (self.subviews.count) {
        NSView *view = [self.subviews objectAtIndex:0];
        [view setFrame:self.bounds];
    }
    [super layout];
}

@end

@interface DrawerBar ()

@property (nonatomic, strong) DrawerBarBar *bar;
@property (nonatomic, strong) NSView *drawerContainer;

@end

@implementation DrawerBar

@synthesize expanded = _expanded, bar, drawerView, contentView, drawerContainer;

- (void)setExpanded:(BOOL)value {
    _expanded = value;
    if (_expanded) {
        [drawerContainer addSubview:drawerView];
    }
    else
        [drawerView removeFromSuperview];
    self.needsLayout = YES;
    [self layoutSubtreeIfNeeded];
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.drawerContainer = [[DrawerContainer alloc] initWithFrame:NSZeroRect];
        [self addSubview:drawerContainer];
        
        self.bar = [[DrawerBarBar alloc] initWithFrame:NSZeroRect];
        bar.button.target = self;
        bar.button.action = @selector(toggleDrawer);
        [self addSubview:bar];
        
        self.autoresizesSubviews = NO;
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)layout {
    NSSize barSize = [bar intrinsicContentSize];
    NSSize drawerSize = NSMakeSize(NSViewNoInstrinsicMetric, 250);
    
    if (self.expanded) {
        self.contentView.frame = NSMakeRect(0, barSize.height + drawerSize.height, self.bounds.size.width, self.bounds.size.height - barSize.height - drawerSize.height);
        self.drawerContainer.frame = NSMakeRect(0, barSize.height, self.bounds.size.width, drawerSize.height);
    }
    else {
        self.contentView.frame = NSMakeRect(0, barSize.height, self.bounds.size.width, self.bounds.size.height - barSize.height);
        self.drawerContainer.frame = NSMakeRect(0, 0, self.bounds.size.width, drawerSize.height);
    }
    
    self.bar.frame = NSMakeRect(0, 0, self.bounds.size.width, barSize.height);
    [super layout];
}

- (void)toggleDrawer {
    self.expanded = !self.expanded;
}

@end
