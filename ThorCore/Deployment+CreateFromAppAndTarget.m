#import "Deployment+CreateFromAppAndTarget.h"

@implementation Deployment (CreateFromAppAndTarget)

+ (Deployment *)deploymentWithApp:(App *)app target:(Target *)target {
    Deployment *result = [Deployment deploymentInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    result.app = app;
    result.target = target;
    result.name = [((NSURL *)[NSURL fileURLWithPath:app.localRoot]).pathComponents lastObject];
    return result;
}

@end
