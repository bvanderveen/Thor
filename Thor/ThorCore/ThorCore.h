#import <CoreData/CoreData.h>

@interface Target : NSManagedObject

@property (copy) NSString *displayName, *hostname, *email, *password;

@end

@interface App : NSManagedObject

@property (strong) NSString *displayName, *localRoot;
@property (strong) NSNumber *defaultMemory, *defaultInstances;

+ (App *)appWithDictionary:(NSDictionary *)dictionary insertIntoManagedObjectContext:(NSManagedObjectContext *)context;
- (NSDictionary *)dictionaryRepresentation;

@end

@interface Deployment : NSManagedObject

@property (copy) NSString *displayName, *hostname, *appName;
@property (strong) NSNumber *memory, *instances;

@end

NSURL *ThorGetStoreURL(NSError **error);
NSManagedObjectContext *ThorGetObjectContext(NSURL *storeURL, NSError **error);

//static NSString *ThorErrorDomain;
//
//static NSInteger AppLocalRootInvalid = 1;
//static NSInteger AppMemoryOutOfRange = 2;
//static NSInteger AppInstancesOutOfRange = 3;

@protocol ThorBackend <NSObject>

- (NSArray *)getConfiguredApps:(NSError **)error;
- (App *)createConfiguredApp:(NSDictionary *)appDict error:(NSError **)error;
//- (void)updateConfiguredApp:(App *)app error:(NSError **)error;
//
//- (NSArray *)getConfiguredTargets;
//- (void)createConfiguredTarget:(Target *)target;
//
//- (NSArray *)getDeploymentsForApp:(App *)app;
//- (void)createDeploymentForApp:(App *)app target:(Target *)target;

@end

@interface ThorBackendImpl : NSObject <ThorBackend>

- (id)initWithObjectContext:(NSManagedObjectContext *)leContext;

@end