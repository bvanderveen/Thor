#import "VMCOperationsTests.h"
#import "VMCOperations.h"

@interface MockShell : NSObject

@property (nonatomic, copy) SynchronousExecuteShellBlock block;
@property (nonatomic, copy) NSArray *resultStrings;
@property (nonatomic, copy) NSArray *calls;

@end

@implementation MockShell

@synthesize block, resultStrings, calls;

- (id)init {
    if (self = [super init]) {
        self.resultStrings = [NSArray array];
        self.calls = [NSArray array];
        self.block = ^ NSString * (NSString *cmd, NSArray *args) {
            
            NSArray *call = [NSArray arrayWithObject:cmd];
            call = [call arrayByAddingObjectsFromArray:args];
            self.calls = [self.calls arrayByAddingObject:call];
            
            NSString *result = nil;
            if (self.resultStrings.count) {
                result = [self.resultStrings objectAtIndex:0];
                NSMutableArray *newResults = [self.resultStrings mutableCopy];
                [newResults removeObjectAtIndex:0];
                self.resultStrings = newResults;
            }
            return result;
        };
    }
    return self;
}

@end

@interface VMCOperationsTests ()

@property (nonatomic, strong) VMCOperationsImpl *impl;
@property (nonatomic, strong) MockShell *mockShell;

@end

@implementation VMCOperationsTests

@synthesize impl, mockShell;

- (void)testSynchronousExecuteShell {
    NSString *result = SynchronousExecuteShell(@"/bin/echo", [NSArray arrayWithObjects:@"the text to", @"be echoed", nil]);
    
    STAssertEqualObjects(result, @"the text to be echoed\n", @"unexpected result from shell");
}

- (void)setUp {
    self.mockShell = [MockShell new];
    self.impl = [[VMCOperationsImpl alloc] initWithShellBlock:mockShell.block];
}

- (void)testTargetHostnameGeneratesCommand {
    [self.impl targetHostname:@"api.host.name"];
    
    NSArray *expectedCalls = [NSArray arrayWithObject:[NSArray arrayWithObjects:@"vmc", @"target", @"api.host.name", @"--non-interactive", nil]];
    STAssertEqualObjects(self.mockShell.calls, expectedCalls, @"shell got unexpected command");
}

- (void)testTargetHostnameReturnsTrueOnSuccess {
    self.mockShell.resultStrings = [NSArray arrayWithObject:@"Successfully targeted to [http://api.host.name]\n\n"];
    
    BOOL result = [self.impl targetHostname:@"api.host.name"];
    
    STAssertTrue(result, @"unexpected result");
}

- (void)testTargetHostnameReturnsFalseOnFailure {
    self.mockShell.resultStrings = [NSArray arrayWithObject:@"\n\n"];
    
    BOOL result = [self.impl targetHostname:@"api.host.name"];
    
    STAssertFalse(result, @"unexpected result");
}

- (void)testLoginGeneratesCommand {
    [self.impl loginWithEmail:@"foo@bar.com" password:@"secret"];
    
    NSArray *expectedCalls = [NSArray arrayWithObject:[NSArray arrayWithObjects:@"vmc", @"login", 
                                                       @"--email", @"foo@bar.com",
                                                       @"--password", @"secret", 
                                                       @"--non-interactive", nil]];
    
    STAssertEqualObjects(self.mockShell.calls, expectedCalls, @"shell got unexpected command");
}

- (void)testLoginReturnsTrueOnSuccess {
    self.mockShell.resultStrings = [NSArray arrayWithObject:@"Successfully logged into [http://api.host.name]\n\n"];
    
    BOOL result = [self.impl loginWithEmail:@"foo@bar.com" password:@"secret"];
    
    STAssertTrue(result, @"unexpected result");
}

- (void)testLoginReturnsFalseOnFailure {
    self.mockShell.resultStrings = [NSArray arrayWithObject:@"Problem with login, invalid account or password when attempting to login to 'http://api.host.name'\n"];
    
    BOOL result = [self.impl targetHostname:@"api.host.name"];
    
    STAssertFalse(result, @"unexpected result");
}

- (void)testGetAppsGeneratesCommand {
    [self.impl getApps];
    
    NSArray *expectedCalls = [NSArray arrayWithObject:[NSArray arrayWithObjects:@"vmc", @"apps",
                                                       @"--non-interactive", nil]];
    
    STAssertEqualObjects(self.mockShell.calls, expectedCalls, @"shell got unexpected command");
}

