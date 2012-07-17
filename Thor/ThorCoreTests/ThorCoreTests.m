#import "ThorCoreTests.h"
#import "ThorCore.h"

@interface ThorBackendTests ()

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) ThorBackendImpl *backend;
@property (nonatomic, copy) NSString *tempStorePath;

- (void)saveContext;

@end

@interface ThorBackendTests (Fixtures)

- (NSArray *)createConfiguredApps;

@end

@implementation ThorBackendTests (Fixtures)

- (NSArray *)createConfiguredApps {
    return [NSArray arrayWithObjects:
            [App appWithDictionary:[self createApp] insertIntoManagedObjectContext:self.context],
            [App appWithDictionary:[self createApp] insertIntoManagedObjectContext:self.context],
            [App appWithDictionary:[self createApp] insertIntoManagedObjectContext:self.context],
            nil]
            ;
}

- (NSDictionary *)createApp {
    static int counter = 0;
    
    counter++;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithFormat:@"App %d", counter], @"displayName",
            [NSString stringWithFormat:@"/path/to/app%d", counter], @"localRoot",
            [NSNumber numberWithInt:128], @"defaultMemory",
            [NSNumber numberWithInt:2], @"defaultInstances", 
            nil];
}

@end

@interface ThorBackendTests (Assertions)

- (void)assertActualApps:(NSArray *)actualApps equalExpectedApps:(NSArray *)expectedApps;
- (void)assertAppExistsInLocalConfiguration:(App *)app;
//- (void)assertError:(NSError *)error hasDomain:(NSString *)domain andCode:(NSInteger)code;

@end

@implementation ThorBackendTests (Assertions)

- (void)assertActualApps:(NSArray *)actualApps equalExpectedApps:(NSArray *)expectedApps {
    for (int i = 0; i < expectedApps.count; i++)
        STAssertEqualObjects([actualApps objectAtIndex:i], [expectedApps objectAtIndex:i], @"Apps differed");
        
}

- (void)assertAppExistsInLocalConfiguration:(App *)app {
    
}

@end

@implementation ThorBackendTests

@synthesize context, backend, tempStorePath;

- (void)saveContext {
    NSError *error = nil;
    [self.context save:&error];
    assert(!error);
}

- (void)setUp
{
    [super setUp];
    
    self.tempStorePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TempStore"];
    
    NSError *error = nil;
    self.context = ThorGetObjectContext([NSURL fileURLWithPath:tempStorePath], &error);
    
    if (!self.context)
        NSLog(@"fail to create test context: %@", error.localizedDescription);
    
    self.backend = [[ThorBackendImpl alloc] initWithObjectContext:context];
}

- (void)tearDown
{
    NSError *error = nil;
    if (![[NSFileManager new] removeItemAtPath:self.tempStorePath error:&error])
        NSLog(@"failed to remove temp store: %@", error.localizedDescription);
    
    [super tearDown];
}


- (void)testGetConfiguredAppsReadsLocalConfiguration {
    NSArray *expectedApps = [self createConfiguredApps];
    
    NSError *error = nil;
    NSArray *actualApps = [self.backend getConfiguredApps:&error];
    
    assert(!error);
    [self assertActualApps:actualApps equalExpectedApps:expectedApps];
}

//- (void)testCreateConfiguredAppAmendsLocalConfiguration {
//    App *app = [self.fixtures createApp];
//    
//    [self.backend createConfiguredApp:app];
//    
//    [self.assertions assertAppExistsInLocalConfiguration:app];
//}
//
//- (void)testCreateConfiguredAppReturnsErrorIfAppLocalPathIsPreviouslyUsed {
//    App *app0 = [self.fixtures createApp];
//    App *app1 = [self.fixtures createApp];
//    [self.backend createConfiguredApp:app0];
//    
//    NSError *error = nil;
//    [self.backend createConfiguredApp:app1 error:&error];
//    
//    [self.assertions assertError:error hasDomain:ThorErrorDomain andCode:AppLocalRootInvalid];
//}
//
//- (void)testCreateConfiguredAppThrowsExceptionIfAppDefaultMemoryIsTooLow {
//    App *app0 = [self.fixtures createApp];
//    app0.defaultMemory = 0;
//    [self.backend createConfiguredApp:app0];
//    
//    NSError *error = nil;
//    [self.backend createConfiguredApp:app0 error:&error];
//    
//    [self.assertions assertError:error hasDomain:ThorErrorDomain andCode:AppMemoryOutOfRange];
//}
//- (void)testCreateConfiguredAppThrowsExceptionIfAppDefaultMemoryIsTooHigh {
//    App *app0 = [self.fixtures createApp];
//    app0.defaultMemory = 1024 * 1024 * 1024;
//    [self.backend createConfiguredApp:app0];
//    
//    NSError *error = nil;
//    [self.backend createConfiguredApp:app0 error:&error];
//    
//    [self.assertions assertError:error hasDomain:ThorErrorDomain andCode:AppMemoryOutOfRange];
//}
//
//- (void)testCreateConfiguredAppThrowsExceptionIfAppDefaultInstancesIsTooLow {
//    App *app0 = [self.fixtures createApp];
//    app0.defaultInstances = 0;
//    [self.backend createConfiguredApp:app0];
//    
//    NSError *error = nil;
//    [self.backend createConfiguredApp:app0 error:&error];
//    
//    [self.assertions assertError:error hasDomain:ThorErrorDomain andCode:AppInstancesOutOfRange];
//}
//
//- (void)testCreateConfiguredAppThrowsExceptionIfAppDefaultInstancesIsTooHigh {
//    App *app0 = [self.fixtures createApp];
//    app0.defaultInstances = 1024;
//    [self.backend createConfiguredApp:app0];
//    
//    NSError *error = nil;
//    [self.backend createConfiguredApp:app0 error:&error];
//    
//    [self.assertions assertError:error hasDomain:ThorErrorDomain andCode:AppInstancesOutOfRange];
//}
//
//- (void)testUpdateConfiguredAppUpdatesLocalConfiguration {
//}
//
//- (void)testUpdateConfiguredAppThrowsExceptionIfAppLocalPathIsPreviouslyUsed {
//}
//
//- (void)testUpdateConfiguredAppThrowsExceptionIfAppDefaultMemoryIsOutOfRange {
//}
//
//- (void)testUpdateConfiguredAppThrowsExceptionIfAppDefaultInstancesIsOutOfRange {
//}
//
//- (void)testGetConfiguredTargetsReadsLocalConfiguration {
//}
//
//- (void)testCreateConfiguredTargetAmendsLocalConfiguration {
//}
//
//- (void)testCreateConfiguredTargetThrowsExceptionIfCredentialsAreInvalid {
//}
//
//- (void)testCreateConfiguredTargetThrowsExceptionIfHostnameIsPreviouslyUsed {
//}
//
//- (void)testCreateConfiguredTargetThrowsExceptionIfHostnameIsInvalid {
//    
//}

@end
