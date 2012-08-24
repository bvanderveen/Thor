#import "DeploymentController.h"

@implementation DeploymentInfo

@synthesize appName, target;

@end

static NSArray *instanceColumns = nil;

@implementation DeploymentController

@synthesize deploymentInfo, app, title, deploymentView, breadcrumbController, instanceStats;

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
    
    self.instanceStats = [[FixtureCloudService new] getStatsForAppWithName:deploymentInfo.appName];
    self.app = [[FixtureCloudService new] getAppWithName:deploymentInfo.appName];
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
    FoundryAppInstanceStats *stats = [instanceStats objectAtIndex:row];
    
    switch (columnIndex) {
        case 0:
            return stats.ID;
        case 1:
            return stats.host;
        case 2:
            return [NSString stringWithFormat:@"%f", stats.cpu];
        case 3:
            return [NSString stringWithFormat:@"%f", stats.memory];
        case 4:
            return [NSString stringWithFormat:@"%f", stats.disk];
        case 5:
            return [NSString stringWithFormat:@"%f", stats.uptime];
    }
    
    BOOL columnIndexIsValid = NO;
    assert(columnIndexIsValid);
    return nil;
}

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row {
    NSLog(@"Clicked at index %lu", row);
}

@end
