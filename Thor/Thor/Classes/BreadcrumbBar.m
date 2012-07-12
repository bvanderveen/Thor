#import "BreadcrumbBar.h"

@interface BreadcrumbBackItemView : NSButton

@end

@implementation BreadcrumbBackItemView

- (id)init {
    if (self = [super initWithFrame:NSZeroRect]) {
        [self setTitle:@"Back"];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(100, NSViewNoInstrinsicMetric);
}



@end

@interface BreadcrumbTitleItemView : NSButton

@end

@implementation BreadcrumbTitleItemView

- (id)initWithTitle:(NSString *)title {
    if (self = [super initWithFrame:NSZeroRect]) {
        [self setTitle:title];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(100, NSViewNoInstrinsicMetric);
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor yellowColor] set];
    NSRectFill(dirtyRect);
}

@end

@implementation BreadcrumbBar

@synthesize stack, crumbViews;

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.stack = [NSArray array];
        self.crumbViews = [NSArray array];
        self.autoresizesSubviews = NO;
    }
    return self;
}

- (void)pushItem:(id<BreadcrumbItem>)item animated:(BOOL)animated {
    NSView *itemView = self.stack.count > 0 ?
        [[BreadcrumbTitleItemView alloc] initWithTitle:item.title] :
        [[BreadcrumbBackItemView alloc] init];
    
    self.stack = [self.stack arrayByAddingObject:item];
    self.crumbViews = [self.crumbViews arrayByAddingObject:itemView];
    
    [self addSubview:itemView];
    [self setNeedsLayout:YES];
}

- (void)popItemAnimated:(BOOL)animated {
    NSMutableArray *newStack = [self.stack mutableCopy];
    [newStack removeObjectAtIndex:newStack.count - 1];
    self.stack = newStack;
    
    NSMutableArray *newViews = [self.crumbViews mutableCopy];
    [[newViews objectAtIndex:newViews.count - 1] removeFromSuperview];
    [newViews removeObjectAtIndex:newViews.count - 1];
    self.crumbViews = newViews;
    
    [self setNeedsLayout:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor blueColor] set];
    NSRectFill(dirtyRect);
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 40);
}

- (void)layout {
    CGFloat x = 0;
    for (NSControl *view in crumbViews) {
        view.frame = NSMakeRect(x, 0, [view intrinsicContentSize].width, self.bounds.size.height);
        NSLog(@"laid out crumb with frame %@", NSStringFromRect(view.frame));
        [view setNeedsLayout:YES];
    }
    [super layout];
}

@end