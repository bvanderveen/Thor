#import "BreadcrumbController.h"
#import "GridView.h"
#import "DeploymentView.h"

@interface DeploymentInfo : NSObject

@property (nonatomic, copy) NSString *appName;
@property (nonatomic, strong) VMCTarget *target;

@end

@interface DeploymentController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem, GridDataSource, GridDelegate>

@property (nonatomic, strong) DeploymentInfo *deploymentInfo;
@property (nonatomic, strong) IBOutlet CloudApp *cloudApp;
@property (nonatomic, copy) NSArray *instanceStats;
@property (nonatomic, strong) IBOutlet DeploymentView *deploymentView;

- (id)initWithDeploymentInfo:(DeploymentInfo *)deploymentInfo;

@end
