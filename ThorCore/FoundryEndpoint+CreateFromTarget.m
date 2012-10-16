#import "FoundryEndpoint+CreateFromTarget.h"

@implementation FoundryEndpoint (CreateFromTarget)

+ (FoundryEndpoint *)endpointWithTarget:(Target *)target {
    FoundryEndpoint *result = [FoundryEndpoint new];
    result.hostname = target.hostname;
    result.email = target.email;
    result.password = target.password;
    return result;
}

@end
