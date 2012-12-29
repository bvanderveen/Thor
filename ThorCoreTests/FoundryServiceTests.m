#import "FoundryServiceTests.h"
#import "ThorCore.h"
#import "Sequence.h"
#import "Specta.h"
#define EXP_SHORTHAND
#import "Expecta.h"
#import "SBJson/SBJson.h"

@interface MockEndpoint : NSObject

@property (nonatomic, copy) NSArray *calls, *results;

@end

@implementation MockEndpoint

@synthesize calls, results;

- (id)init {
    if (self = [super init]) {
        self.calls = [NSMutableArray array];
        self.results = [NSMutableArray array];
    }
    return self;
}

- (NSString *)stringFromStream:(NSInputStream *)stream {
    NSMutableString *result = [NSMutableString string];
    
    NSInteger bytesRead = 0;
    NSUInteger bufferSize = 1024 * 20;
    uint8_t buffer[bufferSize];
    
    [stream open];
    while (true) {
        bytesRead = [stream read:&buffer maxLength:bufferSize];
        
        if (bytesRead <= 0)
            break;
        
        [result appendString:[[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding]];
    }
    [stream close];
    
    return [result copy];
}

- (RACSignal *)logCallAndGetResult:(NSDictionary *)call {
    calls = [calls arrayByAddingObject:call];
    
    id resultObject = results.count ? results[0] : nil;
    
    if (results.count) {
        NSMutableArray *newResults = [results mutableCopy];
        [newResults removeObjectAtIndex:0];
        results = newResults;
    }
    
    return [RACSignal return:resultObject];
}

- (RACSignal *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    NSDictionary *call = @{
    @"method" : method ? method : [NSNull null],
    @"path" : path ? path : [NSNull null],
    @"headers" : headers ? headers : [NSNull null],
    @"body" : body ? ([body isKindOfClass:[NSInputStream class]] ? [self stringFromStream:(NSInputStream *)body] : body) : [NSNull null]
    };
    
    return [self logCallAndGetResult:call];
}

- (RACSignal *)requestSignalWithURLRequest:(NSURLRequest *)urlRequest {

    NSString *hostname = urlRequest.URL.host;
    NSString *method = urlRequest.HTTPMethod;
    NSString *path = urlRequest.URL.path;
    NSDictionary *headers = urlRequest.allHTTPHeaderFields;
    id body = [[[NSString alloc] initWithData:urlRequest.HTTPBody encoding:NSUTF8StringEncoding] JSONValue];
    NSDictionary *call = @{
        @"host": hostname,
        @"method" : method ? method : [NSNull null],
        @"path" : path ? path : [NSNull null],
        @"headers" : headers ? headers : [NSNull null],
        @"body" : body ? body : [NSNull null]
    };
    
    
    return [self logCallAndGetResult:call];
}

@end

@interface MockSlugService : NSObject <SlugService>

@end

@implementation MockSlugService

- (id)createManifestFromPath:(NSURL *)rootURL {
    return nil;
}

- (NSURL *)createSlugFromManifest:(id)manifest path:(NSURL *)rootURL {
    return [NSURL URLWithString:@"file:///foo"];
}

- (BOOL)createMultipartMessageFromManifest:(id)manifest slug:(NSURL *)slugFile outMessagePath:(NSString **)outMessagePath outContentLength:(NSNumber **)outContentLength outBoundary:(NSString **)outBoundary error:(NSError **)error {
    *outMessagePath = @"file:///tmp/blah";
    *outBoundary = @"the_boundary";
    *outContentLength = [NSNumber numberWithInt:0];
    return YES;
}

@end

SpecBegin(RestEndpoint)

describe(@"verifyCredentials", ^{
    
    __block MockEndpoint *wrappedEndpoint;
    __block FoundryEndpoint *endpoint;
    
    beforeEach(^ {
        wrappedEndpoint = [[MockEndpoint alloc] init];
        endpoint = [[FoundryEndpoint alloc] init];
        endpoint.hostname = @"cool.com";
        endpoint.email = @"thor@tier3.com";
        endpoint.password = @"passw0rd";
        
        [(id)endpoint setEndpoint:wrappedEndpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[endpoint verifyCredentials] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"host": @"cool.com",
        @"method" : @"POST",
        @"path" : @"/users/thor@tier3.com/tokens",
        @"headers" : @{
            @"Content-Type": @"application/json"
        },
        @"body" : @{ @"password": @"passw0rd" }
        }];
        
        expect(wrappedEndpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse valid token results", ^ {
        wrappedEndpoint.results = @[@{@"token": @"foobs"}];
        
        __block NSNumber *result;
        [[endpoint verifyCredentials] subscribeNext:^(id x) {
            result = (NSNumber *)x;
        }];
        
        expect(result).to.beTruthy();
    });
    
    it(@"should parse invalid token results", ^ {
        wrappedEndpoint.results = @[[NSNull null]];
        
        __block NSNumber *result;
        [[endpoint verifyCredentials] subscribeNext:^(id x) {
            result = (NSNumber *)x;
        }];
        
        expect(result).to.beTruthy();
    });
});

SpecEnd

SpecBegin(FoundryService)

describe(@"getApps", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[client getApps] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"GET",
        @"path" : @"/apps",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse results", ^ {
        endpoint.results = @[ @[
        @{
        @"name" : @"the name",
        @"uris" : @[ @"uri", @"uri2" ],
        @"instances" : @2,
        @"state" : @"STARTED",
        @"resources" : @{
        @"memory" : @2048,
        @"disk" : @4096
        }
        },
        @{
        @"name" : @"the name2",
        @"uris" : @[ @"uri3", @"uri4" ],
        @"instances" : @3,
        @"state" : @"STOPPED",
        @"resources" : @{
        @"memory" : @2049,
        @"disk" : @4097
        }
        }
        ] ];
        
        __block NSArray *result;
        [[client getApps] subscribeNext:^(id x) {
            result = (NSArray *)x;
        }];
        
        expect(result.count).to.equal(2);
        
        FoundryApp *app0 = result[0];
        expect(app0.name).to.equal(@"the name");
        id uris = @[ @"uri", @"uri2" ];
        expect(app0.uris).to.equal(uris);
        expect(app0.instances).to.equal(2);
        expect(app0.state).to.equal(FoundryAppStateStarted);
        expect(app0.memory).to.equal(2048);
        expect(app0.disk).to.equal(4096);
        
        FoundryApp *app1 = result[1];
        
        expect(app1.name).to.equal(@"the name2");
        uris = @[ @"uri3", @"uri4" ];
        expect(app1.uris).to.equal(uris);
        expect(app1.instances).to.equal(3);
        expect(app1.state).to.equal(FoundryAppStateStopped);
        expect(app1.memory).to.equal(2049);
        expect(app1.disk).to.equal(4097);
    });
});

