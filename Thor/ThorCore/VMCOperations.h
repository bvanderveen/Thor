
@interface VMCInstanceStats : NSObject 

@property (nonatomic, assign) NSString *cpu, *memory, *disk, *uptime;

@end

// all operations are considered long-running
// and should not be performed on the UI thread.
@protocol VMCOperations <NSObject>

- (BOOL)targetHostname:(NSString *)target;
- (BOOL)loginWithEmail:(NSString *)username password:(NSString *)password;
- (NSArray *)getApps;
- (NSArray *)getInstanceStatsForApp:(NSString *)app;

@end

typedef NSString * (^SynchronousExecuteShellBlock)(NSString *, NSArray *);

SynchronousExecuteShellBlock SynchronousExecuteShell;
SynchronousExecuteShellBlock RVMExecute;

@interface VMCOperationsImpl : NSObject <VMCOperations>

- (id)initWithShellBlock:(SynchronousExecuteShellBlock)shellBlock;

@end