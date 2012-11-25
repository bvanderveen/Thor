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
    self.needsLayout = YES;
    [self layoutSubtreeIfNeeded];
}

- (void)popToView:(NSView *)view animated:(BOOL)animated {
    [contentView removeFromSuperview];
    self.contentView = view;
    [self addSubview:contentView];
    self.needsLayout = YES;
    [self layoutSubtreeIfNeeded];
}

- (void)viewDidMoveToSuperview {
    if (self.superview) {
        [self setNeedsLayout:YES];
    }
}

- (void)layout {
    CGFloat barHeight = [self.bar intrinsicContentSize].height;
    if (bar.stack.count > 1) {
        self.bar.frame = NSMakeRect(0, self.bounds.size.height - barHeight, self.bounds.size.width, barHeight);
        self.contentView.frame = NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height - barHeight);
    }
    else {
        // push bar out of sight to the right. eventually we will animate
        self.bar.frame = NSMakeRect(self.bounds.size.width, self.bounds.size.height - barHeight, self.bounds.size.width, barHeight);
        self.contentView.frame = self.bounds;
    }
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
    self.view = breadcrumbView;
}

- (void)viewWillAppear {
    if (!self.breadcrumbView.bar.stack.count)
        [self pushViewController:rootController animated:NO];
    else
        [self viewWillAppearForController:[self topController]];
}

- (void)viewWillAppearForController:(NSViewController<BreadcrumbControllerAware> *)controller {
    if ([controller respondsToSelector:@selector(viewWillAppear)])
        [controller viewWillAppear];
}

- (NSViewController<BreadcrumbControllerAware> *)topController {
    return [self.breadcrumbView.bar.stack lastObject];
}

- (void)pushViewController:(NSViewController<BreadcrumbControllerAware> *)controller animated:(BOOL)animated {
    controller.breadcrumbController = self;
    [self.breadcrumbView.bar pushItem:controller.breadcrumbItem animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    [self.breadcrumbView.bar popItemAnimated:animated];
}

- (void)breadcrumbBar:(BreadcrumbBar *)bar willPopItem:(id<BreadcrumbItem>)item animated:(BOOL)animated {
}

- (void)breadcrumbBar:(BreadcrumbBar *)bar didPopItem:(id<BreadcrumbItem>)item animated:(BOOL)animated {
    NSViewController<BreadcrumbControllerAware> *controller = [self topController];
    [self.breadcrumbView popToView:controller.view animated:animated];
    [self viewWillAppearForController:controller];
}

- (void)breadcrumbBar:(BreadcrumbBar *)bar willPushItem:(id<BreadcrumbItem>)item animated:(BOOL)animated {
}

- (void)breadcrumbBar:(BreadcrumbBar *)bar didPushItem:(id<BreadcrumbItem>)item animated:(BOOL)animated {
    NSViewController<BreadcrumbControllerAware> *controller = [self topController];
    [self.breadcrumbView pushToView:controller.view animated:animated];
    [self viewWillAppearForController:controller];
}

@end