describe(@"getAppWithName", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[client getAppWithName:@"name"] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"GET",
        @"path" : @"/apps/name",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse result", ^ {
        endpoint.results = @[
        @{
        @"name" : @"the name",
        @"uris" : @[ @"uri", @"uri2" ],
        @"instances" : @2,
        @"state" : @"STARTED",
        @"resources" : @{
        @"memory" : @2048,
        @"disk" : @4096
        }
        }];
        
        __block FoundryApp *app;
        
        [[client getAppWithName:@"the name"] subscribeNext:^(id x) {
            app = (FoundryApp *)x;
        }];
        
        expect(app.name).to.equal(@"the name");
        id uris = @[ @"uri", @"uri2" ];
        expect(app.uris).to.equal(uris);
        expect(app.instances).to.equal(2);
        expect(app.state).to.equal(FoundryAppStateStarted);
        expect(app.memory).to.equal(2048);
        expect(app.disk).to.equal(4096);
    });
});

describe(@"getStatsForAppWithName", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[client getStatsForAppWithName:@"name"] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"GET",
        @"path" : @"/apps/name/stats",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse result", ^ {
        endpoint.results = @[ @{
        @"0" : @{
            @"stats" : @{
                @"host" : @"10.0.0.1",
                @"port" : @3300,
                @"uptime": @2300.1,
                @"usage" : @{
                    @"cpu" : @99.1,
                    @"mem" : @2048.3,
                    @"disk": @4096
                }
            }
        }
        }];
        
        __block NSArray *result;
        
        [[client getStatsForAppWithName:@"the name"] subscribeNext:^(id x) {
            result = (NSArray *)x;
        }];
        
        expect(result.count).to.equal(1);
        
        FoundryAppInstanceStats *stats = result[0];
        
        expect(stats.ID).to.equal(@"0");
        expect(stats.host).to.equal(@"10.0.0.1");
        expect(stats.port).to.equal(3300);
        expect(stats.uptime).to.equal(2300.1);
        expect(stats.cpu).to.equal(99.1);
        expect(stats.memory).to.equal(2048.3);
        expect(stats.disk).to.equal(4096);
    });
    
    it(@"should parse result with nulls", ^ {
        endpoint.results = @[ @{
        @"0" : @{
            @"stats" : @{
                @"host" : @"10.0.0.1",
                @"port" : [NSNull null],
                @"uptime": [NSNull null],
                @"usage" : @{
                    @"cpu" : [NSNull null],
                    @"mem" : @2048.3,
                    @"disk": @4096
                }
            }
        }
        }];
        
        __block NSArray *result;
        
        [[client getStatsForAppWithName:@"the name"] subscribeNext:^(id x) {
            result = (NSArray *)x;
        }];
        
        expect(result.count).to.equal(1);
        
        FoundryAppInstanceStats *stats = result[0];
        
        expect(stats.ID).to.equal(@"0");
        expect(stats.host).to.equal(@"10.0.0.1");
        expect(stats.port).to.equal(0);
        expect(stats.uptime).to.equal(0);
        expect(stats.cpu).to.equal(0);
        expect(stats.memory).to.equal(2048.3);
        expect(stats.disk).to.equal(4096);
    });
    
    it(@"should parse result with down instances", ^ {
        endpoint.results = @[ @{
        @"0" : @{
            @"since" : @1354230089,
            @"state" : @"DOWN"
        }
        }];
        
        __block NSArray *result;
        
        [[client getStatsForAppWithName:@"the name"] subscribeNext:^(id x) {
            result = (NSArray *)x;
        }];
        
        expect(result.count).to.equal(1);
        
        FoundryAppInstanceStats *stats = result[0];
        
        expect(stats.ID).to.equal(@"0");
        expect(stats.isDown).to.beTruthy();
        expect(stats.host).to.beNil();
        expect(stats.port).to.equal(0);
        expect(stats.uptime).to.equal(0);
        expect(stats.cpu).to.equal(0);
        expect(stats.memory).to.equal(0);
        expect(stats.disk).to.equal(0);
    });
});

