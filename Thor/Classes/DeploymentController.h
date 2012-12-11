#import "BreadcrumbController.h"
#import "GridView.h"
#import "DeploymentView.h"
#import "ThorCore.h"

@interface DeploymentController : NSViewController <GridDataSource, GridDelegate>


@property (nonatomic, strong) Target *target;
@property (nonatomic, strong) NSString *appName;

@property (nonatomic, strong) IBOutlet FoundryApp *app;
@property (nonatomic, strong) IBOutlet DeploymentView *deploymentView;

- (IBAction)editClicked:(id)sender;
- (IBAction)deleteClicked:(id)sender;

@end
