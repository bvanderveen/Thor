#import "FoundryClient.h"
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
    
    NSDictionary *staging = appDict[@"staging"];
    
    if ([[staging allKeys] containsObject:@"model"])
        app.stagingFramework = staging[@"model"];
    else if ([[staging allKeys] containsObject:@"framework"])
        app.stagingFramework = staging[@"framework"];
    
    if ([[staging allKeys] containsObject:@"stack"])
        app.stagingFramework = staging[@"stack"];
    else if ([[staging allKeys] containsObject:@"runtime"])
        app.stagingFramework = staging[@"runtime"];

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
    for (id u in [[NSFileManager defaultManager] enumeratorAtURL:path includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil]) {
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

NSURL *ExtractZipFile(NSURL *zipFilePath) {
    NSString *tempExtractionPath = [NSString pathWithComponents:@[NSTemporaryDirectory(), @"ThorFrameworkDetectionTemp"]];
    [[NSFileManager defaultManager] removeItemAtPath:tempExtractionPath error:nil];
    NSURL *path = [NSURL fileURLWithPath:tempExtractionPath];
    
    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/bin/unzip";
    task.arguments = @[ zipFilePath.path, @"-d", tempExtractionPath ];
    [task launch];
    [task waitUntilExit];
    
    return path;
}

BOOL StringEndsWithString(NSString *string, NSString *suffix) {
    return string.length >= suffix.length && [[string substringFromIndex:string.length - suffix.length] isEqual:suffix];
}

BOOL StringStartsWithString(NSString *string, NSString *prefix) {
    return string.length >= prefix.length && [[string substringToIndex:prefix.length] isEqual:prefix];
}

BOOL IsJarNamed(NSString *string, NSString *jarName) {
    return
        StringStartsWithString(string, [NSString stringWithFormat:@"WEB-INF/lib/%@", jarName]) &&
        StringEndsWithString(string, @".jar");
}

NSString *DetectFrameworkInArchive(NSURL *warURL) {
    NSURL *tempDir = ExtractZipFile(warURL);
    
    NSString *result = DetectFrameworkFromPath(tempDir);
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:tempDir.path error:&error];
    
    return result;
}

NSString *DetectFrameworkFromPath(NSURL *rootURL) {
    if (StringEndsWithString(rootURL.path, @".war") ||
        StringEndsWithString(rootURL.path, @".zip"))
        return DetectFrameworkInArchive(rootURL);
    
    NSArray *items = [[GetItemsOnPath(rootURL) filter:^BOOL(id url) {
        return !URLIsDirectory(url);
    }] map:^ id (id i) {
        return StripBasePath(rootURL, i);
    }];
    
    if ([items containsObject:@"config/environment.rb"])
        return @"rails";
    
    if ([items containsObject:@"config.ru"])
        return @"rack";
    
    if ([items containsObject:@"server.js"] ||
        [items containsObject:@"main.js"] ||
        [items containsObject:@"app.js"] ||
        [items containsObject:@"index.js"])
        return @"node";
    
    if ([items containsObject:@"manage.py"] && [items containsObject:@"settings.py"])
        return @"django";
    
    if ([items any:^ BOOL (id i) { return StringEndsWithString(i, @".php"); }])
        return @"php";
    
    if ([items containsObject:@"wsgi.py"])
        return @"wsgi";
    
    if ([items containsObject:@"web.config"])
        return @"dotnet";
    
    if (
        [items any:^BOOL(id i) {
            return StringStartsWithString(i, @"releases/") && StringEndsWithString(i, @".rel");
        }] &&
        [items any:^BOOL(id i) {
        return StringStartsWithString(i, @"releases/") && StringEndsWithString(i, @".boot");
    }])
        return @"otp_rebar";
        
    
    if ([items containsObject:@"WEB-INF/web.xml"]) {
        if ([items any:^BOOL(id i) { return IsJarNamed(i, @"grails-web"); }])
            return @"grails";
        
        if ([items any:^BOOL(id i) { return IsJarNamed(i, @"lift-webkit"); }])
            return @"lift";
        
        if ([items any:^BOOL(id i) { return IsJarNamed(i, @"spring-core"); }])
            return @"spring";
        
        if ([items any:^BOOL(id i) { return IsJarNamed(i, @"org.springframework.core"); }])
            return @"spring";
        
        if ([items any:^BOOL(id i) {
            return StringStartsWithString(i, @"WEB-INF/classes/org/springframework");
        }])
            return @"spring";
        
        return @"java_web";
    }
    
    if ([items any:^BOOL(id i) {
        return StringStartsWithString(i, @"lib/play") && StringEndsWithString(i, @".jar");
    }])
        return @"play";
    
    NSArray *zips = [items filter:^ BOOL (id i) { return StringEndsWithString(i, @".zip"); }];
    
    if (zips.count) {
        NSString *zipPath = zips[0];
        NSURL *zipURL = [NSURL URLWithString:[NSString pathWithComponents:@[ rootURL.path, zipPath ]]];
        return DetectFrameworkInArchive(zipURL);
    }
    
    NSArray *wars = [items filter:^ BOOL (id i) { return StringEndsWithString(i, @".war"); }];
    
    if (wars.count) {
        NSString *warPath = wars[0];
        NSURL *warURL = [NSURL URLWithString:[NSString pathWithComponents:@[ rootURL.path, warPath ]]];
        return DetectFrameworkInArchive(warURL);
    }
    
    return @"standalone";
}

