#import "FoundryService.h"
#import "ThorCore.h"

@interface FoundryEndpoint (FoundryEndpointCreation)

+ (FoundryEndpoint *)endpointWithTarget:(Target *)target;

@end
