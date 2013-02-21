#import "FoundryEndpoint+CreateFromTarget.h"

@implementation FoundryEndpoint (CreateFromTarget)

+ (FoundryEndpoint *)endpointWithTarget:(Target *)target {
    FoundryEndpoint *result = [[FoundryEndpoint alloc] init];
    result.hostURL = [NSURL URLWithString:target.hostURL];
    result.email = target.email;
    result.password = target.password;
    return result;
}

@end
