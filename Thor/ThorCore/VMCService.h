#import "ThorBackend.h"

@interface VMCDeployment : NSObject

@property (nonatomic, copy) NSString *name, *cpu, *memory, *disk;

@end

@protocol VMCService <NSObject>

- (NSArray *)getDeploymentsForTarget:(Target *)target;

@end

@interface FixtureVMCService : NSObject <VMCService>

@end