describe(@"createApp", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        
        FoundryApp *app = [FoundryApp new];
        
        app.name = @"appname";
        app.stagingFramework = @"rack";
        app.stagingRuntime = @"ruby18";
        app.uris = @[ @"app.foo.bar.com" ];
        app.services = @[];
        app.instances = 3;
        app.memory = 256;
        //app.disk = 512;
        app.state = FoundryAppStateStarted;
        
        [[client createApp:app] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"POST",
        @"path" : @"/apps",
        @"headers" : [NSNull null],
        @"body" : @{
        @"name" : @"appname",
        @"staging" : @{
        @"framework" : @"rack",
        @"runtime" : @"ruby18",
        },
        @"uris" : @[ @"app.foo.bar.com" ],
        @"services" : @[],
        @"instances": @3,
        @"resources" : @{
        @"memory" : @256//,
        //@"disk" : @512
        },
        @"state" : @"STARTED",
        //@"env" : @[],
        //@"meta" : @{
        //@"debug" : @0
        //}
        }
        
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should call endpoint with null framework, runtime, uris, and services", ^ {
        
        FoundryApp *app = [FoundryApp new];
        
        app.name = @"appname";
        app.stagingFramework = nil;
        app.stagingRuntime = nil;
        app.uris = nil;
        app.services = nil;
        app.instances = 3;
        app.memory = 256;
        //app.disk = 512;
        app.state = FoundryAppStateStarted;
        
        [[client createApp:app] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"POST",
        @"path" : @"/apps",
        @"headers" : [NSNull null],
        @"body" : @{
        @"name" : @"appname",
        @"staging" : @{
        @"framework" : [NSNull null],
        @"runtime" : [NSNull null],
        },
        @"uris" : [NSNull null],
        @"services" : [NSNull null],
        @"instances": @3,
        @"resources" : @{
        @"memory" : @256//,
        //@"disk" : @512
        },
        @"state" : @"STARTED",
        //@"env" : @[],
        //@"meta" : @{
        //@"debug" : @0
        //}
        }
        
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
});

describe(@"updateApp", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        
        FoundryApp *app = [FoundryApp new];
        
        app.name = @"appname";
        app.stagingFramework = @"rack";
        app.stagingRuntime = @"ruby18";
        app.uris = @[ @"app.foo.bar.com" ];
        app.services = @[ @"redis", @"postgres" ];
        app.instances = 3;
        app.memory = 256;
        //app.disk = 512;
        app.state = FoundryAppStateStarted;
        
        [[client updateApp:app] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"PUT",
        @"path" : @"/apps/appname",
        @"headers" : [NSNull null],
        @"body" : @{
        @"name" : @"appname",
        @"staging" : @{
        @"framework" : @"rack",
        @"runtime" : @"ruby18",
        },
        @"uris" : @[ @"app.foo.bar.com" ],
        @"services" : @[ @"redis", @"postgres" ],
        @"instances": @3,
        @"resources" : @{
        @"memory" : @256//,
        //@"disk" : @512
        },
        @"state" : @"STARTED",
        //@"env" : @[],
        //@"meta" : @{
        //@"debug" : @0
        //}
        }
        
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should call endpoint with stopped state", ^ {
        
        FoundryApp *app = [FoundryApp new];
        
        app.name = @"appname";
        app.stagingFramework = @"rack";
        app.stagingRuntime = @"ruby18";
        app.uris = @[ @"app.foo.bar.com" ];
        app.services = @[ @"redis", @"postgres" ];
        app.instances = 3;
        app.memory = 256;
        //app.disk = 512;
        app.state = FoundryAppStateStopped;
        
        [[client updateApp:app] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"PUT",
        @"path" : @"/apps/appname",
        @"headers" : [NSNull null],
        @"body" : @{
        @"name" : @"appname",
        @"staging" : @{
        @"framework" : @"rack",
        @"runtime" : @"ruby18",
        },
        @"uris" : @[ @"app.foo.bar.com" ],
        @"services" : @[ @"redis", @"postgres" ],
        @"instances": @3,
        @"resources" : @{
        @"memory" : @256//,
        //@"disk" : @512
        },
        @"state" : @"STOPPED",
        //@"env" : @[],
        //@"meta" : @{
        //@"debug" : @0
        //}
        }
        
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
});

describe(@"deleteAppWithName", ^ {
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[client deleteAppWithName:@"foobard"] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
            @"method" : @"DELETE",
            @"path" : @"/apps/foobard",
            @"headers" : [NSNull null],
            @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
});

describe(@"CreateMultipartMessage", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should write multipart message", ^ {
        NSString *tempFilePath = [NSString pathWithComponents:@[ NSTemporaryDirectory(), @"TestUploadFile.txt" ]];
        NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
        
        [[NSFileManager defaultManager] createFileAtPath:tempFilePath contents:[@"this is some data in a file" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        
        NSArray *manifest = @[ @"a", @"b", @"c" ];
        
        NSString *messagePath, *boundary;
        NSNumber *contentLength;
        NSError *error;
        
        BOOL success = [[[SlugService alloc] init] createMultipartMessageFromManifest:manifest slug:tempFileURL outMessagePath:&messagePath outContentLength:&contentLength outBoundary:&boundary error:&error];
        
        NSString *message = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:messagePath] encoding:NSUTF8StringEncoding];
        
        [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
        
        NSString *expectedMessage = @"--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL\r\n" \
        "Content-Disposition: form-data; name=\"resources\"\r\n\r\n" \
        "[\"a\",\"b\",\"c\"]\r\n" \
        "--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL\r\n" \
        "Content-Disposition: form-data; name=\"application\"\r\n" \
        "Content-Type: application/zip\r\n\r\n" \
        "this is some data in a file\r\n"
        "--BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL--\r\n";
        
        expect(success).to.beTruthy();
        expect(boundary).to.equal(@"BVANDERVEEN_WAS_HERE_AND_IT_WAS_PRETTY_RADICAL");
        expect(message).to.equal(expectedMessage);
    });
});

