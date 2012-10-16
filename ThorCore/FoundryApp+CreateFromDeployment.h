#import "FoundryService.h"
#import "ThorBackend.h"

@interface FoundryApp (CreateFromDeployment)

+ (FoundryApp *)appWithDeployment:(Deployment *)deployment;

@end