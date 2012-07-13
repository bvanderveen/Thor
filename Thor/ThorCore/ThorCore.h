#import "Target.h"

@interface ThorUserData : NSObject

- (void)createTarget:(Target *)target;
- (NSArray *)getTargets;

@end



// all operations are considered long-running.
// objects should not be accessed from the UI thread.
@protocol VMCOperations <NSObject>

@property (nonatomic, copy) NSString *target;
@property (nonatomic, strong) Credentials *credentials;

- (NSArray *)getApps;



@end


@interface Credentials : NSObject

@property (nonatomic, copy) NSString *email, *password;

@end

@interface Target : NSObject

@property (nonatomic, copy) NSString *displayName, *hostname;
@property (nonatomic, strong) Credentials *credentials;

@end

@interface App : NSObject

@property (nonatomic, copy) NSString *displayName, *localRoot;
@property (nonatomic, assign) NSInteger defaultMemory, defaultInstances;

@end

@interface Deployment : NSObject

@property (nonatomic, copy) NSString *displayName, *hostname, *appName;
@property (nonatomic, assign) NSInteger memory, instances;

@end

@interface DeploymentInfo : NSObject 

// status, mapped urls, memory amount, num instances, instance resource usage (?), etc

@end

@protocol ThorBackend <NSObject>

- (NSArray *)getConfiguredApps;
- (void)createConfiguredApp:(App *)app;
- (void)updateConfiguredApp:(App *)app;

- (NSArray *)getConfiguredTargets;
- (void)createConfiguredTarget:(Target *)target;

- (NSArray *)getDeploymentsForApp:(App *)app;
- (void)createDeploymentForApp:(App *)app target:(Target *)target;

@end

@interface TargetOperations : NSObject

@end

@interface ThorCore : NSObject

@end