describe(@"pushAppWithName:localRoot:", ^{
    
    __block MockEndpoint *endpoint;
    __block MockSlugService *slugService;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
        slugService = [MockSlugService new];
        [client performSelector:@selector(setSlugService:) withObject:slugService];
    });
    

    it(@"should send status events", ^ {
        __block NSArray *results = @[];
        __block NSError *error = nil;
        __block BOOL completed = NO;
        
        [[client pushAppWithName:@"" fromLocalPath:@"whatever"] subscribeNext:^(id x) {
            results = [results arrayByAddingObject:x];
        } error:^(NSError *e) {
            error = e;
        } completed:^{
            completed = YES;
        }];
        
        expect(results.count).to.equal(5);
        expect([results[0] intValue]).to.equal(FoundryPushStageBuildingManifest);
        expect([results[1] intValue]).to.equal(FoundryPushStageCompressingFiles);
        expect([results[2] intValue]).to.equal(FoundryPushStageWritingPackage);
        expect([results[3] intValue]).to.equal(FoundryPushStageUploadingPackage);
        expect([results[4] intValue]).to.equal(FoundryPushStageFinished);
        expect(error).to.beNil();
        expect(completed).to.beTruthy();
    });
});

void (^ensureDirectoryForFile)(NSArray *, NSArray *) = ^ void (NSArray *rootPathComponents, NSArray *pathComponents) {
    NSString *directory = [NSString pathWithComponents:[[rootPathComponents concat:pathComponents] take:rootPathComponents.count + pathComponents.count - 1]];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (error) {
        NSLog(@"error: %@", [error localizedDescription]);
        assert(NO);
    }
};

