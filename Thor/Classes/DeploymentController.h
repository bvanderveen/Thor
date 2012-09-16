#import "BreadcrumbController.h"
#import "GridView.h"
#import "DeploymentView.h"
#import "ThorCore.h"

@interface DeploymentController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem, GridDataSource, GridDelegate>

@property (nonatomic, strong) Deployment *deployment;
@property (nonatomic, strong) IBOutlet FoundryApp *app;
@property (nonatomic, copy) NSArray *instanceStats;
@property (nonatomic, strong) IBOutlet DeploymentView *deploymentView;

- (id)initWithDeployment:(Deployment *)deployment;

- (IBAction)deleteClicked:(id)sender;

@end
