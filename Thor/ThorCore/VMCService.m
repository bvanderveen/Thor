#import "VMCService.h"

@implementation VMCDeployment

@synthesize name, cpu, memory, disk;

@end

@implementation FixtureVMCService

- (NSArray *)getDeploymentsForTarget:(Target *)target {
    VMCDeployment *deployment0 = [VMCDeployment new];
    deployment0.name = @"Foo";
    deployment0.cpu = @"33%";
    deployment0.memory = @"256M";
    deployment0.disk = @"128MB";
    
    VMCDeployment *deployment1 = [VMCDeployment new];
    deployment1.name = @"Bar";
    deployment1.cpu = @"66%";
    deployment1.memory = @"512M";
    deployment1.disk = @"256MB";
    
    return [NSArray arrayWithObjects:deployment0, deployment1, nil];
}

@end