NSSet *(^createFilesAtRoot)(NSArray *, NSArray *) = ^ (NSArray *files, NSArray *root) {
    NSSet *created = [NSSet set];
    for (NSArray *f in files) {
        NSArray *pathComponents = f[0];
        NSString *contents = f[1];
        
        ensureDirectoryForFile(root, pathComponents);
        
        NSString *path = [NSString pathWithComponents:[root arrayByAddingObjectsFromArray:pathComponents]];
        
        created = [created setByAddingObject:@{
            @"name" : [NSString pathWithComponents:pathComponents],
            @"contents": contents
        }];
        
        [[NSFileManager defaultManager] createFileAtPath:path contents:[contents dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    return created;
};

void (^removeCreatedFiles)(NSString *) = ^ (NSString *path) {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
};

describe(@"CreateSlugManifestFromPath", ^ {
    void (^expectToBeIntendedFiles)(NSSet *) = ^ (NSSet *filenames) {
        expect(filenames.count).to.equal(8);
        expect(filenames).to.contain(@"foo");
        expect(filenames).to.contain(@"bar");
        expect(filenames).to.contain(@"subdir1/foo1");
        expect(filenames).to.contain(@"subdir1/bar1");
        expect(filenames).to.contain(@"subdir2/foo2");
        expect(filenames).to.contain(@"subdir2/bar2");
        expect(filenames).to.contain(@"subdir2/subdir3/foo3");
        expect(filenames).to.contain(@"subdir2/subdir3/bar3");
    };
    
    id (^filesInManifest)(NSURL *) = ^ id (NSURL *rootURL) {
        return [[[[SlugService alloc] init] createManifestFromPath:rootURL] map:^id(id r) {
            return [r objectForKey:@"fn"];
        }];
    };
    
    __block NSSet *intendedFiles;
    
    NSArray *root = @[NSTemporaryDirectory(), @"ThorScratchDir"];
    NSString *rootPath = [NSString pathWithComponents:root];
    NSURL *rootURL = [NSURL fileURLWithPath:rootPath];
    
    beforeEach(^{
        intendedFiles = createFilesAtRoot(@[
                    @[ @[@"foo"], @"this is /foo" ],
                    @[ @[@"bar"], @"this is /bar" ],
                    @[ @[@"subdir1", @"foo1"], @"this is /subdir1/foo1" ],
                    @[ @[@"subdir1", @"bar1"], @"this is /subdir1/bar1" ],
                    @[ @[@"subdir2", @"foo2"], @"this is /subdir2/foo2" ],
                    @[ @[@"subdir2", @"bar2"], @"this is /subdir2/bar2" ],
                    @[ @[@"subdir2", @"subdir3", @"foo3"], @"this is /subdir2/subdir3/foo3" ],
                    @[ @[@"subdir2", @"subdir3", @"bar3"], @"this is /subdir2/subdir3/bar3" ],
                    ], root);
        createFilesAtRoot(@[
                          @[ @[ @".DS_Store" ], @"stuff things" ],
                          @[ @[ @"subdir1", @".DS_Store" ], @"stuff things" ],
                          @[ @[ @".git", @"index" ], @"things stuff" ],
                          @[ @[ @".git", @"objects", @"abcdef" ], @"things stuff" ]
                          ], root);
    });
    
    afterEach(^{
        removeCreatedFiles(rootPath);
    });

    it(@"should list files recursively", ^{
        expectToBeIntendedFiles(filesInManifest(rootURL));
    });
    
    it(@"should exclude .git directories", ^ {
        createFilesAtRoot(@[
                    @[ @[@".git", @"index-n-stuff"], @"blah blah blah" ],
                    @[ @[@".git", @"objects"], @"tree or whatever" ],
                    @[ @[@".git", @"whateverelse"], @"wish I understood git more" ]
                    ], root);
        
        
        expectToBeIntendedFiles(filesInManifest(rootURL));
    });
    
    it(@"should provide file sizes", ^ {
        NSArray *manifest = [[[SlugService alloc] init] createManifestFromPath:rootURL];
        
        NSMutableDictionary *nameToSizeDict = [manifest reduce:^id(id acc, id i) {
            ((NSMutableDictionary *)acc)[[i objectForKey:@"fn"]] = [i objectForKey:@"size"];
            return acc;
        } seed:[NSMutableDictionary dictionary]];
        
        expect(nameToSizeDict[@"foo"]).to.equal(@"this is /foo".length);
        expect(nameToSizeDict[@"subdir1/foo1"]).to.equal(@"this is /subdir1/foo1".length);
        expect(nameToSizeDict[@"subdir2/subdir3/bar3"]).to.equal(@"this is /subdir2/subdir3/bar3".length);
    });
    
    it(@"should calculate SHA1 digests", ^ {
        NSArray *manifest = [[[SlugService alloc] init] createManifestFromPath:rootURL];
        
        NSMutableDictionary *nameToHashDict = [manifest reduce:^id(id acc, id i) {
            ((NSMutableDictionary *)acc)[[i objectForKey:@"fn"]] = [i objectForKey:@"sha1"];
            return acc;
        } seed:[NSMutableDictionary dictionary]];
        
        expect(nameToHashDict[@"foo"]).to.equal(@"02d93cc62a7f63b4e4bead55fff95176251d7cc7");
        expect(nameToHashDict[@"subdir1/foo1"]).to.equal(@"1411e4e16e797bd23075cf9b4fc0611ea64402f2");
        expect(nameToHashDict[@"subdir2/subdir3/bar3"]).to.equal(@"84fb57be8728b638cfa2b100fc6b8f82dc807e62");
    });
});

void (^extractSlug)(NSURL *, NSURL *) = ^(NSURL *slug, NSURL *path) {
    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/bin/unzip";
    task.arguments = @[slug.path, @"-d", path.path];
    [task launch];
    [task waitUntilExit];
    
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:slug.path error:&error];
};

NSSet *(^filesUnderRoot)(NSURL *) = ^ NSSet * (NSURL *root) {
    NSSet *result = [NSSet set];
    root = [root URLByResolvingSymlinksInPath];
    id i = nil;
    for (id u in [[NSFileManager defaultManager] enumeratorAtURL:root includingPropertiesForKeys:nil options:0 errorHandler:nil]) {
        NSURL *url = [u URLByResolvingSymlinksInPath];
        
        NSError *error = nil;
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
        
        if (error)
            NSLog(@"Error: %@", [error localizedDescription]);
        
        if ([attributes[NSFileType] isEqual:NSFileTypeDirectory])
            continue;
        
        result = [result setByAddingObject:@{
            @"name": [url.path stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/", root.path] withString:@""],
            @"contents" : [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil]
         }];
    }
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:root.path error:&error];
    return result;
};

describe(@"CreateSlugFromManifest", ^{
    __block NSSet *createdFiles;
    
    NSArray *root = @[NSTemporaryDirectory(), @"ThorScratchDir"];
    NSString *rootPath = [NSString pathWithComponents:root];
    NSURL *rootURL = [NSURL fileURLWithPath:rootPath];
    
    beforeEach(^{
        createdFiles = createFilesAtRoot(@[
                    @[ @[@"foo"], @"this is /foo" ],
                    @[ @[@"bar"], @"this is /bar" ],
                    @[ @[@"subdir1", @"foo1"], @"this is /subdir1/foo1" ],
                    @[ @[@"subdir1", @"bar1"], @"this is /subdir1/bar1" ],
                    @[ @[@"subdir2", @"foo2"], @"this is /subdir2/foo2" ],
                    @[ @[@"subdir2", @"bar2"], @"this is /subdir2/bar2" ],
                    @[ @[@"subdir2", @"subdir3", @"foo3"], @"this is /subdir2/subdir3/foo3" ],
                    @[ @[@"subdir2", @"subdir3", @"bar3"], @"this is /subdir2/subdir3/bar3" ],
                    ], root);
    });
    
    afterEach(^{
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:rootPath error:&error];
    });
    
    it(@"should contain all of the files", ^{
        NSArray *extractionRoot = @[NSTemporaryDirectory(), @"TestZipDirExtracted"];
        NSURL *extractionRootPath = [NSURL fileURLWithPath:[NSString pathWithComponents:extractionRoot]];
        
        
        SlugService *service = [[SlugService alloc] init];
        NSArray *manifest = [service createManifestFromPath:rootURL];
        NSURL *slug = [service createSlugFromManifest:manifest path:rootURL];
        
        extractSlug(slug, extractionRootPath);
        NSSet *files = filesUnderRoot(extractionRootPath);
        
        expect(files).to.equal(createdFiles);
    });
});

void (^createZipFile)(NSArray *, NSArray *, NSArray *) = ^ void (NSArray *basePathComponents, NSArray *outputFileComponents, NSArray *manifest) {
    
    ensureDirectoryForFile(outputFileComponents, nil);
    
    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/bin/zip";
    task.currentDirectoryPath = [basePathComponents componentsJoinedByString:@"/"];
    task.arguments = [@[[outputFileComponents componentsJoinedByString:@"/"]] concat:[manifest map:^id(id i) {
        return [i componentsJoinedByString:@"/"];
    }]];
    
    [task launch];
    [task waitUntilExit];
};

describe(@"detect framework", ^{
    
    NSArray *root = @[NSTemporaryDirectory(), @"ThorScratchDir"];
    NSString *rootPath = [NSString pathWithComponents:root];
    NSURL *rootURL = [NSURL fileURLWithPath:rootPath];
    
    NSArray *zipScratchRoot = @[NSTemporaryDirectory(), @"ThorZipScratchDir"];
    NSString *zipScratchRootPath = [NSString pathWithComponents:zipScratchRoot];
    NSURL *zipScratchRootURL = [NSURL fileURLWithPath:zipScratchRootPath];
    
    __block NSString *archivePathToCleanUp;
    __block NSURL *archiveRootURL;
    
    void (^cleanup)() = ^ {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:rootPath error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:zipScratchRootPath error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:archivePathToCleanUp error:&error];
    };
    
    void (^createFiles)(NSArray *) = ^ (NSArray *manifest) {
        createFilesAtRoot(manifest, root);
    };
    
    afterEach(^{
        cleanup();
    });
    
    it(@"should default to standalone", ^{
        createFiles(@[
                    @[ @[@"foo", @"bar" ], @"augh nyeah" ],
                    @[ @[@"yay", ], @"argh blargh" ],
                    @[ @[@"lumps", ], @"hay" ],
                    ]);
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"standalone");
    });
    
    it(@"should detect rails apps", ^{
        createFiles(@[
                    @[ @[@"config", @"environment.rb" ], @"use rails or whatever" ],
                    ]);
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"rails");
    });
    
    it(@"should detect rack apps", ^{
        createFiles(@[
                    @[ @[ @"config.ru" ], @"use rack or whatever" ]
                    ]);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"rack");
    });
    
    it(@"should detect node apps", ^{
        NSArray *nodeSentinels = @[ @"server.js", @"app.js", @"index.js", @"main.js" ];
        
        [nodeSentinels each:^(id s) {
            createFiles(@[
                        @[ @[ s ], @"some javascript or whatever" ]
                        ]);
            
            NSString *framework = DetectFrameworkFromPath(rootURL);
            
            cleanup();
            
            expect(framework).to.equal(@"node");
        }];
    });
    
    it(@"should detect django apps", ^{
        createFiles(@[
                    @[ @[ @"manage.py" ], @"boot django or whatever" ],
                    @[ @[ @"settings.py" ], @"DEBUG = lol" ],
                    ]);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"django");
    });
    
    it(@"should detect php apps", ^{
        createFiles(@[
                    @[ @[ @"anything.php" ], @"$phpinfolol()" ]
                    ]);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"php");
    });
    
    it(@"should detect erlang/otp rebar apps", ^{
        createFiles(@[
                    @[ @[ @"releases", @"foo", @"foo.rel" ], @"whatever this contains" ],
                    @[ @[ @"releases", @"bar", @"bar.boot" ], @"whatever that contains" ]
                    ]);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"otp_rebar");
    });
    
    it(@"should detect WSGI apps", ^{
        createFiles(@[
                    @[ @[ @"wsgi.py" ], @"def application(req, start_res):\n\t\return process(req)\n" ]
                    ]);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"wsgi");
    });
    
    it(@"should detect ASP.NET apps", ^{
        createFiles(@[
                    @[ @[ @"web.config" ], @"<inscrutable><opaque><soup>blech</soup></opaque></inscrutable>" ]
                    ]);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"dotnet");
    });
    
    // java stuff is a little crazy. while the file structures are all about the same
    // they can be found a few different ways.
    //
    // - on the root path
    // - in a war file *in* the root path
    // - in a war file that *is* the root path
    
    
    void (^createArchiveOnRootPath)(NSArray *, NSString *) = ^ (NSArray *manifest, NSString *name) {
        createFilesAtRoot(manifest, zipScratchRoot);
        
        createZipFile(zipScratchRoot, [root concat:@[ name ]], [manifest map:^id(id i) {
            return ((NSArray *)i)[0];
        }]);
    };
    
    void (^createWarOnRootPath)(NSArray *) = ^ (NSArray *manifest) {
        createArchiveOnRootPath(manifest, @"foo.war");
    };
    
    void (^createZipOnRootPath)(NSArray *) = ^ (NSArray *manifest) {
        createArchiveOnRootPath(manifest, @"foo.zip");
    };
    
    
    void (^createArchiveAtRootPath)(NSArray *, NSString *name) = ^ void (NSArray *manifest, NSString *name) {
        createFilesAtRoot(manifest, zipScratchRoot);
        
        NSArray *archivePathComponents = @[NSTemporaryDirectory(), name];
        archivePathToCleanUp = [NSString pathWithComponents:archivePathComponents];
        archiveRootURL = [NSURL fileURLWithPath:archivePathToCleanUp];
        createZipFile(zipScratchRoot, archivePathComponents, [manifest map:^id(id i) {
            return ((NSArray *)i)[0];
        }]);
    };
    
    void (^createWarAtRootPath)(NSArray *) = ^ void (NSArray *manifest) {
        createArchiveAtRootPath(manifest, @"ThorTestWar.war");
    };
    
    void (^createZipAtRootPath)(NSArray *) = ^ void (NSArray *manifest) {
        createArchiveAtRootPath(manifest, @"ThorTestZip.zip");
    };
    
    id grailsManifest = @[
        @[ @[ @"WEB-INF", @"web.xml" ], @"whatever" ],
        @[ @[ @"WEB-INF", @"lib", @"grails-web-1.3.1.jar" ], @"blob" ]
    ];
    
    it(@"should detect grails apps on root path", ^{
        createFiles(grailsManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"grails");
    });
    
    it(@"should detect grails apps in war on root path", ^{
        createWarOnRootPath(grailsManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"grails");
    });
    
    it(@"should detect grails apps in war at root path", ^{
        createWarAtRootPath(grailsManifest);
        
        NSString *framework = DetectFrameworkFromPath(archiveRootURL);
        
        expect(framework).to.equal(@"grails");
    });
    
    id liftManifest = @[
        @[ @[ @"WEB-INF", @"web.xml" ], @"whatever" ],
        @[ @[ @"WEB-INF", @"lib", @"lift-webkit-1.0.1.jar" ], @"blob" ]
    ];
    
    it(@"should detect lift apps on root path", ^{
        createFiles(liftManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"lift");
    });
    
    it(@"should detect lift apps in war on root path", ^{
        createWarOnRootPath(liftManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"lift");
    });
    
    it(@"should detect lift apps in war at root path", ^{
        createWarAtRootPath(liftManifest);
        
        NSString *framework = DetectFrameworkFromPath(archiveRootURL);
        
        expect(framework).to.equal(@"lift");
    });
    
    id springCoreManifest = @[
        @[ @[ @"WEB-INF", @"web.xml" ], @"whatever" ],
        @[ @[ @"WEB-INF", @"lib", @"spring-core-2.0.1.jar" ], @"blob" ]
    ];
    
    it(@"should detect spring apps on root path with spring-core jar", ^{
        createFiles(springCoreManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"spring");
    });
    
    it(@"should detect spring apps in war on root path with spring-core jar", ^{
        createWarOnRootPath(springCoreManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"spring");
    });
    
    it(@"should detect spring apps in war at root path with spring-core jar", ^{
        createWarAtRootPath(springCoreManifest);
        
        NSString *framework = DetectFrameworkFromPath(archiveRootURL);
        
        expect(framework).to.equal(@"spring");
    });
    
    id springFrameworkCoreManifest = @[
        @[ @[ @"WEB-INF", @"web.xml" ], @"whatever" ],
        @[ @[ @"WEB-INF", @"lib", @"org.springframework.core-2.0.1.jar" ], @"blob" ]
    ];
    
    it(@"should detect spring apps on root path with org.springframework.core jar", ^{
        createFiles(springCoreManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"spring");
    });
    
    it(@"should detect spring apps in war on root path with org.springframework.core jar", ^{
        createWarOnRootPath(springCoreManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"spring");
    });
    
    it(@"should detect spring apps in war at root path with org.springframework.core jar", ^{
        createWarAtRootPath(springCoreManifest);
        
        NSString *framework = DetectFrameworkFromPath(archiveRootURL);
        
        expect(framework).to.equal(@"spring");
    });
    
    id springFrameworkClassesManifest = @[
    @[ @[ @"WEB-INF", @"web.xml" ], @"whatever" ],
    @[ @[ @"WEB-INF", @"classes", @"org", @"springframework", @"whatever.class" ], @"blob" ]
    ];
    
    it(@"should detect spring apps on root path with springframework classes", ^{
        createFiles(springFrameworkClassesManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"spring");
    });
    
    it(@"should detect spring apps in war on root path with springframework classes", ^{
        createWarOnRootPath(springFrameworkClassesManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"spring");
    });
    
    it(@"should detect spring apps in war at root path with springframework classes", ^{
        createWarAtRootPath(springFrameworkClassesManifest);
        
        NSString *framework = DetectFrameworkFromPath(archiveRootURL);
        
        expect(framework).to.equal(@"spring");
    });
    
    id otherFrameworkManifest = @[
    @[ @[ @"WEB-INF", @"web.xml" ], @"whatever" ],
    @[ @[ @"WEB-INF", @"classes", @"some", @"other", @"framework.class" ], @"blob" ]
    ];
    
    it(@"should detect other java web apps on root path", ^{
        createFiles(otherFrameworkManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"java_web");
    });
    
    it(@"should detect other java web apps in war on root path", ^{
        createWarOnRootPath(otherFrameworkManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"java_web");
    });
    
    it(@"should detect other java web apps in war at root path", ^{
        createWarAtRootPath(otherFrameworkManifest);
        
        NSString *framework = DetectFrameworkFromPath(archiveRootURL);
        
        expect(framework).to.equal(@"java_web");
    });
    
    id playManifest = @[
        @[ @[ @"lib", @"play.1.0.jar" ], @"stuff" ]
    ];
    
    it(@"should detect play apps in zip on root path", ^{
        createZipOnRootPath(playManifest);
        
        NSString *framework = DetectFrameworkFromPath(rootURL);
        
        expect(framework).to.equal(@"play");
    });
    
    it(@"should detect play apps in zip at root path", ^{
        createZipAtRootPath(playManifest);
        
        NSString *framework = DetectFrameworkFromPath(archiveRootURL);
        
        expect(framework).to.equal(@"play");
    });
});

