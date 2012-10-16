#import "FoundryApp+CreateFromDeployment.h"

@implementation FoundryApp (CreateFromDeployment)

+ (FoundryApp *)appWithDeployment:(Deployment *)deployment {
    FoundryApp *app = [FoundryApp new];
    app.name = deployment.appName;
    app.uris = @[];
    app.stagingFramework = DetectFrameworkFromPath([NSURL fileURLWithPath:deployment.app.localRoot]);
    app.stagingRuntime = nil;
    app.instances = deployment.instances;
    app.memory = deployment.memory;
    return app;
}

@end