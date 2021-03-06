#import "FoundryClient.h"
#import "Sequence.h"
#import "SMWebRequest+RAC.h"
#import "NSObject+JSONDataRepresentation.h"
#import "SBJson.h"
#import "SHA1.h"
#import "NSOutputStream+Writing.h"
#import <ReactiveCocoa/EXTScope.h>
#import "RACSignal+Extensions.h"
#import "Packaging.h"

NSString *FoundryClientErrorDomain = @"FoundryClientErrorDomain";
NSInteger JsonParseError = 123;

static id (^JsonParser)(id) = ^ id (id d) {
    NSData *data = (NSData *)d;
    
    if (!data.length)
        return nil;
    
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    id result = [parser objectWithData:data];
    
    if (!result) {
        NSLog(@"-JSONValue failed. Error is: %@", parser.error);
        return [NSError errorWithDomain:FoundryClientErrorDomain code:JsonParseError userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"-JSONValue failed. Error is: %@", parser.error] }];
    }
    
    return result;
};

@implementation RestEndpoint

- (RACSignal *)requestSignalWithURLRequest:(NSURLRequest *)urlRequest {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        return [[SMWebRequest requestSignalWithURLRequest:urlRequest dataParser:JsonParser] subscribeNext:^(id x) {
            if ([x isKindOfClass:[NSError class]]) {
                [subscriber sendError:x];
            }
            else {
                [subscriber sendNext:x];
            }
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } completed:^{
            [subscriber sendCompleted];
        }];
    }];
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

@property (nonatomic, strong) RACConnectableSignal *tokenSignal;
@property (nonatomic, strong) RestEndpoint *endpoint;

@end

@interface NSURLRequest (Signing)

@property (readonly) BOOL isSignedWithToken;

@end

@implementation NSURLRequest (Signing)

+ (NSURLRequest *)requestWithHost:(NSURL *)hostURL method:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    assert(hostURL);
    assert(method);
    assert(path);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", [hostURL scheme], [hostURL host], path]];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:6];
    urlRequest.HTTPMethod = method;
    urlRequest.AllHTTPHeaderFields = headers;
    
    if ([body isKindOfClass:[NSInputStream class]]) {
        urlRequest.HTTPBodyStream = (NSInputStream *)body;
    }
    else {
        urlRequest.HTTPBody = [body JSONDataRepresentation];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    
    return urlRequest;
}

+ (NSURLRequest *)tokenRequestWithHost:(NSURL *)hostURL email:(NSString *)email password:(NSString *)password {
    assert(email && email.length);
    assert(password);
    
    NSString *path = [NSString stringWithFormat:@"/users/%@/tokens", email];
    NSDictionary *body = [NSDictionary dictionaryWithObject:password forKey:@"password"];
    return [self requestWithHost:hostURL method:@"POST" path:path headers:nil body:body];
}

- (BOOL)isSignedWithToken {
    return [self valueForHTTPHeaderField:@"AUTHORIZATION"] != nil;
}

- (NSURLRequest *)signedRequestWithToken:(NSString *)token {
    NSMutableURLRequest *result = [self mutableCopy];
    [result setValue:token forHTTPHeaderField:@"AUTHORIZATION"];
    return result;
}

@end

@implementation FoundryEndpoint

@synthesize hostURL, email, password, tokenSignal, endpoint;

- (id)init {
    if (self = [super init]) {
        self.endpoint = [[RestEndpoint alloc] init];
        
        @weakify(self);
        self.tokenSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            @strongify(self);
            if (!self.email || !self.password) {
                [self sendInvalidCredentialsError:subscriber];
                return nil;
            }
        
            return [[self.endpoint requestSignalWithURLRequest:[NSURLRequest tokenRequestWithHost:self.hostURL email:self.email password:self.password]] subscribeNext:^(id x) {
                [subscriber sendNext:x];
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
                                             
        }] multicast:[RACReplaySubject subject]];
    }
    return self;
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%@%@%@", hostURL, email, password] hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[FoundryEndpoint class]])
        return NO;
    
    FoundryEndpoint *other = (FoundryEndpoint *)object;
    return
        [other.hostURL isEqual:self.hostURL] &&
        [other.email isEqual:self.email] &&
        [other.password isEqual:self.password];
}

- (id)copyWithZone:(NSZone *)zone {
    FoundryEndpoint *result = [[FoundryEndpoint allocWithZone:zone] init];
    result.hostURL = self.hostURL;
    result.email = self.email;
    result.password = self.password;
    return result;
}

- (void)sendInvalidCredentialsError:(RACSubscriber *)subscriber {
    [subscriber sendError:[FoundryClientError errorWithDomain:FoundryClientErrorDomain code:FoundryClientInvalidCredentials userInfo:nil]];
}

