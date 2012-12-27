#import "FoundryClient.h"
#import "Sequence.h"
#import "SMWebRequest+RAC.h"
#import "NSObject+JSONDataRepresentation.h"
#import "SBJson.h"
#import "SHA1.h"
#import "NSOutputStream+Writing.h"

NSString *FoundryClientErrorDomain = @"FoundryClientErrorDomain";

static id (^JsonParser)(id) = ^ id (id d) {
    NSData *data = (NSData *)d;
    return data.length ? [data JSONValue] : nil;
};

@implementation RestEndpoint

- (RACSignal *)requestWithHost:(NSString *)hostname method:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@%@", hostname, path]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:6];
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
    
    return [SMWebRequest requestSignalWithURLRequest:urlRequest dataParser:JsonParser];
}

@end

@interface FoundryClientError : NSError

@end

@implementation FoundryClientError

- (NSString *)localizedDescription {
    switch (self.code) {
        case FoundryClientInvalidCredentials:
            return @"Your username and password are invalid. Double check them and try again.";
    }
    return [super localizedDescription];
}

@end

@interface FoundryEndpoint ()

@property (nonatomic, copy) NSString *token;
@property (nonatomic, strong) RestEndpoint *endpoint;

@end

@implementation FoundryEndpoint

@synthesize hostname, email, password, token, endpoint;

- (id)init {
    if (self = [super init]) {
        self.endpoint = [[RestEndpoint alloc] init];
    }
    return self;
}

- (void)sendInvalidCredentialsError:(RACSubscriber *)subscriber {
    [subscriber sendError:[FoundryClientError errorWithDomain:FoundryClientErrorDomain code:FoundryClientInvalidCredentials userInfo:nil]];
}

- (RACSignal *)getToken {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        if (!email || !password)
            [self sendInvalidCredentialsError:subscriber];
        
        NSString *path = [NSString stringWithFormat:@"/users/%@/tokens", email];
        return [[self.endpoint requestWithHost:self.hostname method:@"POST" path:path headers:nil body:[NSDictionary dictionaryWithObject:password forKey:@"password"]] subscribeNext:^(id r) {
            [subscriber sendNext:r];
        } error:^(NSError *error) {
            if ([error.domain isEqual:@"SMWebRequest"]) {
                SMErrorResponse *errorResponse = error.userInfo[SMErrorResponseKey];
                if (errorResponse.response.statusCode == 403)
                    [self sendInvalidCredentialsError:subscriber];
            }
            else [subscriber sendError:error];
        } completed:^{
            [subscriber sendCompleted];
        }];
    }];
}

- (RACSignal *)verifyCredentials {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        return [[self getToken] subscribeNext:^(id x) {
            [subscriber sendNext:[NSNumber numberWithBool:YES]];
        } error:^(NSError *error) {
            if ([error.domain isEqual:FoundryClientErrorDomain] && error.code == FoundryClientInvalidCredentials) {
                [subscriber sendNext:[NSNumber numberWithBool:NO]];
                [subscriber sendCompleted];
            }
            else
                [subscriber sendError:error];
        } completed:^{
            [subscriber sendCompleted];
        }];
    }];
}

// result is signal
- (RACSignal *)getAuthenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    NSMutableDictionary *h = headers ? [headers mutableCopy] : [NSMutableDictionary dictionary];
    
    if (token) {
        h[@"AUTHORIZATION"] = token;
        return [RACSignal return:[self.endpoint requestWithHost:hostname method:method path:path headers:h body:body]];
    }
    
    return [[self getToken] map:^ id (id t) {
        self.token = ((NSDictionary *)t)[@"token"];
        h[@"AUTHORIZATION"] = token;
        return [self.endpoint requestWithHost:hostname method:method path:path headers:h body:body];
    }];
}

