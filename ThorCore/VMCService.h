#import "ThorBackend.h"
#import "VMCOperations.h"

@interface VMCDeployment : NSObject

@property (nonatomic, copy) NSString *name, *cpu, *memory, *disk;

@end

@interface VMCTarget : NSObject

@property (nonatomic, copy) NSString *hostname, *email, *password;

@end

@protocol VMCService <NSObject>

- (NSArray *)getDeploymentsForTarget:(Target *)target error:(NSError **)error;
- (NSArray *)getInstanceStatsForAppName:(NSString *)appname target:(VMCTarget *)target error:(NSError **)error;

@end

@interface FixtureVMCService : NSObject <VMCService>

@end


extern NSString *VMCServiceErrorDomain;

static NSInteger FailedToTarget = 1;
static NSInteger FailedToLogin = 2;

@interface VMCServiceImpl : NSObject <VMCService>

- (id)initWithVMCOperations:(id<VMCOperations>)vmc;

@end

@interface VMCService : NSObject

+ (id<VMCService>)shared;

@end