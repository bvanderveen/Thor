#import "CloudService.h"

@implementation CloudInfo

@synthesize hostname, email, password;

@end

@implementation CloudApp

@synthesize name, uris, instances, memory, disk, state;

@end

@implementation CloudAppInstanceStats

@synthesize ID, host, port, cpu, memory, disk, uptime;

@end

@implementation FixtureCloudService

- (NSArray *)getApps {
    return [NSArray arrayWithObjects:[self getAppWithName:@"fixture_app1"], [self getAppWithName:@"fixture_app2"], nil];
}

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

- (NSArray *)getStatsForAppWithName:(NSString *)name {
    CloudAppInstanceStats *stats0 = [CloudAppInstanceStats new];
    stats0.ID = @"0";
    stats0.host = @"10.0.0.1";
    stats0.port = 23433;
    stats0.cpu = 100.0;
    stats0.memory = 2 * 1024 * 1024 * 1024 * 1024;
    stats0.disk = 53 * 1024 * 1024 * 1024;
    stats0.uptime = 32492.3;
    
    CloudAppInstanceStats *stats1 = [CloudAppInstanceStats new];
    stats1.ID = @"1";
    stats1.host = @"10.0.0.2";
    stats1.port = 23435;
    stats1.cpu = 80.0;
    stats1.memory = 2 * 1024 * 1024 * 1024 * 1024;
    stats1.disk = 53 * 1024 * 1024 * 1024;
    stats1.uptime = 32487.9;
    
    return [NSArray arrayWithObjects:stats0, stats1, nil];
}

@end
