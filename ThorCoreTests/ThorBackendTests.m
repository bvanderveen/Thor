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
    return @[[self createApp],
            [self createApp],
            [self createApp]];
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
    return @[[self createTarget],
            [self createTarget],
            [self createTarget]];
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
    STAssertNotNil(error, @"Expected non-nil error.");
    STAssertEqualObjects(error.domain, domain, @"Unexpected error domain. Localized description: %@", error.localizedDescription);
    STAssertEquals(error.code, code, @"Unexpected error code. Localized description: %@", error.localizedDescription);
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
        NSLog(@"failed to create test context: %@", error.localizedDescription);
    
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

- (void)testCreateDeploymentFailsIfAppNotSet {
    Target *target = [self createTarget];
    NSError *error;
    [context save:&error];
    
    Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:context];
    deployment.name = @"foo";
    deployment.target = target;
    
    [context save:&error];
    
    [self assertError:error hasDomain:ThorBackendErrorDomain andCode:DeploymentAppNotGiven];
}

- (void)testCreateDeploymentFailsIfTargetNotSet {
    App *app = [self createApp];
    NSError *error;
    [context save:&error];
    
    Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:context];
    deployment.name = @"foo";
    deployment.app = app;
    
    [context save:&error];
    
    [self assertError:error hasDomain:ThorBackendErrorDomain andCode:DeploymentTargetNotGiven];
}

- (void)testCreateDeploymentFailsIfAppNameNotSet {
    App *app = [self createApp];
    Target *target = [self createTarget];
    NSError *error;
    [context save:&error];
    
    Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:context];
    deployment.app = app;
    deployment.target = target;
    
    [context save:&error];
    
    [self assertError:error hasDomain:ThorBackendErrorDomain andCode:DeploymentAppNameNotGiven];
}

- (void)testCreateDeploymentFailsIfAppNameAlreadyUsed {
    App *app = [self createApp];
    Target *target = [self createTarget];
    
    Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:context];
    deployment.app = app;
    deployment.target = target;
    deployment.name = @"foo";
    
    NSError *error;
    [context save:&error];
    
    Deployment *deployment2 = [Deployment deploymentInsertedIntoManagedObjectContext:context];
    deployment2.app = app;
    deployment2.target = target;
    deployment2.name = @"foo";
    
    [context save:&error];
    
    [self assertError:error hasDomain:ThorBackendErrorDomain andCode:DeploymentAppNameInUse];
}

- (void)testGetDeploymentsForAppReturnsNoDeploymentsIfAppHasNoDeployments {
    App *app = [self createApp];
    NSError *error;
    [context save:&error];
    
    NSArray *result = [backend getDeploymentsForApp:app error:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    STAssertEquals(((NSUInteger)result.count), ((NSUInteger)0), @"Expected no results.");
}

- (void)testGetDeploymentsForAppReturnsDeploymentsForApp {
    App *app = [self createApp];
    Target *target = [self createTarget];
    
    Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:context];
    deployment.app = app;
    deployment.target = target;
    deployment.name = @"foo";
    
    NSError *error;
    [context save:&error];
    
    NSArray *result = [backend getDeploymentsForApp:app error:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    NSUInteger count = result.count;
    NSUInteger expected = 1;
    STAssertEquals(count, expected, @"Expected 1 result.");
    STAssertEquals(((Deployment *)result[0]).name, @"foo", @"Expected app named 'foo'.");
}

- (void)testGetDeploymentsForTargetReturnsNoDeploymentsIfTargetHasNoDeployments {
    Target *target = [self createTarget];
    NSError *error;
    [context save:&error];
    
    NSArray *result = [backend getDeploymentsForTarget:target error:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    NSUInteger count = result.count;
    NSUInteger expected = 0;
    STAssertEquals(count, expected, @"Expected no results.");
}

- (void)testGetDeploymentsForTargetReturnsDeploymentsForTarget {
    App *app = [self createApp];
    Target *target = [self createTarget];
    
    Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:context];
    deployment.app = app;
    deployment.target = target;
    deployment.name = @"foo";
    
    NSError *error;
    [context save:&error];
    
    NSArray *result = [backend getDeploymentsForTarget:target error:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    NSUInteger count = result.count;
    NSUInteger expectedCount = 1;
    STAssertEquals(count, expectedCount, @"Expected 1 result.");
    STAssertEquals(((Deployment *)result[0]).name, @"foo", @"Expected app named 'foo'.");
}

@end
