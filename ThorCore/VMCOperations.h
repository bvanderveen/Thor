
@interface VMCInstanceStats : NSObject 

@property (nonatomic, copy) NSString *ID, *host, *cpu, *memory, *disk, *uptime;

@end

@interface VMCApp : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *uris;

@end

// all operations are considered long-running
// and should not be performed on the UI thread.
@protocol VMCOperations <NSObject>

- (BOOL)targetHostname:(NSString *)target;
- (BOOL)loginWithEmail:(NSString *)username password:(NSString *)password;
- (NSArray *)getApps; // of VMCApp
- (NSArray *)getInstanceStatsForApp:(NSString *)app; // of VMCInstanceStats

@end

typedef NSString * (^SynchronousExecuteShellBlock)(NSString *, NSArray *);

SynchronousExecuteShellBlock SynchronousExecuteShell;
SynchronousExecuteShellBlock RVMExecute;

@interface VMCOperationsImpl : NSObject <VMCOperations>

- (id)initWithShellBlock:(SynchronousExecuteShellBlock)shellBlock;

@end