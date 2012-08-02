#import "BreadcrumbController.h"

@interface TargetsController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem>

@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) IBOutlet NSMutableArray *targets;

@end
