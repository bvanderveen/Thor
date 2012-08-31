#import "FoundryService.h"
#import "SMWebRequest+RAC.h"
#import "NSObject+JSONDataRepresentation.h"
#import "SBJson.h"


static id (^JsonParser)(id) = ^ id (id data) {
    return [((NSData *)data) JSONValue];
};

@interface FoundryEndpoint ()

@property (nonatomic, copy) NSString *token;

@end

@implementation FoundryEndpoint

@synthesize hostname, email, password, token;

- (RACSubscribable *)requestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", hostname, path]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    urlRequest.HTTPMethod = method;
    urlRequest.AllHTTPHeaderFields = headers;
    urlRequest.HTTPBody = [body JSONDataRepresentation];
    return [SMWebRequest requestSubscribableWithURLRequest:urlRequest dataParser:JsonParser];
}

- (RACSubscribable *)getToken {
    NSString *path = [NSString stringWithFormat:@"/users/%@/tokens", email];
    return [[self requestWithMethod:@"POST" path:path headers:nil body:[NSDictionary dictionaryWithObject:password forKey:@"password"]] select:^ id (id r) {
        return ((NSDictionary *)r)[@"token"];
    }];
}

// result is subscribable
- (RACSubscribable *)getAuthenticatedRequestForPath:(NSString *)path {
    if (token)
        return [RACSubscribable return:[self requestWithMethod:@"GET" path:path headers:@{ @"AUTHORIZATION" : token } body:nil]];
    
    return [[self getToken] select:^ id (id t) {
        self.token = t;
        return [self requestWithMethod:@"GET" path:path headers:@{ @"AUTHORIZATION" : token } body:nil];
    }];
}

- (RACSubscribable *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    return [[self getAuthenticatedRequestForPath:path] selectMany:^ id (id request) {
        return request;
    }];
}

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

@implementation FoundryService

@synthesize endpoint, token;

- (id)initWithEndpoint:(FoundryEndpoint *)lEndpoint {
    if (self = [super init]) {
        self.endpoint = lEndpoint;
    }
    return self;
}

- (RACSubscribable *)getApps {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:@"/apps" headers:nil body:nil] select:^id(id apps) {
        return [(NSArray *)apps map:^ id (id app) {
            return [FoundryApp appWithDictionary:app];
        }];
    }];
}

- (RACSubscribable *)getStatsForAppWithName:(NSString *)name {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:[NSString stringWithFormat:@"/apps/%@/stats", name] headers:nil body:nil] select:^id(id allStats) {
        return [((NSDictionary *)allStats).allKeys map:^ id (id key) {
            return [FoundryAppInstanceStats instantsStatsWithID:key dictionary:allStats[key]];
        }];
    }];
}

- (RACSubscribable *)getAppWithName:(NSString *)name {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:[NSString stringWithFormat:@"/apps/%@", name] headers:nil body:nil] select:^id(id app) {
        return [FoundryApp appWithDictionary:app];
    }];
}

@end
