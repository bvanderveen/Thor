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

@property (strong) NSString *displayName, *localRoot;
@property (strong) NSNumber *defaultMemory, *defaultInstances;

+ (NSFetchRequest *)fetchRequest;

+ (App *)appInsertedIntoManagedObjectContext:(NSManagedObjectContext *)context;

@end

@interface Deployment : NSObject

@property (copy) NSString *displayName, *hostname, *appName;

@end

NSURL *ThorGetStoreURL(NSError **error);
NSManagedObjectContext *ThorGetObjectContext(NSURL *storeURL, NSError **error);
void ThorEjectObjectContext();

extern NSString *ThorBackendErrorDomain;

static NSInteger AppLocalRootInvalid = 1;
static NSInteger TargetHostnameInvalid = 2;
static NSInteger TargetHostnameAndEmailPreviouslyConfigured = 3;

@protocol ThorBackend <NSObject>

- (NSArray *)getConfiguredApps:(NSError **)error;
- (NSArray *)getConfiguredTargets:(NSError **)error;

@end

@interface ThorBackendImpl : NSObject <ThorBackend>

- (id)initWithObjectContext:(NSManagedObjectContext *)leContext;

@end


@interface ThorBackend : NSObject

+ (NSManagedObjectContext *)sharedContext;
+ (id<ThorBackend>)shared;

@end