
@protocol BreadcrumbItem <NSObject>

@property (nonatomic, readonly) NSString *title;

@end

@interface BreadcrumbBar : NSView

@property (nonatomic, copy) NSArray *stack;
@property (nonatomic, copy) NSArray *crumbViews;

- (void)pushItem:(id<BreadcrumbItem>)item animated:(BOOL)animated;
- (void)popItemAnimated:(BOOL)animated;

@end

@protocol BreadcrumbBarDelegate <NSObject>

- (void)breadcrumbBar:(BreadcrumbBar *)bar willPushItem:(id<BreadcrumbItem>)item;
- (void)breadcrumbBar:(BreadcrumbBar *)bar willPopItem:(id<BreadcrumbItem>)item;
- (void)breadcrumbBar:(BreadcrumbBar *)bar didPushItem:(id<BreadcrumbItem>)item;
- (void)breadcrumbBar:(BreadcrumbBar *)bar didPopItem:(id<BreadcrumbItem>)item;

@end
