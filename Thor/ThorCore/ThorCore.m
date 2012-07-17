#import "ThorCore.h"

static NSString *ThorErrorDomain = @"com.tier3.thor.ErrorDomain";
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

NSManagedObjectModel *getManagedObjectModel() {
    static NSManagedObjectModel *model = nil;
    
    if (!model) {
        model = [[NSManagedObjectModel alloc] init];
        model.entities = [NSArray arrayWithObjects:
                        getAppEntity(),
                        nil];
    }
    
    return model;
}

NSManagedObjectContext *ThorGetObjectContext(NSURL *storeURL, NSError **error) {
    static NSManagedObjectContext *context = nil;
    
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


- (NSDictionary *)dictionaryRepresentation {
    return nil;
}

+ (NSFetchRequest *)fetchRequest {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = getAppEntity();
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
    App *app = [App appWithDictionary:appDict insertIntoManagedObjectContext:self.context];
    return [self.context save:error] ? app : nil;
}

@end