// this tests a full create/post slug deployment to a CF service. it's disabled
// because it assumes a CF service exists and we don't want test failures
// if that is not the case. so it's here for posterity i guess.
//
//describe(@"TestDeployment", ^{
//    it(@"should deploy a thing", ^{
//        
//        NSArray *repoPathComponents = @[ NSTemporaryDirectory(), @"paasIt" ];
//        NSString *repoPath = [NSString pathWithComponents:repoPathComponents];
//        
//        [[NSFileManager defaultManager] removeItemAtPath:repoPath error:nil];
//        NSURL *repoURL = [NSURL fileURLWithPath:repoPath];
//        
//        NSTask *task = [NSTask new];
//        task.launchPath = @"/usr/bin/git";
//        task.arguments = @[ @"clone", @"git://github.com/Adron/goldmind.git", repoPath ];
//        [task launch];
//        [task waitUntilExit];
//        
//        NSURL *nodeTestAppURL = [NSURL fileURLWithPath:[NSString pathWithComponents:repoPathComponents]];
//        
//        NSArray *manifest = CreateSlugManifestFromPath(nodeTestAppURL);
//        NSURL *slug = CreateSlugFromManifest(manifest, nodeTestAppURL);
//        
//        FoundryEndpoint *endpoint = [FoundryEndpoint new];
//        endpoint.email = @"b@bvanderveen.com";
//        endpoint.password = @"secret";
//        endpoint.hostname = @"api.bvanderveen.cloudfoundry.me";
//        
//        FoundryClient *client = [[FoundryClient alloc] initWithEndpoint:endpoint];
//        
//        FoundryApp *app = [FoundryApp new];
//        app.name = @"goldmind-test";
//        app.uris = @[ [NSString stringWithFormat:@"%@.bvanderveen.cloudfoundry.me", app.name] ];
//        app.instances = 1;
//        //app.state = FoundryAppStateStarted;
//        app.memory = 64;
//        //app.disk = 2048;
//        app.stagingFramework = @"node";
//        //app.stagingRuntime = [NSNull null];//@"node";
//        //app.services = @[];
//        
//        __block BOOL done = NO, err = NO;
//        int attempts = 0;
//        
//        [[client createApp:app] subscribeError:^ (NSError *error) {
//            NSLog(@"error: %@", [error localizedDescription]);
//            err = YES;
//        } completed:^{
//            [[client postSlug:slug manifest:manifest toAppWithName:app.name] subscribeError: ^ (NSError *error) {
//                NSLog(@"error: %@", [error localizedDescription]);
//                err = YES;
//            } completed:^{
//                done = YES;
//                NSError *error = nil;
//            }];
//        }];
//        
//        while (!done && !err && attempts++ < 1) {
//            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:15.0]];
//        }
//        
//        expect(err).to.beFalsy();
//        expect(done).to.beTruthy();
//        
//        NSError *error;
//        [[NSFileManager defaultManager] removeItemAtPath:repoPath error:&error];
//        [[NSFileManager defaultManager] removeItemAtPath:slug.path error:&error];
//    });
//});

