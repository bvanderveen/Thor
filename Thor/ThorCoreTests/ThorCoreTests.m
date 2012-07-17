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
            nil];
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

- (NSArray *)createConfiguredTargets {
    return [NSArray arrayWithObjects:
            [Target targetWithDictionary:[self createTarget] insertIntoManagedObjectContext:self.context],
            [Target targetWithDictionary:[self createTarget] insertIntoManagedObjectContext:self.context],
            [Target targetWithDictionary:[self createTarget] insertIntoManagedObjectContext:self.context],
            nil];
}

- (NSDictionary *)createTarget {
    static int counter = 0;
    counter++;
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithFormat:@"Target %d", counter], @"displayName",
            [NSString stringWithFormat:@"api.target%d.foo.com", counter], @"hostname",
            [NSString stringWithFormat:@"user%d@foo.com", counter], @"email",
            [NSString stringWithFormat:@"password%d", counter], @"password",
            nil];
}

@end

@interface ThorBackendTests (Assertions)

- (void)assertActualObjects:(NSArray *)actualObjects equalExpectedObjects:(NSArray *)expectedObjects;
- (void)assertObjectExistsInLocalConfiguration:(NSDictionary *)dict fetchRequest:(NSFetchRequest *)request;
- (void)assertError:(NSError *)error hasDomain:(NSString *)domain andCode:(NSInteger)code;

@end

@implementation ThorBackendTests (Assertions)

- (void)assertActualObjects:(NSArray *)actualObjects equalExpectedObjects:(NSArray *)expectedObjects {
    for (int i = 0; i < actualObjects.count; i++)
        STAssertEqualObjects([actualObjects objectAtIndex:i], [expectedObjects objectAtIndex:i], @"objects differed at index %d", i);
    
    STAssertEquals(expectedObjects.count, actualObjects.count, @"object count mismatch");
        
}

- (void)assertObjectExistsInLocalConfiguration:(NSDictionary *)dict fetchRequest:(NSFetchRequest *)request {
    NSError *error = nil;
    NSArray *objects = [self.context executeFetchRequest:request error:&error];
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    
    BOOL found = NO;
    for (id o in objects)
        if ([[o dictionaryRepresentation] isEqual:dict])
            found = YES;
    
    STAssertTrue(found, @"did not find object %@", dict);
}

- (void)assertError:(NSError *)error hasDomain:(NSString *)domain andCode:(NSInteger)code {
    NSLog(@"heh %@ %@", ThorErrorDomain, error.domain);
    STAssertEqualObjects(domain, error.domain, @"Unexpected error domain");
    STAssertEquals(code, error.code, @"Unexpected error code");
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


- (void)testGetConfiguredAppsReadsLocalConfiguration {
    NSArray *expectedApps = [self createConfiguredApps];
    
    NSError *error = nil;
    NSArray *actualApps = [self.backend getConfiguredApps:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    [self assertActualObjects:actualApps equalExpectedObjects:expectedApps];
}

- (void)testCreateConfiguredAppAmendsLocalConfiguration {
    NSDictionary *appDict = [self createApp];
    
    NSError *error = nil;
    App *app = [self.backend createConfiguredApp:appDict error:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    STAssertNotNil(app, @"Expected result");
    STAssertEqualObjects([app dictionaryRepresentation], appDict, @"Returned app and given app differ");
    [self assertObjectExistsInLocalConfiguration:appDict fetchRequest:[App fetchRequest]];
}

- (void)testCreateConfiguredAppReturnsErrorIfAppLocalPathIsPreviouslyUsed {
    NSDictionary *appDict0 = [self createApp];
    NSDictionary *appDict1 = [[self createApp] mutableCopy];
    [appDict1 setValue:[appDict0 objectForKey:@"localRoot"] forKey:@"localRoot"];
    
    NSError *error = nil;
    [self.backend createConfiguredApp:appDict0 error:&error];
    App *app1 = [self.backend createConfiguredApp:appDict1 error:&error];
    
    STAssertNil(app1, @"Expected no result");
    [self assertError:error hasDomain:ThorErrorDomain andCode:AppLocalRootInvalid];
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

- (void)testGetConfiguredTargetsReadsLocalConfiguration {
    NSArray *expectedTargets = [self createConfiguredTargets];
    
    NSError *error = nil;
    NSArray *actualTargets = [self.backend getConfiguredTargets:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    [self assertActualObjects:actualTargets equalExpectedObjects:expectedTargets];
}

- (void)testCreateConfiguredTargetAmendsLocalConfiguration {
    NSDictionary *targetDict = [self createTarget];
    
    NSError *error = nil;
    Target *target = [self.backend createConfiguredTarget:targetDict error:&error];
    
    STAssertNil(error, @"Unexpected error %@", error.localizedDescription);
    STAssertNotNil(target, @"Expected result");
    STAssertEqualObjects([target dictionaryRepresentation], targetDict, @"Returned target and given target differ");
    [self assertObjectExistsInLocalConfiguration:targetDict fetchRequest:[Target fetchRequest]];
    
}
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
