#import "FoundryService.h"
#import "Sequence.h"
#import "SMWebRequest+RAC.h"
#import "NSObject+JSONDataRepresentation.h"
#import "SBJson.h"
#import "SHA1.h"
#import "NSOutputStream+Writing.h"

static id (^JsonParser)(id) = ^ id (id d) {
    NSData *data = (NSData *)d;
    return data.length ? [data JSONValue] : nil;
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
    
    if ([body isKindOfClass:[NSInputStream class]]) {
        urlRequest.HTTPBodyStream = (NSInputStream *)body;
    }
    else {
        urlRequest.HTTPBody = [body JSONDataRepresentation];
        NSMutableDictionary *newHeaders = headers ? [headers mutableCopy] : [NSMutableDictionary dictionary];
        newHeaders[@"Content-Type"] = @"application/json";
        headers = newHeaders;
    }
    
    urlRequest.AllHTTPHeaderFields = headers;
    
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
    NSMutableDictionary *h = headers ? [headers mutableCopy] : [NSMutableDictionary dictionary];
    
    
    if (token) {
        h[@"AUTHORIZATION"] = token;
        return [RACSubscribable return:[self requestWithMethod:method path:path headers:h body:body]];
    }
    
    return [[self getToken] select:^ id (id t) {
        self.token = t;
        h[@"AUTHORIZATION"] = token;
        return [self requestWithMethod:method path:path headers:h body:body];
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

@synthesize name, stagingFramework, stagingRuntime, uris, services, instances, memory, disk, state;

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
            @"framework" : stagingFramework ? stagingFramework : [NSNull null],
            @"runtime" : stagingRuntime ? stagingRuntime : [NSNull null],
        },
        @"uris" : uris,
        @"instances" : [NSNumber numberWithInteger:instances],
        @"resources" : @{
            @"memory" : [NSNumber numberWithInteger:memory]//,
            //@"disk" : [NSNumber numberWithInteger:disk]
        },
        //@"state" : AppStateStringFromState(state),
        //@"services" : services,
        //@"env" : @[],
        //@"meta" : @{
        //    @"debug" : @NO
        //}
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

BOOL URLIsInGitDirectory(NSURL *url) {
    BOOL result = [url.path rangeOfString:@".git"].location != NSNotFound;
    NSLog(@"URLIsInGitDirectory %@ = %d", url, result);
    return result;
}

NSString *StripBasePath(NSURL *baseUrl, NSURL *url) {
    NSString *stripped = [url.path stringByReplacingOccurrencesOfString:baseUrl.path withString:@""];
    if ([[stripped substringToIndex:1] isEqual:@"/"])
        stripped = [stripped substringFromIndex:1];
    
    return stripped;
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
        return !URLIsDirectory(url) && !URLIsInGitDirectory(url);
    }] map:^ id (id f) {
        return @{
        @"fn" : StripBasePath(path, f),
        @"size": SizeOfFile(f),
        @"sha1": CalculateSHA1OfFileAtPath(f)
        };
    }];
}

NSURL *CreateSlugFromManifest(NSArray *manifest, NSURL *basePath) {
    NSString *slugPath = [NSString pathWithComponents:@[NSTemporaryDirectory(), @"ThorSlug.zip"]];
    [[NSFileManager defaultManager] removeItemAtPath:slugPath error:nil];
    NSURL *path = [NSURL fileURLWithPath:slugPath];
    
    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/bin/zip";
    task.currentDirectoryPath = basePath.path;
    task.arguments = [@[path.path] concat:[manifest map:^id(id f) {
        return f[@"fn"];
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

- (RACSubscribable *)createApp:(FoundryApp *)app {
    return [endpoint authenticatedRequestWithMethod:@"POST" path:@"/apps" headers:nil body:[app dictionaryRepresentation]];
}

- (RACSubscribable *)deleteAppWithName:(NSString *)name {
    return [endpoint authenticatedRequestWithMethod:@"DELETE" path:[NSString stringWithFormat:@"/apps/%@", name] headers:nil body:nil];
}

- (RACSubscribable *)postSlug:(NSURL *)slug manifest:(NSArray *)manifest toAppWithName:(NSString *)name {
    // per thread: http://lists.apple.com/archives/macnetworkprog/2007/May/msg00051.html
    //
    // we're gonna write out the multipart message to a temp file,
    // post a stream over that temp file, then delete it when we're done.
    //
    // not the world's most efficient approach, but should work much more
    // predictably than trying to subclass NSInputStream and dealing
    // with undocumented private API weirdness.
    
    static NSString *boundary = @"BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL";
    
    return [RACSubscribable createSubscribable:^ RACDisposable *(id<RACSubscriber> subscriber) {
        NSString *tempFilePath = [NSString pathWithComponents:@[NSTemporaryDirectory(), @"ThorMultipartMessageBuffer"]];
        NSOutputStream *tempFile = [NSOutputStream outputStreamToFileAtPath:tempFilePath append:NO];
        
        __block BOOL deletedTempFile = NO;
        void (^deleteTempFile)() = ^ {
            if (deletedTempFile) return;
            deletedTempFile = YES;
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:&error];
        };
        
        [tempFile open];
        
        [tempFile writeString:[NSString stringWithFormat:@"--%@\r\n", boundary]];
        [tempFile writeString:@"Content-Disposition: form-data; name=\"resources\"\r\n\r\n"];
        [tempFile writeData:[manifest JSONDataRepresentation]];
        [tempFile writeString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
        [tempFile writeString:@"Content-Disposition: form-data; name=\"application\"\r\n"];
        [tempFile writeString:@"Content-Type: application/zip\r\n\r\n"];
        
        NSInputStream *slugFile = [NSInputStream inputStreamWithURL:slug];
        [slugFile open];

        [tempFile writeStream:slugFile];
        [slugFile close];
        
        [tempFile writeString:[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary]];
        
        [tempFile close];
        
        NSError *error;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:tempFilePath error:&error];
        
        if (error) {
            deleteTempFile();
            [subscriber sendError:error];
            return nil;
        }
        
        NSNumber *contentLength = attributes[NSFileSize];
        
        RACDisposable *inner = [[endpoint authenticatedRequestWithMethod:@"PUT" path:[NSString stringWithFormat:@"/apps/%@/application", name] headers:@{
                                 @"Content-Type": [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary],
                                  @"Content-Length": [contentLength stringValue],
                                  } body:[NSInputStream inputStreamWithFileAtPath:tempFilePath]] subscribeNext:^(id x) {
            [subscriber sendNext:x];
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } completed:^{
            deleteTempFile();
            [subscriber sendCompleted];
        }];
        
        return [RACDisposable disposableWithBlock:^ {
            deleteTempFile();
            [inner dispose];
        }];
    }];
    
}

@end
