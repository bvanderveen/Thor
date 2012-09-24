#import <Foundation/Foundation.h>
#import "BreadcrumbBar.h"
#import "ViewVisibilityAware.h"

@class BreadcrumbController;

@protocol BreadcrumbControllerAware <NSObject, ViewVisibilityAware>

@property (nonatomic, unsafe_unretained) BreadcrumbController *breadcrumbController;
@property (nonatomic, readonly) id<BreadcrumbItem> breadcrumbItem;

@end

@interface BreadcrumbController : NSViewController <BreadcrumbBarDelegate, ViewVisibilityAware>

- (id)initWithRootViewController:(NSViewController<BreadcrumbControllerAware> *)controller;

- (void)pushViewController:(NSViewController<BreadcrumbControllerAware> *)controller animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

@end
