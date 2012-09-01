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

SpecEnd