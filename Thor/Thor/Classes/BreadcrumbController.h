#import <Foundation/Foundation.h>
#import "BreadcrumbBar.h"

@interface BreadcrumbController : NSViewController

//@property (nonatomic, strong, readonly) BreadcrumbBar *bar;

- (id)initWithRootViewController:(NSViewController *)controller;

- (void)pushViewController:(NSViewController<BreadcrumbItem> *)controller animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

@end
