#import "FoundryServiceTests.h"
#import "FoundryService.h"
#import "Specta.h"
#define EXP_SHORTHAND
#import "Expecta.h"

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

- (RACSubscribable *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body {
    NSDictionary *call = @{
    @"method" : method ? method : [NSNull null],
    @"path" : path ? path : [NSNull null],
    @"headers" : headers ? headers : [NSNull null],
    @"body" : body ? body : [NSNull null]
    };
    
    calls = [calls arrayByAddingObject:call];
    
    id resultObject = results.count ? results[0] : nil;
    
    if (results.count) {
        NSMutableArray *newResults = [results mutableCopy];
        [newResults removeObjectAtIndex:0];
        results = newResults;
    }
    
    return [RACSubscribable return:resultObject];
}

@end

SpecBegin(FoundryService)

describe(@"getApps", ^ {
    
    __block MockEndpoint *endpoint;
    __block FoundryService *service;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        service = [[FoundryService alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[service getApps] subscribeCompleted:^{ }];
        
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
        [[service getApps] subscribeNext:^(id x) {
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
    __block FoundryService *service;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        service = [[FoundryService alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[service getAppWithName:@"name"] subscribeCompleted:^{ }];
        
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
        
        [[service getAppWithName:@"the name"] subscribeNext:^(id x) {
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
    __block FoundryService *service;
    
    beforeEach(^ {
        endpoint = [MockEndpoint new];
        service = [[FoundryService alloc] initWithEndpoint:(FoundryEndpoint *)endpoint];
    });
    
    it(@"should call endpoint", ^ {
        [[service getStatsForAppWithName:@"name"] subscribeCompleted:^{ }];
        
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
        
        [[service getStatsForAppWithName:@"the name"] subscribeNext:^(id x) {
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
});

describe(@"CreateSlugFromPath", ^ {
    NSArray *root = @[NSTemporaryDirectory(), @"TestZipDir"];
    NSString *rootPath = [NSString pathWithComponents:root];
    
    beforeEach(^{
        void(^createFile)(NSArray *, NSString *) = ^ (NSArray *pathComponents, NSString *contents) {
            
            NSString *directory = [NSString pathWithComponents:[[root concat:pathComponents] take:root.count + pathComponents.count - 1]];
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
            
            if (error) {
                NSLog(@"error: %@", [error localizedDescription]);
                assert(NO);
            }
            
            NSString *path = [NSString pathWithComponents:[root arrayByAddingObjectsFromArray:pathComponents]];
            
            [[NSFileManager defaultManager] createFileAtPath:path contents:[contents dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        };
        
        createFile(@[@"foo"], @"this is /foo");
        createFile(@[@"bar"], @"this is /bar");
        createFile(@[@"subdir1", @"foo1"], @"this is /subdir1/foo1");
        createFile(@[@"subdir1", @"bar1"], @"this is /subdir1/bar1");
        createFile(@[@"subdir2", @"foo2"], @"this is /subdir2/foo2");
        createFile(@[@"subdir2", @"bar2"], @"this is /subdir2/bar2");
        createFile(@[@"subdir2", @"subdir3", @"foo3"], @"this is /subdir2/subdir3/foo3");
        createFile(@[@"subdir2", @"subdir3", @"bar3"], @"this is /subdir2/subdir3/bar3");
    });
    
    afterEach(^{
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:rootPath error:&error];
    });

    it(@"should list files recursively", ^{
        FoundrySlug *slug = CreateSlugFromPath([NSURL fileURLWithPath:rootPath]);
        
        NSArray *filenames = [slug.resources map:^id(id r) {
            return [r objectForKey:@"fn"];
        }];
        
        expect(filenames.count).to.equal(8);
        expect(filenames).to.contain(@"/foo");
        expect(filenames).to.contain(@"/bar");
        expect(filenames).to.contain(@"/subdir1/foo1");
        expect(filenames).to.contain(@"/subdir1/bar1");
        expect(filenames).to.contain(@"/subdir2/foo2");
        expect(filenames).to.contain(@"/subdir2/bar2");
        expect(filenames).to.contain(@"/subdir2/subdir3/foo3");
        expect(filenames).to.contain(@"/subdir2/subdir3/bar3");
    });
    
    it(@"should provide file sizes", ^ {
        FoundrySlug *slug = CreateSlugFromPath([NSURL fileURLWithPath:rootPath]);
        
        
        NSMutableDictionary *nameToSizeDict = [slug.resources reduce:^id(id acc, id i) {
            ((NSMutableDictionary *)acc)[[i objectForKey:@"fn"]] = [i objectForKey:@"size"];
            return acc;
        } seed:[NSMutableDictionary dictionary]];
        
        expect(nameToSizeDict[@"/foo"]).to.equal(@"this is /foo".length);
        expect(nameToSizeDict[@"/subdir1/foo1"]).to.equal(@"this is /subdir1/foo1".length);
        expect(nameToSizeDict[@"/subdir2/subdir3/bar3"]).to.equal(@"this is /subdir2/subdir3/bar3".length);
    });
    
    it(@"should calculate SHA1 digests", ^ {
        FoundrySlug *slug = CreateSlugFromPath([NSURL fileURLWithPath:rootPath]);
        
        
        NSMutableDictionary *nameToHashDict = [slug.resources reduce:^id(id acc, id i) {
            ((NSMutableDictionary *)acc)[[i objectForKey:@"fn"]] = [i objectForKey:@"sha1"];
            return acc;
        } seed:[NSMutableDictionary dictionary]];
        
        expect(nameToHashDict[@"/foo"]).to.equal(@"02d93cc62a7f63b4e4bead55fff95176251d7cc7");
        expect(nameToHashDict[@"/subdir1/foo1"]).to.equal(@"1411e4e16e797bd23075cf9b4fc0611ea64402f2");
        expect(nameToHashDict[@"/subdir2/subdir3/bar3"]).to.equal(@"84fb57be8728b638cfa2b100fc6b8f82dc807e62");
    });
    
    it(@"should generate zip file containing listed files", ^ {
        
    });
});

SpecEnd