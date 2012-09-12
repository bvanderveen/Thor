#import "FoundryService.h"
#import "SMWebRequest+RAC.h"
#import "NSObject+JSONDataRepresentation.h"
#import "SBJson.h"
#import "SHA1.h"

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
- (RACSubscribable *)getAuthenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    if (token)
        return [RACSubscribable return:[self requestWithMethod:@"GET" path:path headers:@{ @"AUTHORIZATION" : token } body:nil]];
    
    return [[self getToken] select:^ id (id t) {
        self.token = t;
        return [self requestWithMethod:@"GET" path:path headers:@{ @"AUTHORIZATION" : token } body:nil];
    }];
}

- (RACSubscribable *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    return [[self getAuthenticatedRequestWithMethod:method path:path headers:headers body:body] selectMany:^ id<RACSubscribable> (id request) {
        return request;
    }];
}

@end

static NSDictionary *stateDict = nil;

FoundryAppState AppStateFromString(NSString *stateString) {
     if (!stateDict)
         stateDict = @{
            @"STARTED" : [NSNumber numberWithInt:FoundryAppStateStarted],
            @"STOPPED" : [NSNumber numberWithInt:FoundryAppStateStopped]
        };
    
    if (![stateDict.allKeys containsObject:stateString]) {
        NSLog(@"Got previously unknown app state '%@'", stateString);
        return FoundryAppStateUnknown;
    }
    else
        return [stateDict[stateString] intValue];
}

NSString *AppStateStringFromState(FoundryAppState state) {
    switch (state) {
        case FoundryAppStateStarted:
            return @"STARTED";
        case FoundryAppStateStopped:
            return @"STOPPED";
        default:
            return @"???";
    }
}

@implementation FoundryApp

@synthesize name, stagingModel, stagingStack, uris, services, instances, memory, disk, state;

+ (FoundryApp *)appWithDictionary:(NSDictionary *)appDict {
    FoundryApp *app = [FoundryApp new];
    
    app.name = appDict[@"name"];
    app.uris = appDict[@"uris"];
    app.instances = [appDict[@"instances"] intValue];

    NSString *state = appDict[@"state"];
    
    app.state = AppStateFromString(state);

    NSDictionary *resources = appDict[@"resources"];
    app.memory = [resources[@"memory"] intValue];
    app.disk = [resources[@"disk"] intValue];

    return app;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"name" : name,
        @"staging" : @{
            @"model" : stagingModel,
            @"stack" : stagingStack,
        },
        @"uris" : uris,
        @"instances" : [NSNumber numberWithInteger:instances],
        @"resources" : @{
            @"memory" : [NSNumber numberWithInteger:memory],
            @"disk" : [NSNumber numberWithInteger:disk]
        },
        @"state" : AppStateStringFromState(state),
        @"services" : services,
        @"env" : @[],
        @"meta" : @{
            @"debug" : @NO
        }
    };
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

@implementation FoundrySlug

@synthesize zipFile, manifiest;

@end

BOOL URLIsDirectory(NSURL *url) {
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
    
    if (error)
        NSLog(@"Error: %@", [error localizedDescription]);
    
    return [attributes[NSFileType] isEqual:NSFileTypeDirectory];
}

NSString *StripBasePath(NSURL *baseUrl, NSURL *url) {
    return [url.path stringByReplacingOccurrencesOfString:baseUrl.path withString:@""];
}

NSNumber *SizeOfFile(NSURL *url) {
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
    
    if (error)
        NSLog(@"Error: %@", [error localizedDescription]);
    
    return attributes[NSFileSize];
}

NSArray *GetItemsOnPath(NSURL *path) {
    NSMutableArray *result = [NSMutableArray array];
    path = [path URLByResolvingSymlinksInPath];
    id i = nil;
    for (id u in [[NSFileManager defaultManager] enumeratorAtURL:path includingPropertiesForKeys:nil options:0 errorHandler:nil]) {
        NSURL *url = [u URLByResolvingSymlinksInPath];
        [result addObject:url];
    }
    
    return result;
}

NSArray *CreateSlugManifestFromPath(NSURL *path) {
    return [[GetItemsOnPath(path) filter:^BOOL(id url) {
        return !URLIsDirectory(url);
    }] map:^ id (id f) {
        return @{
        @"fn" : StripBasePath(path, f),
        @"size": SizeOfFile(f),
        @"sha1": CalculateSHA1OfFileAtPath(f)
        };
    }];
}

NSURL *CreateSlugFromManifest(NSArray *manifest, NSURL *basePath) {
    NSURL *path = [NSURL fileURLWithPath:[NSString pathWithComponents:@[NSTemporaryDirectory(), @"ThorSlug.zip"]]];
    
    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/bin/zip";
    task.currentDirectoryPath = basePath.path;
    task.arguments = [@[path.path] concat:[manifest map:^id(id f) {
        return [f[@"fn"] substringWithRange:NSMakeRange(1, [f[@"fn"] length] - 1)];
    }]];
    
    [task launch];
    
    [task waitUntilExit];
    return path;
}

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
