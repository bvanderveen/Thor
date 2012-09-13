#import "DeploymentPropertiesView.h"
#import "ThorCore.h"

@interface DeploymentPropertiesController : NSViewController

@property (nonatomic, strong) IBOutlet NSObjectController *objectController;
@property (nonatomic, strong) IBOutlet Deployment *deployment;
@property (nonatomic, strong) IBOutlet DeploymentPropertiesView *deploymentPropertiesView;

- (IBAction)buttonClicked:(id)sender;

@end
