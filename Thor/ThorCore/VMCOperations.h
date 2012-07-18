
@interface DeploymentInfo : NSObject 

// status, mapped urls, memory amount, num instances, instance resource usage (?), etc

@end

// all operations are considered long-running.
// objects should not be accessed from the UI thread.
@protocol VMCOperations <NSObject>

- (BOOL)targetHostname:(NSString *)target;
- (BOOL)loginWithEmail:(NSString *)username password:(NSString *)password;
- (NSArray *)getApps;
- (DeploymentInfo *)getInfoForAppName:(NSString *)appName;

@end

typedef NSString * (^SynchronousExecuteShellBlock)(NSString *, NSArray *);

SynchronousExecuteShellBlock SynchronousExecuteShell;

@interface VMCOperationsImpl : NSObject <VMCOperations>

- (id)initWithShellBlock:(SynchronousExecuteShellBlock)shellBlock;

@end