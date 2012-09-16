#import <Foundation/Foundation.h>
#import "BreadcrumbBar.h"

@class BreadcrumbController;

@protocol BreadcrumbControllerAware <NSObject>

@property (nonatomic, unsafe_unretained) BreadcrumbController *breadcrumbController;
@property (nonatomic, readonly) id<BreadcrumbItem> breadcrumbItem;

// TODO move this somewhere else.
@optional
- (void)viewWillAppear;

@end

@interface BreadcrumbController : NSViewController <BreadcrumbBarDelegate>

- (id)initWithRootViewController:(NSViewController<BreadcrumbControllerAware> *)controller;

- (void)pushViewController:(NSViewController<BreadcrumbControllerAware> *)controller animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

@end
