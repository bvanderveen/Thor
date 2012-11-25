
@protocol BreadcrumbItem <NSObject>

@property (nonatomic, copy) NSString *title;

@end

@protocol BreadcrumbBarDelegate;

@interface BreadcrumbBar : NSView

@property (nonatomic, copy) NSArray *stack;
@property (nonatomic, copy) NSArray *crumbViews;
@property (nonatomic, unsafe_unretained) id<BreadcrumbBarDelegate> delegate;

- (void)pushItem:(id<BreadcrumbItem>)item animated:(BOOL)animated;
- (void)popItemAnimated:(BOOL)animated;

@end

@protocol BreadcrumbBarDelegate <NSObject>

- (void)breadcrumbBar:(BreadcrumbBar *)bar willPushItem:(id<BreadcrumbItem>)item animated:(BOOL)animated;
- (void)breadcrumbBar:(BreadcrumbBar *)bar willPopItem:(id<BreadcrumbItem>)item animated:(BOOL)animated;
- (void)breadcrumbBar:(BreadcrumbBar *)bar didPushItem:(id<BreadcrumbItem>)item animated:(BOOL)animated;
- (void)breadcrumbBar:(BreadcrumbBar *)bar didPopItem:(id<BreadcrumbItem>)item animated:(BOOL)animated;

@end
