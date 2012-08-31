#import "CloudService.h"
#import "SMWebRequest+RAC.h"
#import "NSObject+JSONDataRepresentation.h"
#import "SBJson.h"

@implementation FoundryEndpoint

@synthesize hostname, email, password;

@end

@implementation FoundryApp

@synthesize name, uris, instances, memory, disk, state;

static NSDictionary *stateDict = nil;

+ (void)initialize {
    stateDict = @{
        @"STARTED" : [NSNumber numberWithInt:FoundryAppStateStarted],
        @"STOPPED" : [NSNumber numberWithInt:FoundryAppStateStopped]
    };
}

+ (FoundryApp *)appWithDictionary:(NSDictionary *)appDict {
    FoundryApp *app = [FoundryApp new];
    
    app.name = appDict[@"name"];
    app.uris = appDict[@"uris"];
    app.instances = [appDict[@"instances"] intValue];

    NSString *state = appDict[@"state"];
    
    NSLog(@"Got app state '%@'", state);
    if (![stateDict.allKeys containsObject:state]) {
        NSLog(@"Got previously unknown app state '%@'", state);
        app.state = FoundryAppStateUnknown;
    }
    else
    app.state = [stateDict[state] intValue];

    NSDictionary *resources = appDict[@"resources"];
    app.memory = [resources[@"memory"] intValue];
    app.disk = [resources[@"disk"] intValue];

    return app;
}

@end

@implementation FoundryAppInstanceStats

@synthesize ID, host, port, cpu, memory, disk, uptime;

+ (FoundryAppInstanceStats *)instantsStatsWithID:(NSString *)lID dictionary:(NSDictionary *)dictionary {
    FoundryAppInstanceStats *result = [FoundryAppInstanceStats new];
    result.ID = lID;
    
    NSDictionary *statsDict = dictionary[@"stats"];
    result.host = statsDict[@"host"];
    result.port = [statsDict[@"port"] intValue];
    
    result.uptime = [statsDict[@"uptime"] floatValue];
    
    NSDictionary *usageDict = statsDict[@"usage"];
    result.cpu = [usageDict[@"cpu"] floatValue];
    result.memory = [usageDict[@"mem"] floatValue];
    result.disk = [usageDict[@"disk"] intValue];
 
    return result;
}

@end

@interface FoundryService ()

@property (nonatomic, copy) NSString *token;

@end


static id (^JsonParser)(id) = ^ id (id data) {
    return [((NSData *)data) JSONValue];
};


@implementation FoundryService

@synthesize endpoint, token;

- (id)initWithEndpoint:(FoundryEndpoint *)lEndpoint {
    if (self = [super init]) {
        self.endpoint = lEndpoint;
    }
    return self;
}

- (NSURL *)URLForPath:(NSString *)path {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", endpoint.hostname, path]];
}

- (NSMutableURLRequest *)URLRequestForPath:(NSString *)path {
    return [NSMutableURLRequest requestWithURL:[self URLForPath:path]];
}

- (NSMutableURLRequest *)URLRequestForPath:(NSString *)path withToken:(NSString *)leToken {
    NSMutableURLRequest *urlRequest = [self URLRequestForPath:path];
    [urlRequest setValue:leToken forHTTPHeaderField:@"AUTHORIZATION"];
    return urlRequest;
}

- (RACSubscribable *)getToken {
    NSString *path = [NSString stringWithFormat:@"/users/%@/tokens", endpoint.email];
    NSMutableURLRequest *urlRequest = [self URLRequestForPath:path];
    urlRequest.HTTPMethod = @"POST";
    urlRequest.HTTPBody = [[NSDictionary dictionaryWithObject:endpoint.password forKey:@"password"] JSONDataRepresentation];
        
    return [[SMWebRequest requestSubscribableWithURLRequest:urlRequest dataParser:JsonParser] select:^ id (id r) {
        return ((NSDictionary *)r)[@"token"];
    }];
}

- (RACSubscribable *)getAuthenticatedWebRequestForPath:(NSString *)path {
    if (token)
        return [RACSubscribable return:[SMWebRequest requestSubscribableWithURLRequest:[self URLRequestForPath:path withToken:token] dataParser:JsonParser]];
    
    return [[self getToken] select:^ id (id t) {
        self.token = t;
        return [SMWebRequest requestSubscribableWithURLRequest:[self URLRequestForPath:path withToken:t] dataParser:JsonParser];
    }];
}

- (RACSubscribable *)authenticatedRequestForPath:(NSString *)path resultHandler:(id(^)(id))handler {
    return [[self getAuthenticatedWebRequestForPath:path] selectMany:^ id (id request) {
        return [request select:^ id (id result) { return handler(result); }];
    }];
}

- (RACSubscribable *)getApps {
    return [self authenticatedRequestForPath:@"/apps" resultHandler:^ id (id apps) {
        return [(NSArray *)apps map:^ id (id app) {
            return [FoundryApp appWithDictionary:app];
        }];
    }];
}

- (RACSubscribable *)getStatsForAppWithName:(NSString *)name {
    return [self authenticatedRequestForPath:[NSString stringWithFormat:@"/apps/%@/stats", name] resultHandler:^ id (id allStats) {
        return [((NSDictionary *)allStats).allKeys map:^ id (id key) {
            return [FoundryAppInstanceStats instantsStatsWithID:key dictionary:allStats[key]];
        }];
    }];
}

- (RACSubscribable *)getAppWithName:(NSString *)name {
    return [self authenticatedRequestForPath:[NSString stringWithFormat:@"/apps/%@", name] resultHandler:^ id (id app) {
        return [FoundryApp appWithDictionary:app];
    }];
}

@end

@implementation FixtureCloudService

- (RACSubscribable *)getApps {
    return [RACSubscribable return:@[[self getAppWithName:@"fixture_app1"], [self getAppWithName:@"fixture_app2"]]];
}

- (RACSubscribable *)getAppWithName:(NSString *)name {
    FoundryApp *result = [FoundryApp new];
    result.name = name;
    result.uris = @[@"api.coolapp.com"];
    result.instances = 2;
    result.memory = 1024 * 1024;
    result.disk = 1024 * 1024 * 1024;
    result.state = FoundryAppStateStarted;
    return [RACSubscribable return:result];
}

- (RACSubscribable *)getStatsForAppWithName:(NSString *)name {
    FoundryAppInstanceStats *stats0 = [FoundryAppInstanceStats new];
    stats0.ID = @"0";
    stats0.host = @"10.0.0.1";
    stats0.port = 23433;
    stats0.cpu = 100.0;
    stats0.memory = 2 * 1024 * 1024 * 1024 * 1024;
    stats0.disk = 53 * 1024 * 1024 * 1024;
    stats0.uptime = 32492.3;
    
    FoundryAppInstanceStats *stats1 = [FoundryAppInstanceStats new];
    stats1.ID = @"1";
    stats1.host = @"10.0.0.2";
    stats1.port = 23435;
    stats1.cpu = 80.0;
    stats1.memory = 2 * 1024 * 1024 * 1024 * 1024;
    stats1.disk = 53 * 1024 * 1024 * 1024;
    stats1.uptime = 32487.9;
    
    return [RACSubscribable return:@[stats0, stats1]];
}

@end
