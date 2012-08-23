#import "DeploymentController.h"

@implementation DeploymentInfo

@synthesize appName, target;

@end

static NSArray *instanceColumns = nil;

@implementation DeploymentController

@synthesize deploymentInfo, cloudApp, title, deploymentView, breadcrumbController, instanceStats;

+ (void)initialize {
    instanceColumns = [NSArray arrayWithObjects:@"ID", @"Host name", @"CPU", @"Memory", @"Disk", @"Uptime", nil];
}

- (id)initWithDeploymentInfo:(DeploymentInfo *)leDeploymentInfo {
    if (self = [super initWithNibName:@"DeploymentView" bundle:[NSBundle mainBundle]]) {
        self.title = leDeploymentInfo.appName;
        self.deploymentInfo = leDeploymentInfo;
    }
    return self;
}

- (void)awakeFromNib {
    NSError *error = nil;
    
    self.instanceStats = [[FixtureVMCService new] getInstanceStatsForAppName:deploymentInfo.appName target:deploymentInfo.target error:&error];
    self.cloudApp = [[FixtureCloudService new] getAppWithName:deploymentInfo.appName];
    [self.deploymentView.instancesGrid reloadData];
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (NSUInteger)numberOfColumnsForGridView:(GridView *)gridView {
    return instanceColumns.count;
}

- (NSString *)gridView:(GridView *)gridView titleForColumn:(NSUInteger)columnIndex {
    return [instanceColumns objectAtIndex:columnIndex];
}

- (NSUInteger)numberOfRowsForGridView:(GridView *)gridView {
    return instanceStats.count;
}

- (NSString *)gridView:(GridView *)gridView titleForRow:(NSUInteger)row column:(NSUInteger)columnIndex {
    VMCInstanceStats *stats = [instanceStats objectAtIndex:row];
    
    switch (columnIndex) {
        case 0:
            return stats.ID;
        case 1:
            return stats.host;
        case 2:
            return stats.cpu;
        case 3:
            return stats.memory;
        case 4:
            return stats.disk;
        case 5:
            return stats.uptime;
    }
    
    BOOL columnIndexIsValid = NO;
    assert(columnIndexIsValid);
    return nil;
}

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row {
    NSLog(@"Clicked at index %lu", row);
}

@end