- (void)testGetAppsReturnsEmptyArrayIfNoApps {
    self.mockShell.resultStrings = [NSArray arrayWithObject:@"\n\nNo Applications\n\n"];
    
    NSArray *result = [self.impl getApps];
    
    NSInteger actualCount = result.count;
    STAssertTrue(actualCount == 0, @"Expected empty result");
}

- (void)testGetAppsParsesAppList {
    NSString *outputString = @"\n"
"\n"    
"+-------------+----+---------+--------------------------------------+----------+\n"
"| Application | #  | Health  | URLS                                 | Services |\n"
"+-------------+----+---------+--------------------------------------+----------+\n"
"| gm          | 1  | RUNNING | gm.robotech.wfabric.com, foo.bar.com |          |\n"
"| nodejs_test | 1  | 0%      | nodejs_test.robotech.wa1.wfabric.com |          |\n"
"+-------------+----+---------+--------------------------------------+----------+\n"
"\n"
"\n";
    self.mockShell.resultStrings = [NSArray arrayWithObject:outputString];
    
    NSArray *result = [self.impl getApps];
    
    NSInteger actualCount = result.count;
    STAssertTrue(actualCount == 2, @"Expected 2 results");
    
    VMCApp *app0 = [VMCApp new];
    app0.name = @"gm";
    app0.uris = [NSArray arrayWithObjects:@"gm.robotech.wfabric.com", @"foo.bar.com", nil];
    
    VMCApp *app1 = [VMCApp new];
    app1.name = @"nodejs_test";
    app1.uris = [NSArray arrayWithObject:@"nodejs_test.robotech.wa1.wfabric.com"];
    
    NSArray *expectedResult = [NSArray arrayWithObjects:app0, app1, nil];
    STAssertEqualObjects(result, expectedResult, @"unexpected result from getApps");
}

- (void)testGetInstanceStatsForAppGeneratesCommand {
    [self.impl getInstanceStatsForApp:@"appName"];
    
    NSArray *expectedCalls = [NSArray arrayWithObject:[NSArray arrayWithObjects:@"vmc", @"stats",
                                                       @"appName",
                                                       @"--non-interactive", nil]];
    
    STAssertEqualObjects(self.mockShell.calls, expectedCalls, @"shell got unexpected command");
}

- (void)testGetInstanceStatsForUnknownAppReturnsNil {
    self.mockShell.resultStrings = [NSArray arrayWithObject:@"\n\nError 301: Application Not Found\n\n"];
    
    NSArray *result = [self.impl getInstanceStatsForApp:@"appName"];
    
    STAssertNil(result, @"expected nil result");
}

- (void)testGetInstanceStatsForAppParsesInstanceList {
    NSString *outputString = @"\n"
"\n"
"+----------+-------------+----------------+--------------+---------------+\n"
"| Instance | CPU (Cores) | Memory (limit) | Disk (limit) | Uptime        |\n"
"+----------+-------------+----------------+--------------+---------------+\n"
"| 0        | 0.0% (2)    | 12.2M (64M)    | 6.5M (2G)    | 0d:1h:31m:14s |\n"
"| 1        | 0.2% (2)    | 14.2M (64M)    | 8.5M (2G)    | 0d:1h:32m:12s |\n"
"+----------+-------------+----------------+--------------+---------------+\n"
"\n"
"\n";
    self.mockShell.resultStrings = [NSArray arrayWithObject:outputString];
    
    NSArray *result = [self.impl getInstanceStatsForApp:@"appName"];
    
    NSInteger actualCount = result.count;
    STAssertTrue(actualCount == 2, @"Expected 2 results");
    
    VMCInstanceStats *stats0 = [VMCInstanceStats new];
    stats0.ID = @"0";
    stats0.cpu = @"0.0% (2)";
    stats0.memory = @"12.2M (64M)";
    stats0.disk = @"6.5M (2G)";
    stats0.uptime = @"0d:1h:31m:14s";
    
    VMCInstanceStats *stats1 = [VMCInstanceStats new];
    stats1.ID = @"1";
    stats1.cpu = @"0.2% (2)";
    stats1.memory = @"14.2M (64M)";
    stats1.disk = @"8.5M (2G)";
    stats1.uptime = @"0d:1h:32m:12s";
    
    NSArray *expectedResult = [NSArray arrayWithObjects:stats0, stats1, nil];
    STAssertEqualObjects(result, expectedResult, @"unexpected result from getInstanceStatsForApp");
}

@end
