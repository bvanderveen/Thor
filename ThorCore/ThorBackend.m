#import "ThorBackend.h"
#import <objc/runtime.h>

static id<ThorBackend> sharedBackend = nil;
static NSManagedObjectContext *sharedContext = nil;
@implementation ThorBackend

+ (NSManagedObjectContext *)sharedContext {
    if (!sharedContext) {
        // TODO handle errors in initialization
        NSError *error = nil;
        sharedContext = ThorGetObjectContext(ThorGetStoreURL(&error), &error);
    }
    return sharedContext;
}

+ (id<ThorBackend>)shared {
    if (!sharedBackend) {
        sharedBackend = [[ThorBackendImpl alloc] initWithObjectContext:[self sharedContext]];
    }
    return sharedBackend;
}

@end

@implementation NSObject (DictionaryRepresentation)

- (NSDictionary *)dictionaryRepresentation {
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);
    for (int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        NSString *name = [[NSString alloc] initWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        id value = [self valueForKey:name];
        [result setObject:value forKey:name];
    }
    
    free(properties);
    
    return [result copy];
}

@end

@interface NSFetchRequest (Helpers)

- (BOOL)anyInContext:(NSManagedObjectContext *)context result:(BOOL*)outResult error:(NSError **)outError;

@end

@implementation NSFetchRequest (Helpers)

- (BOOL)anyInContext:(NSManagedObjectContext *)context result:(BOOL*)outResult error:(NSError **)outError {
    NSError *fetchError = nil;
    NSArray *matching = [context executeFetchRequest:self error:&fetchError];
    
    if (fetchError) {
        *outError = fetchError;
        return NO;
    }
    
    *outResult = matching.count > 0;
    
    return YES;
}

@end

NSString *ThorBackendErrorDomain = @"com.tier3.thor.BackendErrorDomain";
static NSString *ThorDataStoreFile = @"ThorDataStore";

NSURL *ThorGetStoreURL(NSError **error) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationSupportDir = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:error];
    
    NSURL *thorDir = [applicationSupportDir URLByAppendingPathComponent:@"Thor"];
    [fileManager createDirectoryAtURL:thorDir withIntermediateDirectories:YES attributes:nil error:error];
    
    return [thorDir URLByAppendingPathComponent:ThorDataStoreFile];
}

NSEntityDescription *getAppEntity() {
    static NSEntityDescription *entity = nil;
    
    if (!entity) {
        entity = [NSEntityDescription new];
        entity.name = @"App";
        entity.managedObjectClassName = @"App";
        
        NSAttributeDescription *displayName = [NSAttributeDescription new];
        displayName.name = @"displayName";
        displayName.attributeType = NSStringAttributeType;
        displayName.optional = NO;
        
        NSAttributeDescription *localRoot = [NSAttributeDescription new];
        localRoot.name = @"localRoot";
        localRoot.attributeType = NSStringAttributeType;
        localRoot.optional = NO;
        
        entity.properties = @[displayName, localRoot];
    }
    
    return entity;
}

NSEntityDescription *getTargetEntity() {
    static NSEntityDescription *entity = nil;
    
    if (!entity) {
        entity = [NSEntityDescription new];
        entity.name = @"Target";
        entity.managedObjectClassName = @"Target";
        
        NSAttributeDescription *displayName = [NSAttributeDescription new];
        displayName.name = @"displayName";
        displayName.attributeType = NSStringAttributeType;
        displayName.optional = NO;
        
        NSAttributeDescription *hostname = [NSAttributeDescription new];
        hostname.name = @"hostURL";
        hostname.attributeType = NSStringAttributeType;
        hostname.optional = NO;
        
        NSAttributeDescription *email = [NSAttributeDescription new];
        email.name = @"email";
        email.attributeType = NSStringAttributeType;
        email.optional = NO;
        
        NSAttributeDescription *password = [NSAttributeDescription new];
        password.name = @"password";
        password.attributeType = NSStringAttributeType;
        password.optional = NO;
        
        entity.properties = @[displayName, hostname, email, password];
    }
    
    return entity;
}

