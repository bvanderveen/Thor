#import "Target+FoundryEndpointCreation.h"

@implementation FoundryEndpoint (FoundryEndpointCreation)

+ (FoundryEndpoint *)endpointWithTarget:(Target *)target {
    FoundryEndpoint *result = [FoundryEndpoint new];
    result.hostname = target.hostname;
    result.email = target.email;
    result.password = target.password;
    return result;
}

@end
