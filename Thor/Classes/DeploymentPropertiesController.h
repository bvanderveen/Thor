#import "DeploymentPropertiesView.h"
#import "ThorCore.h"
#import "WizardController.h"

@interface DeploymentProperties : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSUInteger instances;
@property (nonatomic, assign) FoundryAppMemoryAmount memory;

@end

@interface DeploymentPropertiesController : NSViewController <WizardControllerAware>

@property (nonatomic, strong) IBOutlet NSObjectController *objectController;
@property (nonatomic, strong) IBOutlet DeploymentProperties *deploymentProperties;
@property (nonatomic, strong) IBOutlet DeploymentPropertiesView *deploymentPropertiesView;

// used when editing an existing deployment
+ (DeploymentPropertiesController *)deploymentPropertiesControllerWithApp:(FoundryApp *)app client:(FoundryClient *)service;

// used when creating a new deployment. Deployment object is assumed to be
// inserted and will be saved if user presses OK
+ (DeploymentPropertiesController *)deploymentPropertiesControllerWithDeployment:(Deployment *)deployment;

@end