NSEntityDescription *getDeploymentEntity(NSEntityDescription *appEntity, NSEntityDescription *targetEntity) {
    static NSEntityDescription *entity = nil;
    
    if (!entity) {
        entity = [NSEntityDescription new];
        entity.name = @"Deployment";
        entity.managedObjectClassName = @"Deployment";
        
        NSAttributeDescription *name = [NSAttributeDescription new];
        name.name = @"name";
        name.attributeType = NSStringAttributeType;
        name.optional = NO;
        
        NSRelationshipDescription *app = [NSRelationshipDescription new];
        app.name = @"app";
        app.destinationEntity = appEntity;
        app.minCount = 1;
        app.maxCount = 1;
        app.deleteRule = NSNoActionDeleteRule;

        NSRelationshipDescription *appInv = [NSRelationshipDescription new];
        appInv.name = @"deployments";
        appInv.destinationEntity = entity;
        appInv.minCount = 0;
        appInv.deleteRule = NSCascadeDeleteRule;

        app.inverseRelationship = appInv;
        appInv.inverseRelationship = app;
        
        appEntity.properties = [appEntity.properties arrayByAddingObject:appInv];
        
        NSRelationshipDescription *target = [NSRelationshipDescription new];
        target.name = @"target";
        target.destinationEntity = targetEntity;
        target.minCount = 1;
        target.maxCount = 1;
        target.deleteRule = NSNoActionDeleteRule;
        
        NSRelationshipDescription *targetInv = [NSRelationshipDescription new];
        targetInv.name = @"deployments";
        targetInv.destinationEntity = entity;
        targetInv.minCount = 0;
        targetInv.deleteRule = NSCascadeDeleteRule;
        
        target.inverseRelationship = targetInv;
        targetInv.inverseRelationship = target;
        
        targetEntity.properties = [targetEntity.properties arrayByAddingObject:targetInv];
        
        entity.properties = @[name, app, target];
    }
    
    return entity;
}

NSManagedObjectModel *getManagedObjectModel() {
    static NSManagedObjectModel *model = nil;
    
    if (!model) {
        
        NSEntityDescription *appEntity = getAppEntity();
        NSEntityDescription *targetEntity = getTargetEntity();
        NSEntityDescription *deploymentEntity = getDeploymentEntity(appEntity, targetEntity);
        
        model = [[NSManagedObjectModel alloc] init];
        model.entities = @[appEntity, targetEntity, deploymentEntity];
    }
    
    return model;
}

static NSManagedObjectContext *context = nil;

void ThorEjectObjectContext() {
    context = nil;
}

NSManagedObjectContext *ThorGetObjectContext(NSURL *storeURL, NSError **error) {
    if (!context) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:getManagedObjectModel()];
        
        NSPersistentStore *store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                  configuration:nil
                                            URL:storeURL
                                        options:nil
                                          error:error];
        
        if (!store) 
            return nil;
        
        context = [[NSManagedObjectContext alloc] init];
        context.persistentStoreCoordinator = coordinator;
    }
    
    return context;
}

@interface NSError (ThorError)

+ (NSError *)thorErrorWithCode:(NSInteger)code localizedDescription:(NSString *)localizedDescription;

@end

@implementation NSError (ThorError)

+ (NSError *)thorErrorWithCode:(NSInteger)code localizedDescription:(NSString *)localizedDescription {
    return [NSError errorWithDomain:ThorBackendErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey : localizedDescription }];
}

@end

@implementation App

@dynamic displayName, localRoot;

