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
    NSError *fetchWithLocalRootError = nil;
    NSArray *withSameLocalRoot = [context executeFetchRequest:self error:&fetchWithLocalRootError];
    
    if (fetchWithLocalRootError) {
        *outError = fetchWithLocalRootError;
        return NO;
    }
    
    *outResult = withSameLocalRoot.count;
    return YES;
}

@end

NSString *ThorErrorDomain = @"com.tier3.thor.ErrorDomain";
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
        [defaultMemory setValidationPredicates:[NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"SELF > 0"], [NSPredicate predicateWithFormat:@"SELF < 99999"], nil] 
                        withValidationWarnings:[NSArray arrayWithObjects:@"Memory too low", @"Memory too high", nil]];
        
        NSAttributeDescription *defaultInstances = [NSAttributeDescription new];
        defaultInstances.name = @"defaultInstances";
        defaultInstances.attributeType = NSInteger32AttributeType;
        defaultInstances.optional = NO;
        defaultInstances.defaultValue = [NSNumber numberWithInt:2];
        
        entity.properties = [NSArray arrayWithObjects:displayName, localRoot, defaultMemory, defaultInstances, nil];
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
        
        entity.properties = [NSArray arrayWithObjects:displayName, hostname, email, password, nil];
    }
    
    return entity;
}

NSManagedObjectModel *getManagedObjectModel() {
    static NSManagedObjectModel *model = nil;
    
    if (!model) {
        model = [[NSManagedObjectModel alloc] init];
        model.entities = [NSArray arrayWithObjects:
                        getAppEntity(),
                        getTargetEntity(),
                        nil];
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

@dynamic displayName, localRoot, defaultMemory, defaultInstances;

+ (App *)appWithDictionary:(NSDictionary *)dictionary insertIntoManagedObjectContext:(NSManagedObjectContext *)context {
    App *app = (App *)[[NSManagedObject alloc] initWithEntity:[[getManagedObjectModel() entitiesByName] objectForKey:@"App"] insertIntoManagedObjectContext:context];
    
    app.localRoot = [dictionary objectForKey:@"localRoot"];
    app.displayName = [dictionary objectForKey:@"displayName"];
    app.defaultMemory = [dictionary objectForKey:@"defaultMemory"];
    app.defaultInstances = [dictionary objectForKey:@"defaultInstances"];
    return app;
}

+ (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = getAppEntity();
    return request;
}

@end

@implementation Target

@dynamic displayName, hostname, email, password;

- (BOOL)validateHostname:(id *)hostname error:(NSError **)outError {
    if (*hostname == nil)
        return YES;
    
    if ([((NSString *)*hostname) rangeOfString:@"api."].location != 0) {
        NSError *error = [[NSError alloc] initWithDomain:ThorErrorDomain code:TargetHostnameInvalid userInfo:[NSDictionary dictionaryWithObject:@"Hostname must start with \"api.\"" forKey:NSLocalizedDescriptionKey]];
        *outError = error;
        return NO;
    }
    return YES;
}

- (BOOL)validateForUpdate:(NSError *__autoreleasing *)error {
    if (![super validateForUpdate:error])
        return NO;
    
    NSFetchRequest *request = [Target fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"email == %@ AND hostname == %@ AND self != %@", self.email, self.hostname, self];
    
    BOOL any = NO;
    
    if (![request anyInContext:self.managedObjectContext result:&any error:error])
        return NO;
    
    if (any) {
        *error = [NSError errorWithDomain:ThorErrorDomain code:TargetHostnameAndEmailPreviouslyConfigured userInfo:[NSDictionary dictionaryWithObject:@"There is already a target with the given email and hostname" forKey:NSLocalizedDescriptionKey]];
        return NO;
    }

    return YES;
}

+ (Target *)targetInsertedIntoManagedObjectContext:(NSManagedObjectContext *)context {
    return (Target *)[[NSManagedObject alloc] initWithEntity:[[getManagedObjectModel() entitiesByName] objectForKey:@"Target"] insertIntoManagedObjectContext:context];
}

+ (Target *)targetWithDictionary:(NSDictionary *)dictionary insertIntoManagedObjectContext:(NSManagedObjectContext *)context {
    Target *target = [self targetInsertedIntoManagedObjectContext:context];
    target.displayName = [dictionary objectForKey:@"displayName"];
    target.hostname = [dictionary objectForKey:@"hostname"];
    target.email = [dictionary objectForKey:@"email"];
    target.password = [dictionary objectForKey:@"password"];
    return target;
}

+ (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = getTargetEntity();
    return request;
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
    request.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES]];
    return [self.context executeFetchRequest:request error:error];
}

- (App *)createConfiguredApp:(NSDictionary *)appDict error:(NSError **)error {
    NSFetchRequest *request = [App fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"localRoot == %@", [appDict objectForKey:@"localRoot"]];
    
    BOOL any = NO;
    
    if (![request anyInContext:self.context result:&any error:error])
        return nil;
    
    if (any) {
        *error = [NSError errorWithDomain:ThorErrorDomain code:AppLocalRootInvalid userInfo:nil];
        return nil;
    }
    
    App *app = [App appWithDictionary:appDict insertIntoManagedObjectContext:self.context];
    return [self.context save:error] ? app : nil;
}


- (NSArray *)getConfiguredTargets:(NSError **)error {
    NSFetchRequest *request = [Target fetchRequest];
    request.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES]];
    return [self.context executeFetchRequest:request error:error];
}

- (Target *)createConfiguredTarget:(NSDictionary *)targetDict error:(NSError **)error {
    NSFetchRequest *request = [Target fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"email == %@ AND hostname == %@", [targetDict objectForKey:@"email"], [targetDict objectForKey:@"hostname"]];
    
    BOOL any = NO;
    
    if (![request anyInContext:self.context result:&any error:error])
        return nil;
    
    if (any) {
        *error = [NSError errorWithDomain:ThorErrorDomain code:TargetHostnameAndEmailPreviouslyConfigured userInfo:nil];
        return nil;
    }
    
    Target *target = [Target targetWithDictionary:targetDict insertIntoManagedObjectContext:self.context];
    return [self.context save:error] ? target : nil;
}

@end
