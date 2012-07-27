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
    
    STAssertEquals(result.count, 0, @"Expected empty result");
}

- (void)testGetAppsParsesAppList {
    NSString *outputString = @" \
    \
    +-------------+----+---------+--------------------------------------+----------+ \
    | Application | #  | Health  | URLS                                 | Services | \
    +-------------+----+---------+--------------------------------------+----------+ \
    | gm          | 1  | RUNNING | gm.robotech.wa1.wfabric.com          |          | \
    | nodejs_test | 1  | 0%      | nodejs_test.robotech.wa1.wfabric.com |          | \
    +-------------+----+---------+--------------------------------------+----------+ \
    \
    ";
    self.mockShell.resultStrings = [NSArray arrayWithObject:outputString];
    
    NSArray *result = [self.impl getApps];
    
    NSArray *expectedResult = [NSArray arrayWithObjects:@"gm", @"nodejs_test", nil];
    STAssertEqualObjects(result, expectedResult, @"unexpected result from getApps");
}

@end