- (RACSignal *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    return [[self getAuthenticatedRequestWithMethod:method path:path headers:headers body:body] flattenMap:^ RACSignal * (id request) {
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
            return @"??";
    }
}

NSUInteger FoundryAppMemoryAmountIntegerFromAmount(FoundryAppMemoryAmount amount) {
    switch (amount) {
        case FoundryAppMemoryAmount64:
            return 64;
        case FoundryAppMemoryAmount128:
            return 128;
        case FoundryAppMemoryAmount256:
            return 256;
        case FoundryAppMemoryAmount512:
            return 512;
        case FoundryAppMemoryAmount1024:
            return 1024;
        case FoundryAppMemoryAmount2048:
            return 2048;
        default:
            return -1;
    }
}

FoundryAppMemoryAmount FoundryAppMemoryAmountAmountFromInteger(NSUInteger integer) {
    switch (integer) {
        case 64:
            return FoundryAppMemoryAmount64;
        case 128:
            return FoundryAppMemoryAmount128;
        case 256:
            return FoundryAppMemoryAmount256;
        case 512:
            return FoundryAppMemoryAmount512;
        case 1024:
            return FoundryAppMemoryAmount1024;
        case 2048:
            return FoundryAppMemoryAmount2048;
        default:
            return FoundryAppMemoryAmountUnknown;
    }
}

NSString * FoundryAppMemoryAmountStringFromAmount(FoundryAppMemoryAmount amount) {
    switch (amount) {
        case FoundryAppMemoryAmount64:
            return @"64MB";
        case FoundryAppMemoryAmount128:
            return @"128MB";
        case FoundryAppMemoryAmount256:
            return @"256MB";
        case FoundryAppMemoryAmount512:
            return @"512MB";
        case FoundryAppMemoryAmount1024:
            return @"1GB";
        case FoundryAppMemoryAmount2048:
            return @"2GB";
        default:
            return @"??";
    }
}

@implementation FoundryApp

@synthesize name, stagingFramework, stagingRuntime, uris, services, instances, memory, disk, state;

+ (FoundryApp *)appWithDictionary:(NSDictionary *)appDict {
    FoundryApp *app = [FoundryApp new];
    
    app.name = appDict[@"name"];
    app.uris = appDict[@"uris"];
    app.services = appDict[@"services"];
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
        @"uris" : uris ? uris : [NSNull null],
        @"instances" : [NSNumber numberWithInteger:instances],
        @"resources" : @{
            @"memory" : [NSNumber numberWithInteger:memory]//,
            //@"disk" : [NSNumber numberWithInteger:disk]
        },
        @"state" : AppStateStringFromState(state),
        @"services" : services ? services : [NSNull null],
        //@"env" : @[],
        //@"meta" : @{
        //    @"debug" : @NO
        //}
    };
}

@end

@interface NSObject (NumberOrNil)

@end

@implementation NSObject (NumberOrNil)

- (NSNumber *)numberOrNil {
    return [self isKindOfClass:[NSNumber class]] ? (NSNumber *)self : nil;
}

@end

@implementation FoundryAppInstanceStats

@synthesize ID, host, port, cpu, memory, disk, uptime;

