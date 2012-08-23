#import "BreadcrumbBar.h"
#import "NSString+ShadowedTextDrawing.h"

#define BAR_BACKGROUND_COLOR ([NSColor colorWithSRGBRed:.25 green:.27 blue:.30 alpha:1.0])

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
        self.bordered = NO;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(44, 44);
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithSRGBRed:.17 green:.19 blue:.21 alpha:1.0] set];
    NSRectFill(self.bounds);
    
    [BAR_BACKGROUND_COLOR set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width - 1, self.bounds.size.height - 1));
    
    NSImage *arrowImage = [NSImage imageNamed:((NSButtonCell *)self.cell).isHighlighted ? @"BreadcrumbArrowSelected" : @"BreadcrumbArrow"];
    CGSize contentSize = [self intrinsicContentSize];
    
    [arrowImage drawAtPoint:NSMakePoint((contentSize.width - arrowImage.size.width) / 2, (contentSize.height - arrowImage.size.height) / 2 - 2) fromRect:(NSRect){ .origin = NSZeroPoint, .size = arrowImage.size } operation:NSCompositeSourceOver fraction:1];
}

@end

@interface BreadcrumbTitleItemView : BreadcrumbItemView

@end

@implementation BreadcrumbTitleItemView

- (id)initWithItem:(id<BreadcrumbItem>)item {
    if (self = [super initWithItem:item]) {
        self.title = item.title;
        self.bordered = NO;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(100, NSViewNoInstrinsicMetric);
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithSRGBRed:.17 green:.19 blue:.21 alpha:1.0] set];
    NSRectFill(self.bounds);
    
    [BAR_BACKGROUND_COLOR set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height - 1));
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingMiddle;
    paragraphStyle.alignment = NSCenterTextAlignment;
    
    NSFont *labelFont = [NSFont boldSystemFontOfSize:12];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                labelFont, NSFontAttributeName,
                                [NSColor whiteColor], NSForegroundColorAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName,
                                nil];
    
    CGFloat fontLineHeight = labelFont.leading + labelFont.ascender - labelFont.descender;
    NSRect labelRect = NSMakeRect(0, (self.bounds.size.height - fontLineHeight) / 2 + 1, self.bounds.size.width, fontLineHeight + 2);
    
    [self.title drawShadowedInRect:labelRect withAttributes:attributes];
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
    [[NSColor colorWithSRGBRed:.17 green:.19 blue:.21 alpha:1.0] set];
    NSRectFill(self.bounds);
    
    [BAR_BACKGROUND_COLOR set];
    NSRectFill(NSMakeRect(0, 1, self.bounds.size.width, self.bounds.size.height - 1));
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 40);
}

- (void)layout {
    CGFloat x = 0;
    for (NSControl *view in crumbViews) {
        CGFloat w = [view intrinsicContentSize].width;
        view.frame = NSMakeRect(x, 0, w, self.bounds.size.height);
        [view setNeedsLayout:YES];
        x += w;
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