#import "BreadcrumbBar.h"

@interface BreadcrumbItemView : NSButton

@property (nonatomic, strong) id<BreadcrumbItem> item;

- (id)initWithItem:(id<BreadcrumbItem>)item;

@end

@implementation BreadcrumbItemView

@synthesize item;

- (id)initWithItem:(id<BreadcrumbItem>)leItem {
    if (self = [super initWithFrame:NSZeroRect]) {
        self.item = leItem;
    }
    return self;
}

@end

@interface BreadcrumbBackItemView : BreadcrumbItemView

@end

@implementation BreadcrumbBackItemView

- (id)initWithItem:(id<BreadcrumbItem>)item {
    if (self = [super initWithItem:item]) {
        [self setTitle:@"Back"];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(100, NSViewNoInstrinsicMetric);
}



@end

@interface BreadcrumbTitleItemView : BreadcrumbItemView

@end

@implementation BreadcrumbTitleItemView

- (id)initWithItem:(id<BreadcrumbItem>)item {
    if (self = [super initWithItem:item]) {
        [self setTitle:item.title];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(100, NSViewNoInstrinsicMetric);
}

@end

@implementation BreadcrumbBar

@synthesize stack, crumbViews, delegate;

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.stack = [NSArray array];
        self.crumbViews = [NSArray array];
        self.autoresizesSubviews = NO;
    }
    return self;
}

- (void)pushItem:(id<BreadcrumbItem>)item animated:(BOOL)animated {
    BreadcrumbItemView *itemView = self.stack.count > 0 ?
        [[BreadcrumbTitleItemView alloc] initWithItem:item] :
        [[BreadcrumbBackItemView alloc] initWithItem:item];
    
    itemView.target = self;
    itemView.action = @selector(itemViewClicked:);
    
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
        CGFloat w = [view intrinsicContentSize].width;
        view.frame = NSMakeRect(x, 0, w, self.bounds.size.height);
        NSLog(@"laid out crumb with frame %@", NSStringFromRect(view.frame));
        [view setNeedsLayout:YES];
        x += w + 2;
    }
    [super layout];
}

- (void)itemViewClicked:(BreadcrumbItemView *)itemView {
    NSUInteger index = [stack indexOfObject:itemView.item];
    if (stack.count == 1) return;
    NSUInteger currentIndex = stack.count - 1;
    while (currentIndex > index) {
        id<BreadcrumbItem> itemAtIndex = [stack objectAtIndex:currentIndex];
        [delegate breadcrumbBar:self willPopItem:itemAtIndex];
        [self popItemAnimated:NO];
        [delegate breadcrumbBar:self didPopItem:itemAtIndex];
        currentIndex--;
    }
}

@end