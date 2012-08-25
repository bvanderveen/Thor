#import "CloudService.h"
#import "SMWebRequest+RAC.h"
#import "NSObject+JSONDataRepresentation.h"
#import "SBJson.h"

@implementation CloudInfo

@synthesize hostname, email, password;

@end

@implementation FoundryApp

@synthesize name, uris, instances, memory, disk, state;

static NSDictionary *stateDict = nil;

+ (void)initialize {
    stateDict = [NSDictionary dictionaryWithObjectsAndKeys:
                 @"STARTED", [NSNumber numberWithInt:FoundryAppStateStarted],
                 @"STOPPED", [NSNumber numberWithInt:FoundryAppStateStopped],
                 nil];
}

+ (FoundryApp *)appWithDictionary:(NSDictionary *)appDict {
    FoundryApp *app = [FoundryApp new];
    
    app.name = [appDict objectForKey:@"name"];
    app.uris = [appDict objectForKey:@"uris"];
    app.instances = [[appDict objectForKey:@"instances"] intValue];

    NSString *state = [appDict objectForKey:@"state"];

    if (![stateDict.allKeys containsObject:state]) {
        NSLog(@"Got previously unknown state %@", state);
        app.state = FoundryAppStateUnknown;
    }
    else
    app.state = [[stateDict objectForKey:state] intValue];

    NSDictionary *resources = [appDict objectForKey:@"resources"];
    app.memory = [[resources objectForKey:@"memory"] intValue];
    app.disk = [[resources objectForKey:@"disk"] intValue];

    return app;
}

@end

@implementation FoundryAppInstanceStats

@synthesize ID, host, port, cpu, memory, disk, uptime;

@end

@interface FoundryService ()

@property (nonatomic, copy) NSString *token;

@end


static id (^JsonParser)(id) = ^ id (id data) {
    return [((NSData *)data) JSONValue];
};


@implementation FoundryService

@synthesize cloudInfo, token;

- (id)initWithCloudInfo:(CloudInfo *)leCloudInfo {
    if (self = [super init]) {
        self.cloudInfo = leCloudInfo;
    }
    return self;
}

- (NSURL *)URLForPath:(NSString *)path {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", cloudInfo.hostname, path]];
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
    NSString *path = [NSString stringWithFormat:@"/users/%@/tokens", cloudInfo.email];
    NSMutableURLRequest *urlRequest = [self URLRequestForPath:path];
    urlRequest.HTTPMethod = @"POST";
    urlRequest.HTTPBody = [[NSDictionary dictionaryWithObject:cloudInfo.password forKey:@"password"] JSONDataRepresentation];
        
    return [[SMWebRequest requestSubscribableWithURLRequest:urlRequest dataParser:JsonParser] select:^ id (id r) {
        return [((NSDictionary *)r) objectForKey:@"token"];
    }];
}

- (RACSubscribable *)getAuthenticatedWebRequestForPath:(NSString *)path {
    if (token)
        return [RACSubscribable return:[self URLRequestForPath:path withToken:token]];
    
    return [[self getToken] select:^ id (id t) {
        self.token = t;
        return [SMWebRequest requestSubscribableWithURLRequest:[self URLRequestForPath:path withToken:t]dataParser:JsonParser];
    }];
}

- (RACSubscribable *)getApps {
    return [[self getAuthenticatedWebRequestForPath:@"/apps"] selectMany:^ id<RACSubscribable> (id r) {
        return [r select:^id(id apps) {
            return [(NSArray *)apps map:^ id (id app) {
                return [FoundryApp appWithDictionary:app];
            }];
        }];
    }];
}

@end

@implementation FixtureCloudService

- (RACSubscribable *)getApps {
    return [RACSubscribable return:[NSArray arrayWithObjects:[self getAppWithName:@"fixture_app1"], [self getAppWithName:@"fixture_app2"], nil]];
}

- (RACSubscribable *)getAppWithName:(NSString *)name {
    FoundryApp *result = [FoundryApp new];
    result.name = name;
    result.uris = [NSArray arrayWithObject:@"api.coolapp.com"];
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
    
    return [RACSubscribable return:[NSArray arrayWithObjects:stats0, stats1, nil]];
}

@end
