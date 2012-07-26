#import "BreadcrumbController.h"
#import "GridView.h"

@interface TargetController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem, GridDataSource>

- (id)initWithTarget:(Target *)leTarget;

@end
