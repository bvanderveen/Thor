
@interface DeploymentInfo : NSObject 

// status, mapped urls, memory amount, num instances, instance resource usage (?), etc

@end

// all operations are considered long-running.
// objects should not be accessed from the UI thread.
@protocol VMCOperations <NSObject>

@property (nonatomic, copy) NSString *target, *email, *password;

- (NSArray *)getApps;
- (DeploymentInfo *)getInfoForAppName:(NSString *)appName;

@end


@interface VMCOperationsImpl : NSObject <VMCOperations>

@end