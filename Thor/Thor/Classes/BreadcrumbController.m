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
        
        self.contentView = [[NSView alloc] initWithFrame:NSZeroRect];
        self.contentView.autoresizesSubviews = YES;
    }
    return self;
}

- (void)pushToView:(NSView *)view animated:(BOOL)animated {
    [contentView removeFromSuperview];
    self.contentView = view;
    [self setNeedsLayout:YES];
}

- (void)popToView:(NSView *)view animated:(BOOL)animated {
    [contentView removeFromSuperview];
    self.contentView = view;
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
    NSLog(@"breadcrumb container set bar frame to %@", NSStringFromRect(self.bar.frame));
    self.contentView.frame = NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height - barHeight);
    NSLog(@"breadcrumb container set content frame to %@", NSStringFromRect(self.contentView.frame));
    [super layout];
}

@end

@interface BreadcrumbController ()

@property (nonatomic, strong) BreadcrumbControllerView *breadcrumbView;
@property (nonatomic, strong) NSViewController<BreadcrumbItem> *rootController;

@end

@implementation BreadcrumbController

@synthesize breadcrumbView, rootController;

- (id)initWithRootViewController:(NSViewController<BreadcrumbItem> *)leRootController {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.rootController = leRootController;
    }
    return self;
}

- (void)loadView {
    self.breadcrumbView = [[BreadcrumbControllerView alloc] initWithFrame:NSZeroRect];
    [self pushViewController:rootController animated:NO];
    self.view = breadcrumbView;
}

- (void)pushViewController:(NSViewController<BreadcrumbItem> *)controller animated:(BOOL)animated {
    [self.breadcrumbView.bar pushItem:controller animated:animated];
    [self.breadcrumbView pushToView:controller.view animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    [self.breadcrumbView.bar popItemAnimated:animated];
    NSViewController *controller = (NSViewController *)[self.breadcrumbView.bar.stack lastObject];
    [self.breadcrumbView popToView:controller.view animated:animated];
}


@end
