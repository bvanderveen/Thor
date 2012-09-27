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
    
    NSLog(@"matching %@", matching);
    return YES;
}

@end

NSString *ThorBackendErrorDomain = @"com.tier3.thor.BackendErrorDomain";
static NSString *ThorDataStoreFile = @"ThorDataStore";

NSURL *ThorGetStoreURL(NSError **error) {
    NSFileManager *fileManager = [NSFileManager new];
    return [[fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:error] URLByAppendingPathComponent:ThorDataStoreFile];
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
        
        
        NSAttributeDescription *defaultMemory = [NSAttributeDescription new];
        defaultMemory.name = @"defaultMemory";
        defaultMemory.attributeType = NSInteger32AttributeType;
        defaultMemory.optional = NO;
        defaultMemory.defaultValue = [NSNumber numberWithInt:64];
        [defaultMemory setValidationPredicates:@[[NSPredicate predicateWithFormat:@"SELF > 0"], [NSPredicate predicateWithFormat:@"SELF < 99999"]]
                        withValidationWarnings:@[@"Memory too low", @"Memory too high"]];
        
        NSAttributeDescription *defaultInstances = [NSAttributeDescription new];
        defaultInstances.name = @"defaultInstances";
        defaultInstances.attributeType = NSInteger32AttributeType;
        defaultInstances.optional = NO;
        defaultInstances.defaultValue = [NSNumber numberWithInt:2];
        
        entity.properties = @[displayName, localRoot, defaultMemory, defaultInstances];
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
        hostname.name = @"hostname";
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
        
        NSAttributeDescription *displayName = [NSAttributeDescription new];
        displayName.name = @"displayName";
        displayName.attributeType = NSStringAttributeType;
        displayName.optional = YES; // TODO NO
        
        NSAttributeDescription *appName = [NSAttributeDescription new];
        appName.name = @"appName";
        appName.attributeType = NSStringAttributeType;
        appName.optional = NO;
        
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
        
        entity.properties = @[displayName, appName, app, target];
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

@implementation App

@dynamic displayName, localRoot;

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

@dynamic displayName, hostname, email, password;

- (BOOL)validateHostname:(id *)hostname error:(NSError **)outError {
    if (*hostname == nil)
        return YES;
    
    if ([((NSString *)*hostname) rangeOfString:@"api."].location != 0) {
        NSError *error = [[NSError alloc] initWithDomain:ThorBackendErrorDomain code:TargetHostnameInvalid userInfo:[NSDictionary dictionaryWithObject:@"Hostname must start with \"api.\"" forKey:NSLocalizedDescriptionKey]];
        *outError = error;
        return NO;
    }
    return YES;
}

- (BOOL)performValidation:(NSError **)error {
    NSFetchRequest *request = [Target fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"email == %@ AND hostname == %@ AND self != %@", self.email, self.hostname, self];
    
    BOOL any = NO;
    
    if (![request anyInContext:self.managedObjectContext result:&any error:error])
        return NO;
    
    if (any) {
        *error = [NSError errorWithDomain:ThorBackendErrorDomain code:TargetHostnameAndEmailPreviouslyConfigured userInfo:[NSDictionary dictionaryWithObject:@"There is already a target with the given email and hostname" forKey:NSLocalizedDescriptionKey]];
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

@dynamic displayName, target, app, appName;
@synthesize memory, instances;

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
    request.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"app == %@", app];
    return [self.context executeFetchRequest:request error:error];
}

- (NSArray *)getDeploymentsForTarget:(Target *)target error:(NSError **)error {
    return @[];
}

- (Target *)getTargetForDeployment:(Deployment *)deployment error:(NSError **)error {
    NSFetchRequest *request = [Target fetchRequest];
    return [[self.context executeFetchRequest:request error:error] objectAtIndex:0];
}

@end
