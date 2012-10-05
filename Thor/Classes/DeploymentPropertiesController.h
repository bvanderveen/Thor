#import "DeploymentPropertiesView.h"
#import "ThorCore.h"
#import "WizardController.h"

@interface DeploymentPropertiesController : NSViewController <WizardControllerAware>

@property (nonatomic, strong) IBOutlet NSObjectController *objectController;
@property (nonatomic, strong) IBOutlet Deployment *deployment;
@property (nonatomic, strong) IBOutlet DeploymentPropertiesView *deploymentPropertiesView;

+ (DeploymentPropertiesController *)newDeploymentControllerWithTarget:(Target *)target app:(App *)app;

@end
