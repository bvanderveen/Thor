#import "CloudService.h"

@implementation CloudApp

@synthesize name, uris, instances, memory, disk, state;

@end

@implementation FixtureCloudService

- (CloudApp *)getAppWithName:(NSString *)name {
    CloudApp *result = [CloudApp new];
    result.name = name;
    result.uris = [NSArray arrayWithObject:@"api.coolapp.com"];
    result.instances = 2;
    result.memory = 1024 * 1024;
    result.disk = 1024 * 1024 * 1024;
    result.state = CloudAppStateStarted;
    return result;
}

@end
