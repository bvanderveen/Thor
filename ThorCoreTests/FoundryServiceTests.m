#import "FoundryServiceTests.h"
#import "FoundryService.h"
#import "Specta.h"
#define EXP_SHORTHAND
#import "Expecta.h"

@interface MockEndpoint : NSObject

@property (nonatomic, strong) NSMutableArray *calls, *results;

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
    
    [calls addObject:call];
    
    id resultObject = results.count ? results[0] : nil;
    
    if (results.count)
        [results removeObjectAtIndex:0];
    
    return [RACSubscribable return:resultObject];
}

@end

@interface FoundryServiceTests ()

@property (nonatomic, strong) FoundryService *service;
@property (nonatomic, strong) MockEndpoint *endpoint;


@end

@implementation FoundryServiceTests

@synthesize service, endpoint;

- (void)setUp {
}

- (void)tearDown {
}

- (void)testGetAppsCallsEndpoint {
    
    
    //STAssertEqualObjects(endpoint.calls[0], expected, @"did not recieve expected calls");
}

- (void)testGetAppsParsesResults {
    
}

@end


SpecBegin(FoundryService)

describe(@"FoundryService", ^ {
    
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
});

SpecEnd