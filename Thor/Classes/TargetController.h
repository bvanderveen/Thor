#import "BreadcrumbController.h"
#import "TargetView.h"
#import "ListView.h"
#import "ThorCore.h"

@interface TargetController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem>

@property (nonatomic, strong) IBOutlet Target *target;
@property (nonatomic, strong) IBOutlet TargetView *targetView;

- (IBAction)editClicked:(id)sender;

@end