describe(@"getServices", ^{
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[client getServices] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"GET",
        @"path" : @"/services",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse results", ^ {
        endpoint.results = @[ @[
        @{
        @"name" : @"the name",
        @"vendor" : @"the vendor",
        @"version" : @"1.2"
        },
        @{
        @"name" : @"the name 2",
        @"vendor" : @"the vendor 2",
        @"version" : @"1.2.2"
        }
        ] ];
        
        __block NSArray *result;
        [[client getServices] subscribeNext:^(id x) {
            result = (NSArray *)x;
        }];
        
        expect(result.count).to.equal(2);
        
        FoundryService *service0 = result[0];
        expect(service0.name).to.equal(@"the name");
        expect(service0.vendor).to.equal(@"the vendor");
        expect(service0.version).to.equal(@"1.2");
        
        FoundryService *service1 = result[1];
        expect(service1.name).to.equal(@"the name 2");
        expect(service1.vendor).to.equal(@"the vendor 2");
        expect(service1.version).to.equal(@"1.2.2");
    });
});

describe(@"getServiceWithName", ^{
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[client getServiceWithName:@"service-name"] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"GET",
        @"path" : @"/services/service-name",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse results", ^ {
        endpoint.results = @[
        @{
        @"name" : @"the name",
        @"vendor" : @"the vendor",
        @"version" : @"1.2"
        }
        ];
        
        __block FoundryService *result;
        [[client getServiceWithName:@"the name"] subscribeNext:^(id x) {
            result = (FoundryService *)x;
        }];
        
        expect(result.name).to.equal(@"the name");
        expect(result.vendor).to.equal(@"the vendor");
        expect(result.version).to.equal(@"1.2");
    });
});