+ (FoundryAppInstanceStats *)instantsStatsWithID:(NSString *)lID dictionary:(NSDictionary *)dictionary {
    FoundryAppInstanceStats *result = [FoundryAppInstanceStats new];
    result.ID = lID;
    
    if ([dictionary[@"state"] isEqual:@"DOWN"]) {
        NSLog(@"Got a down instance.");
        result.isDown = YES;
        return result;
    }
    
    NSDictionary *statsDict = dictionary[@"stats"];
    
    result.host = statsDict[@"host"];
    result.port = [[statsDict[@"port"] numberOrNil] intValue];
    result.uptime = [[statsDict[@"uptime"] numberOrNil] floatValue];
    
    NSDictionary *usageDict = statsDict[@"usage"];
    
    result.cpu = [[usageDict[@"cpu"] numberOrNil] floatValue];
    result.memory = [[usageDict[@"mem"] numberOrNil] floatValue];
    result.disk = [[usageDict[@"disk"] numberOrNil] intValue];
 
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

NSString *FoundryPushStageString(FoundryPushStage stage) {
    switch (stage) {
        case FoundryPushStageBuildingManifest:
            return @"Building manifest…";
        case FoundryPushStageCompressingFiles:
            return @"Compressing files…";
        case FoundryPushStageWritingPackage:
            return @"Writing slug…";
        case FoundryPushStageUploadingPackage:
            return @"Uploading…";
        case FoundryPushStageFinished:
            return @"Done.";
        default:
            return @"";
    }
}

@implementation SlugService

- (id)createManifestFromPath:(NSURL *)rootURL {
    return [[GetItemsOnPath(rootURL) filter:^BOOL(id url) {
        return !URLIsDirectory(url);
    }] map:^ id (id f) {
        return @{
        @"fn" : StripBasePath(rootURL, f),
        @"size": SizeOfFile(f),
        @"sha1": CalculateSHA1OfFileAtPath(f)
        };
    }];
}

- (NSURL *)createSlugFromManifest:(id)manifest path:(NSURL *)rootURL {
    
    NSString *slugPath = [NSString pathWithComponents:@[NSTemporaryDirectory(), @"ThorSlug.zip"]];
    [[NSFileManager defaultManager] removeItemAtPath:slugPath error:nil];
    NSURL *path = [NSURL fileURLWithPath:slugPath];
    
    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/bin/zip";
    task.currentDirectoryPath = rootURL.path;
    task.arguments = [@[path.path] concat:[manifest map:^id(id f) {
        return f[@"fn"];
    }]];
    
    [task launch];
    [task waitUntilExit];
    return path;
}

- (BOOL)createMultipartMessageFromManifest:(id)manifest slug:(NSURL *)slug outMessagePath:(NSString **)outMessagePath outContentLength:(NSNumber **)outContentLength outBoundary:(NSString **)outBoundary error:(NSError **)error {
    *outBoundary = @"BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL";
    
    *outMessagePath = [NSString pathWithComponents:@[NSTemporaryDirectory(), @"ThorMultipartMessageBuffer"]];
    NSOutputStream *tempFile = [NSOutputStream outputStreamToFileAtPath:*outMessagePath append:NO];
    
    [tempFile open];
    
    [tempFile writeString:[NSString stringWithFormat:@"--%@\r\n", *outBoundary]];
    [tempFile writeString:@"Content-Disposition: form-data; name=\"resources\"\r\n\r\n"];
    [tempFile writeData:[manifest JSONDataRepresentation]];
    [tempFile writeString:[NSString stringWithFormat:@"\r\n--%@\r\n", *outBoundary]];
    [tempFile writeString:@"Content-Disposition: form-data; name=\"application\"\r\n"];
    [tempFile writeString:@"Content-Type: application/zip\r\n\r\n"];
    
    NSInputStream *slugFile = [NSInputStream inputStreamWithURL:slug];
    [slugFile open];
    
    [tempFile writeStream:slugFile];
    [slugFile close];
    
    [tempFile writeString:[NSString stringWithFormat:@"\r\n--%@--\r\n", *outBoundary]];
    
    [tempFile close];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:*outMessagePath error:error];
    
    if (!attributes) {
        return NO;
    }
    
    *outContentLength = (NSNumber *)attributes[NSFileSize];
    return YES;
}

@end

@implementation FoundryService

@synthesize name, vendor, version, type;

+ (FoundryService *)serviceWithDictionary:(NSDictionary *)dict {
    FoundryService *result = [FoundryService new];
    result.name = dict[@"name"];
    result.vendor = dict[@"vendor"];
    result.version = dict[@"version"];
    result.type = dict[@"type"];
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

@synthesize description, vendor, version, type;

+ (FoundryServiceInfo *)serviceInfoWithDictionary:(NSDictionary *)dict {
    FoundryServiceInfo *result = [FoundryServiceInfo new];
    result.description = dict[@"description"];
    result.vendor = dict[@"vendor"];
    result.version = dict[@"version"];
    result.type = dict[@"type"];
    return result;
}

@end

@interface FoundryClient ()

@property (nonatomic, copy) NSString *token;
@property (nonatomic, strong) SlugService *slugService;

@end

@implementation FoundryClient

@synthesize endpoint, token, slugService;

- (id)initWithEndpoint:(FoundryEndpoint *)lEndpoint {
    if (self = [super init]) {
        self.endpoint = lEndpoint;
        self.slugService = [[SlugService alloc] init];
    }
    return self;
}

- (RACSignal *)getApps {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:@"/apps" headers:nil body:nil] map:^id(id apps) {
        return [(NSArray *)apps map:^ id (id app) {
            return [FoundryApp appWithDictionary:app];
        }];
    }];
}

