#import "DeploymentPropertiesView.h"
#import "ThorCore.h"
#import "WizardController.h"

@interface DeploymentPropertiesController : NSViewController <WizardControllerAware>

@property (nonatomic, strong) IBOutlet NSObjectController *objectController;
@property (nonatomic, strong) IBOutlet NSObject *bindingObject;
@property (nonatomic, strong) IBOutlet DeploymentPropertiesView *deploymentPropertiesView;

+ (DeploymentPropertiesController *)deploymentPropertiesControllerWithApp:(FoundryApp *)app client:(FoundryClient *)service;
+ (DeploymentPropertiesController *)deploymentPropertiesControllerWithDeployment:(Deployment *)deployment create:(BOOL)create;

@end