- (NSString *)lastPathComponent {
    return [[[((NSURL *)[NSURL fileURLWithPath:self.localRoot]).pathComponents lastObject] componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

+ (App *)appInsertedIntoManagedObjectContext:(NSManagedObjectContext *)context {
    return (App *)[[NSManagedObject alloc] initWithEntity:[getManagedObjectModel() entitiesByName][@"App"] insertIntoManagedObjectContext:context];
}

+ (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = getAppEntity();
    return request;
}

- (BOOL)performValidation:(NSError **)error {
    NSFetchRequest *request = [App fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"localRoot == %@ AND self != %@", self.localRoot, self];
    
    BOOL any = NO;
    NSLog(@"Performing validation on app with local root %@", self.localRoot);
    
    if (![request anyInContext:self.managedObjectContext result:&any error:error])
        return NO;
    
    if (any) {
        *error = [NSError errorWithDomain:ThorBackendErrorDomain code:AppLocalRootInvalid userInfo:nil];
        NSLog(@"Failed validation for app root");
        return NO;
    }
    
    return YES;
}

- (BOOL)validateForInsert:(NSError **)error {
    if (![super validateForInsert:error])
        return NO;
    
    return [self performValidation:error];
}

- (BOOL)validateForUpdate:(NSError *__autoreleasing *)error {
    if (![super validateForUpdate:error])
        return NO;
    
    return [self performValidation:error];
}

@end

@implementation Target

@dynamic displayName, hostURL, email, password;

- (BOOL)performValidation:(NSError **)error {
    
    NSURL *validURL = [NSURL URLWithString:self.hostURL];
    
    if (!validURL) {
        *error = [NSError thorErrorWithCode:TargetHostnameInvalid localizedDescription:@"The hostname is invalid."];
        return NO;
    }
    
    NSFetchRequest *request = [Target fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"email == %@ AND hostURL == %@ AND self != %@", self.email, self.hostURL, self];
    
    BOOL any = NO;
    
    if (![request anyInContext:self.managedObjectContext result:&any error:error])
        return NO;
    
    if (any) {
        *error = [NSError thorErrorWithCode:TargetHostnameAndEmailPreviouslyConfigured localizedDescription:@"There is already a target with the given email and hostname."];
        return NO;
    }
    
    return YES;
}

- (BOOL)validateForInsert:(NSError **)error {
    if (![super validateForInsert:error])
        return NO;
    
    return [self performValidation:error];
}

- (BOOL)validateForUpdate:(NSError **)error {
    if (![super validateForUpdate:error])
        return NO;
    
    return [self performValidation:error];
}

+ (Target *)targetInsertedIntoManagedObjectContext:(NSManagedObjectContext *)context {
    return (Target *)[[NSManagedObject alloc] initWithEntity:[getManagedObjectModel() entitiesByName][@"Target"] insertIntoManagedObjectContext:context];
}

+ (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = getTargetEntity();
    return request;
}

@end

@implementation Deployment

@dynamic target, app, name;

- (BOOL)performValidation:(NSError **)error {
    
    if (!self.target) {
        *error = [NSError thorErrorWithCode:DeploymentTargetNotGiven localizedDescription:@"Target for deployment was not given."];
        return NO;
    }
    
    if (!self.app) {
        *error = [NSError thorErrorWithCode:DeploymentAppNotGiven localizedDescription:@"App for deployment was not given."];
        return NO;
    }
    
    if (!self.name) {
        *error = [NSError thorErrorWithCode:DeploymentAppNameNotGiven localizedDescription:@"App name for deployment was not given."];
        return NO;
    }
    
    NSFetchRequest *request = [Deployment fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"target == %@ AND app == %@ AND name == %@ AND self != %@", self.target, self.app, self.name, self];
    
    BOOL any = NO;
    
    if (![request anyInContext:self.managedObjectContext result:&any error:error])
        return NO;
    
    if (any) {
        *error = [NSError thorErrorWithCode:DeploymentAppNameInUse localizedDescription:@"An app with the given name is already configued for the target."];
        return NO;
    }
    
    return YES;
}

- (BOOL)validateForInsert:(NSError **)error {
    if (![self performValidation:error])
        return NO;
    
    return [super validateForInsert:error];
}

- (BOOL)validateForUpdate:(NSError *__autoreleasing *)error {
    if (![self performValidation:error])
        return NO;
    
    return [super validateForUpdate:error];
}

+ (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = getDeploymentEntity(getAppEntity(), getTargetEntity());
    return request;
}


+ (Deployment *)deploymentInsertedIntoManagedObjectContext:(NSManagedObjectContext *)context {
    return (Deployment *)[[NSManagedObject alloc] initWithEntity:[getManagedObjectModel() entitiesByName][@"Deployment"] insertIntoManagedObjectContext:context];
}


@end

@interface ThorBackendImpl ()

@property (nonatomic, strong) NSManagedObjectModel *model;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation ThorBackendImpl

@synthesize model, context;

- (id)initWithObjectContext:(NSManagedObjectContext *)leContext {
    if (self = [super init]) {
        model = getManagedObjectModel();
        context = leContext;
    }
    return self;
}

- (NSArray *)getConfiguredApps:(NSError **)error {
    NSFetchRequest *request = [App fetchRequest];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES]];
    return [self.context executeFetchRequest:request error:error];
}

- (NSArray *)getConfiguredTargets:(NSError **)error {
    NSFetchRequest *request = [Target fetchRequest];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES]];
    return [self.context executeFetchRequest:request error:error];
}

- (NSArray *)getDeploymentsForApp:(App *)app error:(NSError **)error {
    NSFetchRequest *request = [Deployment fetchRequest];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"app == %@", app];
    return [self.context executeFetchRequest:request error:error];
}

- (NSArray *)getDeploymentsForTarget:(Target *)target error:(NSError **)error {
    NSFetchRequest *request = [Deployment fetchRequest];
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"target == %@", target];
    return [self.context executeFetchRequest:request error:error];
}

- (Target *)getTargetForDeployment:(Deployment *)deployment error:(NSError **)error {
    NSFetchRequest *request = [Target fetchRequest];
    return [[self.context executeFetchRequest:request error:error] objectAtIndex:0];
}

@end
