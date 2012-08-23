#import "ThorBackendTests.h"
#import "ThorBackend.h"

@interface ThorBackendTests ()

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) ThorBackendImpl *backend;
@property (nonatomic, copy) NSString *tempStorePath;

- (void)saveContext;

@end

@interface ThorBackendTests (Fixtures)

@end

@implementation ThorBackendTests (Fixtures)

- (NSArray *)createApps {
    return [NSArray arrayWithObjects:
            [self createApp],
            [self createApp],
            [self createApp],
            nil];
}

- (App *)createApp {
    static int counter = 0;
    counter++;
    
    App *result = [App appInsertedIntoManagedObjectContext:self.context];
    result.displayName = [NSString stringWithFormat:@"App %d", counter];
    result.localRoot = [NSString stringWithFormat:@"/path/to/app%d", counter];
    
    NSLog(@"returning app with local root %@", result.localRoot);
    return result;
}

- (NSArray *)createTargets {
    return [NSArray arrayWithObjects:
            [self createTarget],
            [self createTarget],
            [self createTarget],
            nil];
}

- (Target *)createTarget {
    static int counter = 0;
    counter++;
    
    Target *result = [Target targetInsertedIntoManagedObjectContext:self.context];
    result.displayName = [NSString stringWithFormat:@"Target %d", counter];
    result.hostname = [NSString stringWithFormat:@"api.target%d.foo.com", counter];
    result.email = [NSString stringWithFormat:@"user%d@foo.com", counter];
    result.password = [NSString stringWithFormat:@"password%d", counter];
    return result;
}

@end

@interface ThorBackendTests (Assertions)

- (void)assertActualObjects:(NSArray *)actualObjects equalExpectedObjects:(NSArray *)expectedObjects;
- (void)assertError:(NSError *)error hasDomain:(NSString *)domain andCode:(NSInteger)code;

@end

@implementation ThorBackendTests (Assertions)

- (void)assertActualObjects:(NSArray *)actualObjects equalExpectedObjects:(NSArray *)expectedObjects {
    for (int i = 0; i < actualObjects.count; i++)
        STAssertEqualObjects([actualObjects objectAtIndex:i], [expectedObjects objectAtIndex:i], @"objects differed at index %d", i);
    
    STAssertEquals(expectedObjects.count, actualObjects.count, @"object count mismatch");
        
}

- (void)assertError:(NSError *)error hasDomain:(NSString *)domain andCode:(NSInteger)code {
    STAssertNotNil(error, @"Expected non-nil error");
    STAssertEqualObjects(error.domain, domain, @"Unexpected error domain");
    STAssertEquals(error.code, code, @"Unexpected error code");
}

@end

@implementation ThorBackendTests

@synthesize context, backend, tempStorePath;

- (void)saveContext {
    NSError *error = nil;
    [self.context save:&error];
    STAssertNil(error, @"Error saving context %@", error.localizedDescription);
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
    ThorEjectObjectContext();
    
    NSError *error = nil;
    if (![[NSFileManager new] removeItemAtPath:self.tempStorePath error:&error])
        NSLog(@"failed to remove temp store: %@", error.localizedDescription);
    
    [super tearDown];
}

- (void)testGetConfiguredAppsReadsContext {
    NSArray *expectedApps = [self createApps];
    [self saveContext];
    
    NSError *error = nil;
    NSArray *actualApps = [self.backend getConfiguredApps:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    [self assertActualObjects:actualApps equalExpectedObjects:expectedApps];
}

- (void)testInsertingAppReturnsErrorIfAppLocalPathIsPreviouslyUsed {
    App *app0 = [self createApp];
    [self saveContext];
    
    App *app1 = [self createApp];
    app1.localRoot = app0.localRoot;
    
    NSError *error = nil;
    [context save:&error];
    
    [self assertError:error hasDomain:ThorBackendErrorDomain andCode:AppLocalRootInvalid];
}

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

- (void)testGetConfiguredTargetsReadsContext {
    NSArray *expectedTargets = [self createTargets];
    [self saveContext];
    
    NSError *error = nil;
    NSArray *actualTargets = [self.backend getConfiguredTargets:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    [self assertActualObjects:actualTargets equalExpectedObjects:expectedTargets];
}
//
//- (void)testCreateConfiguredTargetAmendsLocalConfiguration {
//    NSDictionary *targetDict = [self createTarget];
//    
//    NSError *error = nil;
//    
//    
//    Target *target = [Target targetWithDictionary:targetDict insertIntoManagedObjectContext:self.context];
//    
//    [self.context save:&error];
//    
//    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
//    STAssertNotNil(target, @"Expected result");
//    
//    STAssertEqualObjects([target dictionaryRepresentation], targetDict, @"Returned target and given target differ");
//    [self assertObjectExistsInLocalConfiguration:targetDict fetchRequest:[Target fetchRequest]];
//    
//}

- (void)testCreateConfiguredTargetReturnsErrorIfEmailAndHostnameArePreviouslyUsed {
    Target *target0 = [self createTarget];
    [self saveContext];
    
    Target *target1 = [self createTarget];
    
    target1.email = target0.email;
    target1.hostname = target0.hostname;
    
    NSError *error = nil;
    [context save:&error];
    
    [self assertError:error hasDomain:ThorBackendErrorDomain andCode:TargetHostnameAndEmailPreviouslyConfigured];
}

//
//- (void)testCreateConfiguredTargetThrowsExceptionIfCredentialsAreInvalid {
//}
//
//
//- (void)testCreateConfiguredTargetThrowsExceptionIfHostnameIsInvalid {
//    
//}

@end