@implementation FoundryService

@synthesize name, vendor, version;

+ (FoundryService *)serviceWithDictionary:(NSDictionary *)dict {
    FoundryService *result = [FoundryService new];
    result.name = dict[@"name"];
    result.vendor = dict[@"vendor"];
    result.version = dict[@"version"];
    return result;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"name" : name,
        @"vendor": vendor,
        @"version" : version,
        @"tier" : @"free"
    };
}

@end

@implementation FoundryServiceInfo

@synthesize description, vendor, version;

+ (FoundryServiceInfo *)serviceInfoWithDictionary:(NSDictionary *)dict {
    FoundryServiceInfo *result = [FoundryServiceInfo new];
    result.description = dict[@"description"];
    result.vendor = dict[@"vendor"];
    result.version = dict[@"version"];
    return result;
}

@end

@interface FoundryClient ()

@property (nonatomic, copy) NSString *token;

@end

@implementation FoundryClient

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

- (RACSubscribable *)updateApp:(FoundryApp *)app {
    return [endpoint authenticatedRequestWithMethod:@"PUT" path:[NSString stringWithFormat:@"/apps/%@", app.name] headers:nil body:[app dictionaryRepresentation]];
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
- (RACSubscribable *)getServicesInfo {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:@"/info/services" headers:nil body:nil] select:^id(id s) {
        NSDictionary *categories = (NSDictionary *)s;
        return [[categories allKeys] reduce:^id(id acc0, id i) {
            return [acc0 concat:[[categories[i] allKeys] reduce:^id(id acc1, id j) {
                return [acc1 concat:[[categories[i][j] allKeys] reduce:^id (id acc2, id k) {
                    return [(NSArray *)acc2 concat:@[[FoundryServiceInfo serviceInfoWithDictionary:categories[i][j][k]]]];
                } seed:@[]]];
            } seed:@[]]];
        } seed:@[]];
    }];
}

- (RACSubscribable *)getServices {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:@"/services" headers:nil body:nil] select:^id(id services) {
        return [(NSArray *)services map:^ id (id service) {
            return [FoundryService serviceWithDictionary:service];
        }];
    }];
}

- (RACSubscribable *)createService:(FoundryService *)service {
    return [endpoint authenticatedRequestWithMethod:@"POST" path:@"/services" headers:nil body:[service dictionaryRepresentation]];
}

- (RACSubscribable *)deleteServiceWithName:(NSString *)name {
    return [endpoint authenticatedRequestWithMethod:@"DELETE" path:[NSString stringWithFormat:@"/services/%@", name] headers:nil body:nil];
}

@end
