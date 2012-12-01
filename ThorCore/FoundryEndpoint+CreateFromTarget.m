#import "FoundryEndpoint+CreateFromTarget.h"

@implementation FoundryEndpoint (CreateFromTarget)

+ (FoundryEndpoint *)endpointWithTarget:(Target *)target {
    FoundryEndpoint *result = [[FoundryEndpoint alloc] init];
    result.hostname = target.hostname;
    result.email = target.email;
    result.password = target.password;
    return result;
}

@end