describe(@"createService", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        
        FoundryService *service = [FoundryService new];
        
        service.name = @"the name";
        service.vendor = @"the vendor";
        service.version = @"the version";
        
        [[client createService:service] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"POST",
        @"path" : @"/services",
        @"headers" : [NSNull null],
        @"body" : @{
        @"name" : @"the name",
        @"vendor" : @"the vendor",
        @"version" : @"the version",
        @"tier" : @"free"
        }}];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
});

describe(@"deleteServiceWithName", ^ {
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[client deleteServiceWithName:@"foobard"] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"DELETE",
        @"path" : @"/services/foobard",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
});


describe(@"getServicesInfo", ^{
    __block MockEndpoint *endpoint;
    __block FoundryClient *client;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        client = [[FoundryClient alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[client getServicesInfo] subscribeCompleted:^{ }];
        
        id expectedCalls = @[@{
        @"method" : @"GET",
        @"path" : @"/info/services",
        @"headers" : [NSNull null],
        @"body" : [NSNull null]
        }];
        
        expect(endpoint.calls).to.equal(expectedCalls);
    });
    
    it(@"should parse results", ^ {
        endpoint.results = @[
        @{
            @"key-value":@{
                @"mongodb":@{
                    @"1.8":@{
                        @"id":@3,
                        @"vendor":@"mongodb",
                        @"version":@"1.8",
                        @"tiers":@{
                            @"free":@{
                                @"options":@{
                                },
                                @"order":@1
                            }
                        },
                        @"type":@"key-value",
                        @"description":@"MongoDB NoSQL store"
                    }
                },
                @"redis":@{
                    @"2.2":@{
                        @"id":@4,
                        @"vendor":@"redis",
                        @"version":@"2.2",
                        @"tiers":@{
                            @"free":@{
                                @"options":@{
                                },
                                @"order":@1
                            }
                        },
                        @"type":@"key-value",
                        @"description":@"Redis key-value store service"
                    }
                }
            },
            @"generic":@{
                @"mssql":@{
                    @"10.50.2500":@{
                        @"id":@7,
                        @"vendor":@"mssql",
                        @"version":@"10.50.2500",
                        @"tiers":@{
                            @"free":@{
                                @"options":@{
                                    
                                },
                                @"order":@1
                            }
                        },
                        @"type":@"generic",
                        @"description":@"MS SQL database service"
                    }
                },
            }
        }
        ];
        
        __block NSArray *result;
        [[client getServicesInfo] subscribeNext:^(id x) {
            result = (NSArray *)x;
        }];
        
        expect(result.count).to.equal(3);
        
        void (^assertAnyEqual)(NSString *, NSString *, NSString *) = ^ void (NSString *description, NSString *vendor, NSString *version) {
            BOOL anyEqual = [result any:^BOOL(id i) {
                FoundryServiceInfo *info = (FoundryServiceInfo *)i;
                return
                [info.description isEqual:description] &&
                [info.vendor isEqual:vendor] &&
                [info.version isEqual:version];
            }];
            expect(anyEqual).to.beTruthy();
        };
        
        assertAnyEqual(@"MongoDB NoSQL store", @"mongodb", @"1.8");
        assertAnyEqual(@"Redis key-value store service", @"redis", @"2.2");
        assertAnyEqual(@"MS SQL database service", @"mssql", @"10.50.2500");
    });
});


SpecEnd