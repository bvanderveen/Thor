#import <CoreData/CoreData.h>

@interface NSObject (DictionaryRepresentation)

- (NSDictionary *)dictionaryRepresentation;

@end

@interface Target : NSManagedObject

@property (copy) NSString *displayName, *hostname, *email, *password;

+ (NSFetchRequest *)fetchRequest;

+ (Target *)targetInsertedIntoManagedObjectContext:(NSManagedObjectContext *)context;

@end

@interface App : NSManagedObject

@property (copy) NSString *displayName, *localRoot;
@property (readonly) NSString *lastPathComponent;

+ (NSFetchRequest *)fetchRequest;

+ (App *)appInsertedIntoManagedObjectContext:(NSManagedObjectContext *)context;

@end

@interface Deployment : NSManagedObject

@property (strong) Target *target;
@property (strong) App *app;
@property (copy) NSString *name;

+ (NSFetchRequest *)fetchRequest;
+ (Deployment *)deploymentInsertedIntoManagedObjectContext:(NSManagedObjectContext *)context;

@end

NSURL *ThorGetStoreURL(NSError **error);
NSManagedObjectContext *ThorGetObjectContext(NSURL *storeURL, NSError **error);
void ThorEjectObjectContext();

extern NSString *ThorBackendErrorDomain;

static NSInteger AppLocalRootInvalid = 1;
static NSInteger TargetHostnameInvalid = 2;
static NSInteger TargetHostnameAndEmailPreviouslyConfigured = 3;
static NSInteger DeploymentTargetNotGiven = 4;
static NSInteger DeploymentAppNotGiven = 5;
static NSInteger DeploymentAppNameNotGiven = 6;
static NSInteger DeploymentAppNameInUse = 7;

@protocol ThorBackend <NSObject>

- (NSArray *)getConfiguredApps:(NSError **)error;
- (NSArray *)getConfiguredTargets:(NSError **)error;
- (NSArray *)getDeploymentsForApp:(App *)app error:(NSError **)error;
- (NSArray *)getDeploymentsForTarget:(Target *)target error:(NSError **)error;
- (Target *)getTargetForDeployment:(Deployment *)deployment error:(NSError **)error;

@end

@interface ThorBackendImpl : NSObject <ThorBackend>

- (id)initWithObjectContext:(NSManagedObjectContext *)leContext;

@end


@interface ThorBackend : NSObject

+ (NSManagedObjectContext *)sharedContext;
+ (id<ThorBackend>)shared;

@end