#import <CoreData/CoreData.h>

@interface NSObject (DictionaryRepresentation)

- (NSDictionary *)dictionaryRepresentation;

@end

@interface Target : NSManagedObject

@property (copy) NSString *displayName, *hostname, *email, *password;

+ (NSFetchRequest *)fetchRequest;

+ (Target *)targetWithDictionary:(NSDictionary *)dictionary insertIntoManagedObjectContext:(NSManagedObjectContext *)context;

@end

@interface App : NSManagedObject

@property (strong) NSString *displayName, *localRoot;
@property (strong) NSNumber *defaultMemory, *defaultInstances;

+ (NSFetchRequest *)fetchRequest;

+ (App *)appWithDictionary:(NSDictionary *)dictionary insertIntoManagedObjectContext:(NSManagedObjectContext *)context;

@end

@interface Deployment : NSManagedObject

@property (copy) NSString *displayName, *hostname, *appName;
@property (strong) NSNumber *memory, *instances;

@end

NSURL *ThorGetStoreURL(NSError **error);
NSManagedObjectContext *ThorGetObjectContext(NSURL *storeURL, NSError **error);
void ThorEjectObjectContext();

extern NSString *ThorErrorDomain;

static NSInteger AppLocalRootInvalid = 1;
//static NSInteger AppMemoryOutOfRange = 2;
//static NSInteger AppInstancesOutOfRange = 3;

@protocol ThorBackend <NSObject>

- (NSArray *)getConfiguredApps:(NSError **)error;
- (App *)createConfiguredApp:(NSDictionary *)appDict error:(NSError **)error;
//- (void)updateConfiguredApp:(App *)app error:(NSError **)error;


- (NSArray *)getConfiguredTargets:(NSError **)error;
- (void)createConfiguredTarget:(NSDictionary *)targetDict error:(NSError **)error;

//- (NSArray *)getDeploymentsForApp:(App *)app;
//- (void)createDeploymentForApp:(App *)app target:(Target *)target;

@end

@interface ThorBackendImpl : NSObject <ThorBackend>

- (id)initWithObjectContext:(NSManagedObjectContext *)leContext;

@end