- (RACSignal *)getStatsForAppWithName:(NSString *)name {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:[NSString stringWithFormat:@"/apps/%@/stats", name] headers:nil body:nil] map:^id(id allStats) {
        return [((NSDictionary *)allStats).allKeys map:^ id (id key) {
            return [FoundryAppInstanceStats instantsStatsWithID:key dictionary:allStats[key]];
        }];
    }];
}

- (RACSignal *)getAppWithName:(NSString *)name {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:[NSString stringWithFormat:@"/apps/%@", name] headers:nil body:nil] map:^id(id app) {
        return [FoundryApp appWithDictionary:app];
    }];
}

- (RACSignal *)createApp:(FoundryApp *)app {
    return [endpoint authenticatedRequestWithMethod:@"POST" path:@"/apps" headers:nil body:[app dictionaryRepresentation]];
}

- (RACSignal *)updateApp:(FoundryApp *)app {
    return [endpoint authenticatedRequestWithMethod:@"PUT" path:[NSString stringWithFormat:@"/apps/%@", app.name] headers:nil body:[app dictionaryRepresentation]];
}

- (RACSignal *)deleteAppWithName:(NSString *)name {
    return [endpoint authenticatedRequestWithMethod:@"DELETE" path:[NSString stringWithFormat:@"/apps/%@", name] headers:nil body:nil];
}

- (RACSignal *)getServicesInfo {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:@"/info/services" headers:nil body:nil] map:^id(id s) {
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

- (RACSignal *)getServices {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:@"/services" headers:nil body:nil] map:^id(id services) {
        return [(NSArray *)services map:^ id (id service) {
            return [FoundryService serviceWithDictionary:service];
        }];
    }];
}

- (RACSignal *)getServiceWithName:(NSString *)name {
    return [[endpoint authenticatedRequestWithMethod:@"GET" path:[NSString stringWithFormat:@"/services/%@", name] headers:nil body:nil] map:^id(id service) {
        return [FoundryService serviceWithDictionary:service];
    }];
}

- (RACSignal *)createService:(FoundryService *)service {
    return [endpoint authenticatedRequestWithMethod:@"POST" path:@"/services" headers:nil body:[service dictionaryRepresentation]];
}

- (RACSignal *)deleteServiceWithName:(NSString *)name {
    return [endpoint authenticatedRequestWithMethod:@"DELETE" path:[NSString stringWithFormat:@"/services/%@", name] headers:nil body:nil];
}

- (RACSignal *)pushAppWithName:(NSString *)name fromLocalPath:(NSString *)localPath {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *rootURL = [NSURL fileURLWithPath:localPath];
        
        [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageBuildingManifest]];
        id manifest = [slugService createManifestFromPath:rootURL];
        
        [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageCompressingFiles]];
        NSURL *slug = [slugService createSlugFromManifest:manifest path:rootURL];
        
        NSString *messagePath, *boundary;
        NSNumber *contentLength;
        NSError *error;
        
        __block BOOL deletedTempFile = NO;
        
        void (^deleteTempFile)() = ^ {
            if (deletedTempFile) return;
            deletedTempFile = YES;
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:messagePath error:&error];
        };
        
        [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageWritingPackage]];
        
        if (![slugService createMultipartMessageFromManifest:manifest slug:slug outMessagePath:&messagePath outContentLength:&contentLength outBoundary:&boundary error:&error]) {
            deleteTempFile();
            [subscriber sendError:error];
            return nil;
        }
        
        [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageUploadingPackage]];
        
        RACSignal *upload = [endpoint authenticatedRequestWithMethod:@"PUT" path:[NSString stringWithFormat:@"/apps/%@/application", name] headers:@{
                                   @"Content-Type": [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary],
                                   @"Content-Length": [contentLength stringValue],
                                    } body:[NSInputStream inputStreamWithFileAtPath:messagePath]];
        
        RACDisposable *inner = [upload subscribeNext:^(id x) {
            [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageFinished]];
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
