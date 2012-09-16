#import "BreadcrumbController.h"
#import "TargetView.h"
#import "GridView.h"
#import "ThorCore.h"

@interface TargetController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem, GridDataSource, GridDelegate>

@property (nonatomic, strong) IBOutlet Target *target;
@property (nonatomic, strong) IBOutlet TargetView *targetView;

- (IBAction)editClicked:(id)sender;
- (IBAction)deleteClicked:(id)sender;

@end
