#import "FoundryApp+CreateFromDeployment.h"

@implementation FoundryApp (CreateFromDeployment)

+ (FoundryApp *)appWithDeployment:(Deployment *)deployment {
    FoundryApp *app = [FoundryApp new];
    app.name = deployment.name;
    app.uris = @[];
    app.services = @[];
    app.stagingFramework = DetectFrameworkFromPath([NSURL fileURLWithPath:deployment.app.localRoot]);
    app.stagingRuntime = nil;
    app.instances = 1;
    app.memory = FoundryAppMemoryAmountIntegerFromAmount(FoundryAppMemoryAmount64);
    return app;
}

@end