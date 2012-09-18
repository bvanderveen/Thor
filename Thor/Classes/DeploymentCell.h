#import "ThorCore.h"
#import "ListView.h"

@interface DeploymentCell : ListCell

@property (nonatomic, strong) Deployment *deployment;
@property (nonatomic, strong) NSButton *pushButton;

@end
