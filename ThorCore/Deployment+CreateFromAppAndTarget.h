#import "ThorBackend.h"

@interface Deployment (CreateFromAppAndTarget)

+ (Deployment *)deploymentWithApp:(App *)app target:(Target *)target;

@end