- (RACSignal *)getToken {
    [tokenSignal connect];
    return tokenSignal;
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

- (RACSignal *)requestSignalWithURLRequest:(NSURLRequest *)urlRequest {
    if (urlRequest.isSignedWithToken)
        return [SMWebRequest requestSignalWithURLRequest:urlRequest dataParser:JsonParser];
    
    return [[self getToken] flattenMap:^RACStream *(id token) {
        NSURLRequest *signedRequest = [urlRequest signedRequestWithToken:token[@"token"]];
        return [self requestSignalWithURLRequest:signedRequest];
    }];
}

- (RACSignal *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    return [self requestSignalWithURLRequest:[NSURLRequest requestWithHost:hostURL method:method path:path headers:headers body:body]];
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

BOOL FoundryAppStateIsTransient(FoundryAppState state) {
    return
        state == FoundryAppStateStarting ||
        state == FoundryAppStateStopping;
}

NSString *FoundryAppStateStringFromState(FoundryAppState state) {
    switch (state) {
        case FoundryAppStateStarted:
            return @"Started";
            break;
        case FoundryAppStateStopped:
            return @"Stopped";
            break;
        case FoundryAppStateStarting:
            return @"Starting…";
            break;
        case FoundryAppStateStopping:
            return @"Stopping…";
            break;
        case FoundryAppStateUnknown:
        default:
            return @"Unknown";
            break;
    }
}

NSString *AppStateValueStringFromState(FoundryAppState state) {
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
        app.stagingRuntime = staging[@"stack"];
    else if ([[staging allKeys] containsObject:@"runtime"])
        app.stagingRuntime = staging[@"runtime"];

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
        @"state" : AppStateValueStringFromState(state),
        @"services" : services ? services : [NSNull null],
        //@"env" : @[],
        //@"meta" : @{
        //    @"debug" : @NO
        //}
    };
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<FoundryApp %@>", [self dictionaryRepresentation]];
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

@synthesize ID, host, port, cpu, memory, disk, uptime, state;

+ (FoundryAppInstanceStats *)instantsStatsWithID:(NSString *)lID dictionary:(NSDictionary *)dictionary {
    FoundryAppInstanceStats *result = [FoundryAppInstanceStats new];
    result.ID = lID;
    
    result.state = FoundryAppInstanceStateUnknown;
    
    if ([dictionary[@"state"] isEqual:@"DOWN"]) {
        result.state = FoundryAppInstanceStateDown;
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

BOOL URLIsDirectory(NSURL *url) {
    NSError *error = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
    
    if (error)
        NSLog(@"Error: %@", [error localizedDescription]);
    
    return [attributes[NSFileType] isEqual:NSFileTypeDirectory];
}

NSString *StripBasePath(NSURL *baseUrl, NSURL *url) {
    if ([baseUrl isEqual:url])
        return [url.pathComponents lastObject];
    
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

- (NSString *)description {
    return [NSString stringWithFormat:@"<FoundryService: %@>", [self dictionaryRepresentation]];
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

@synthesize serviceDescription, vendor, version, type;

+ (FoundryServiceInfo *)serviceInfoWithDictionary:(NSDictionary *)dict {
    FoundryServiceInfo *result = [FoundryServiceInfo new];
    result.serviceDescription = dict[@"description"];
    result.vendor = dict[@"vendor"];
    result.version = dict[@"version"];
    result.type = dict[@"type"];
    return result;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<FoundryServiceInfo %@>", @{
        @"description": serviceDescription,
        @"vendor": vendor,
        @"version": version,
        @"type": type
    }];
}

@end

@interface FoundryClient ()

@property (nonatomic, copy) NSString *token;

@end

static NSMutableDictionary *clients;

@implementation FoundryClient

@synthesize endpoint, token;

+ (void)initialize {
    clients = [@{} mutableCopy];
}

+ (FoundryClient *)clientWithEndpoint:(FoundryEndpoint *)endpoint {
    if (![[clients allKeys] containsObject:endpoint])
        clients[endpoint] = [[FoundryClient alloc] initWithEndpoint:endpoint];
    
    return clients[endpoint];
}

- (id)initWithEndpoint:(FoundryEndpoint *)lEndpoint {
    if (self = [super init]) {
        self.endpoint = lEndpoint;
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

- (RACSignal *)ignoreTimeoutErrors:(RACSignal *)signal {
    return [signal catch:^RACSignal *(NSError *error) {
        if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorTimedOut) {
            return [RACSignal return:@YES];
        }
        return [RACSignal error:error];
    }];
}

- (RACSignal *)createApp:(FoundryApp *)app {
    return [self ignoreTimeoutErrors:[endpoint authenticatedRequestWithMethod:@"POST" path:@"/apps" headers:nil body:[app dictionaryRepresentation]]];
}

- (RACSignal *)updateApp:(FoundryApp *)app {
    return [self ignoreTimeoutErrors:[endpoint authenticatedRequestWithMethod:@"PUT" path:[NSString stringWithFormat:@"/apps/%@", app.name] headers:nil body:[app dictionaryRepresentation]]];
}


- (RACSignal *)updateApp:(FoundryApp *)app withState:(FoundryAppState)state {
    assert(state == FoundryAppStateStarted || state == FoundryAppStateStopped);
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        if (state == FoundryAppStateStarted)
            app.state = FoundryAppStateStarting;
        
        if (state == FoundryAppStateStopped)
            app.state = FoundryAppStateStopping;
        
        return [[[self getAppWithName:app.name] continueAfter:^RACSignal *(id x) {
            FoundryApp *latestApp = (FoundryApp *)x;
            latestApp.state = state;
            return [[self updateApp:latestApp] doCompleted:^{
                app.state = state;
            }];
        }] subscribe:subscriber];
    }];
}

- (RACSignal *)updateApp:(FoundryApp *)app byAddingServiceNamed:(NSString *)name {
    return [[self getAppWithName:app.name] continueAfter:^RACSignal *(id x) {
        FoundryApp *latestApp = (FoundryApp *)x;
        if (![latestApp.services containsObject:name])
            latestApp.services = [latestApp.services arrayByAddingObject:name];
        return [self updateApp:latestApp];
    }];
}

- (RACSignal *)updateApp:(FoundryApp *)app byRemovingServiceNamed:(NSString *)name {
    return [[self getAppWithName:app.name] continueAfter:^RACSignal *(id x) {
        FoundryApp *latestApp = (FoundryApp *)x;
        latestApp.services = [latestApp.services filter:^BOOL(id n) {
            return ![n isEqual:name];
        }];
        return [self updateApp:latestApp];
    }];
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

- (RACSignal *)pushAppWithName:(NSString *)name fromLocalPath:(NSString *)localPath packaging:(id<Packaging>)packaging {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *archiveFileURL = packaging.archiveFileURL;
        NSURL *explodeDirectoryURL = packaging.explodeDirectoryURL;
        NSURL *messageFileURL = packaging.messageFileURL;
        
        [archiveFileURL removeItem];
        [explodeDirectoryURL removeItem];
        [messageFileURL removeItem];
        
        NSURL *rootURL = [NSURL fileURLWithPath:localPath];
        NSURL *resolved = [packaging resolveURL:rootURL];
        
        BOOL shouldUnpack = [packaging shouldUnpackURL:resolved];
        
        if (shouldUnpack) {
            [packaging unarchive:resolved toURL:explodeDirectoryURL];
        }
        else if (resolved && !resolved.isDirectory) {
            [[NSFileManager defaultManager] copyItemAtURL:resolved toURL:explodeDirectoryURL error:nil];
        }
        else {
            NSArray *includedFiles = [packaging includedFilesInDirectory:resolved];
            [packaging copyFiles:includedFiles inDirectory:resolved toDirectory:explodeDirectoryURL];
        }
        
        [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageBuildingManifest]];
        NSArray *archiveFiles = [packaging includedFilesInDirectory:explodeDirectoryURL];
        
        [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageCompressingFiles]];
        [packaging archiveFiles:archiveFiles inDirectory:explodeDirectoryURL archiveURL:archiveFileURL];
        
        __block BOOL deletedTempFiles = NO;
        
        void (^deleteTempFiles)() = ^ {
            if (deletedTempFiles) return;
            deletedTempFiles = YES;
            NSError *error = nil;
            
            [[NSFileManager defaultManager] removeItemAtURL:archiveFileURL error:&error];
            [[NSFileManager defaultManager] removeItemAtURL:explodeDirectoryURL error:&error];
            [[NSFileManager defaultManager] removeItemAtURL:messageFileURL error:&error];
        };
        
        [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageWritingPackage]];
        
        id manifest = [packaging manifestForFiles:archiveFiles inDirectory:explodeDirectoryURL];
        
        NSString *boundary = @"HelloFromThorMessageBoundaryTokenThing";
        [packaging writeMultipartMessage:messageFileURL withManifest:manifest archive:archiveFileURL boundary:boundary];
        
        [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageUploadingPackage]];
        
        NSNumber *contentLength = messageFileURL ? messageFileURL.fileSize : @0;
        
        NSInputStream *body = messageFileURL ? [NSInputStream inputStreamWithFileAtPath:messageFileURL.path] : nil;
        
        RACSignal *upload = [endpoint authenticatedRequestWithMethod:@"POST" path:[NSString stringWithFormat:@"/apps/%@/application", name] headers:@{
                                   @"Content-Type": [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary],
                                   @"Content-Length": [contentLength stringValue],
                                    } body:body];
        
        RACDisposable *inner = [upload subscribeNext:^(id x) {
            [subscriber sendNext:[NSNumber numberWithInt:FoundryPushStageFinished]];
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } completed:^{
            deleteTempFiles();
            [subscriber sendCompleted];
        }];
        
        return [RACDisposable disposableWithBlock:^ {
            deleteTempFiles();
            [inner dispose];
        }];
    }];
}

@end
