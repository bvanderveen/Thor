#import "BreadcrumbController.h"

@interface BreadcrumbControllerView : NSView

@property (nonatomic, strong) BreadcrumbBar *bar;
@property (nonatomic, strong) NSView *contentView;

@end

@implementation BreadcrumbControllerView

@synthesize bar, contentView;

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.bar = [[BreadcrumbBar alloc] initWithFrame:NSZeroRect];
        [self addSubview:bar];
    }
    return self;
}

- (void)pushToView:(NSView *)view animated:(BOOL)animated {
    [contentView removeFromSuperview];
    self.contentView = view;
    [self addSubview:contentView];
    [self setNeedsLayout:YES];
}

- (void)popToView:(NSView *)view animated:(BOOL)animated {
    [contentView removeFromSuperview];
    self.contentView = view;
    [self addSubview:contentView];
    [self setNeedsLayout:YES];
}

- (void)viewDidMoveToSuperview {
    if (self.superview) {
        [self setNeedsLayout:YES];
    }
}

- (void)layout {
    CGFloat barHeight = [self.bar intrinsicContentSize].height;
    self.bar.frame = NSMakeRect(0, self.bounds.size.height - barHeight, self.bounds.size.width, barHeight);
    self.contentView.frame = NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height - barHeight);
    [super layout];
}

@end

@interface BreadcrumbController ()

@property (nonatomic, strong) BreadcrumbControllerView *breadcrumbView;
@property (nonatomic, strong) NSViewController<BreadcrumbControllerAware> *rootController;

@end

@implementation BreadcrumbController

@synthesize breadcrumbView, rootController;

- (id)initWithRootViewController:(NSViewController<BreadcrumbControllerAware> *)leRootController {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.rootController = leRootController;
    }
    return self;
}

- (void)loadView {
    self.breadcrumbView = [[BreadcrumbControllerView alloc] initWithFrame:NSZeroRect];
    self.breadcrumbView.bar.delegate = self;
    [self pushViewController:rootController animated:NO];
    self.view = breadcrumbView;
}

- (void)pushViewController:(NSViewController<BreadcrumbControllerAware> *)controller animated:(BOOL)animated {
    controller.breadcrumbController = self;
    [self.breadcrumbView.bar pushItem:controller.breadcrumbItem animated:animated];
    [self.breadcrumbView pushToView:controller.view animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    [self.breadcrumbView.bar popItemAnimated:animated];
    NSViewController *controller = (NSViewController *)[self.breadcrumbView.bar.stack lastObject];
    [self.breadcrumbView popToView:controller.view animated:animated];
}

- (void)breadcrumbBar:(BreadcrumbBar *)bar willPopItem:(id<BreadcrumbItem>)item {
    NSViewController *controller = (NSViewController *)[self.breadcrumbView.bar.stack objectAtIndex:self.breadcrumbView.bar.stack.count - 2];
    [self.breadcrumbView popToView:controller.view animated:NO];
}

- (void)breadcrumbBar:(BreadcrumbBar *)bar didPopItem:(id<BreadcrumbItem>)item {
    
}
- (void)breadcrumbBar:(BreadcrumbBar *)bar willPushItem:(id<BreadcrumbItem>)item {
    
}
- (void)breadcrumbBar:(BreadcrumbBar *)bar didPushItem:(id<BreadcrumbItem>)item {
    
}



@end
