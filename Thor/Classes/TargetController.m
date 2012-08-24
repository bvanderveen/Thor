#import "TargetController.h"
#import "TargetPropertiesController.h"
#import "SheetWindow.h"
#import "NSObject+AssociateDisposable.h"
#import "DeploymentController.h"

@interface TargetController ()

@property (nonatomic, strong) NSArray *deployments;
@property (nonatomic, strong) TargetPropertiesController *targetPropertiesController;

@end

static NSArray *deploymentColumns = nil;

@implementation TargetController

+ (void)initialize {
    deploymentColumns = [NSArray arrayWithObjects:@"Name", @"URI", @"Instances", @"Memory", @"Disk", nil];
}

@synthesize target, targetView, breadcrumbController, title, deployments, targetPropertiesController;

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (id)init {
    if (self = [super initWithNibName:@"TargetView" bundle:[NSBundle mainBundle]]) {
        self.title = @"Cloud";
    }
    return self;
}

- (void)awakeFromNib {
    self.associatedDisposable = [[[RACSubscribable start:^id(BOOL *success, NSError **error) {
        id result = [[FixtureCloudService new] getApps];
        return result;
    }] deliverOn:[RACScheduler mainQueueScheduler]] subscribeNext:^(id x) {
        self.deployments = x;
        [targetView.deploymentsGrid reloadData];
        targetView.needsLayout = YES;
    } error:^(NSError *error) {
        [NSApp presentError:error];
    }];
    
    targetView.deploymentsGrid.dataSource = self;
}

- (NSUInteger)numberOfColumnsForGridView:(GridView *)gridView {
    return deploymentColumns.count;
}

- (NSString *)gridView:(GridView *)gridView titleForColumn:(NSUInteger)columnIndex {
    return [deploymentColumns objectAtIndex:columnIndex];
}

- (NSUInteger)numberOfRowsForGridView:(GridView *)gridView {
    return deployments.count;
}

- (NSString *)gridView:(GridView *)gridView titleForRow:(NSUInteger)row column:(NSUInteger)columnIndex {
    CloudApp *app = [deployments objectAtIndex:row];
    
    switch (columnIndex) {
        case 0:
            return app.name;
        case 1:
            return [app.uris objectAtIndex:0];
        case 2:
            return [NSString stringWithFormat:@"%d", app.instances];
        case 3:
            return [NSString stringWithFormat:@"%d", app.memory];
        case 4:
            return [NSString stringWithFormat:@"%d", app.disk];
    }
    
    BOOL columnIndexIsValid = NO;
    assert(columnIndexIsValid);
    return nil;
}

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row {
    CloudApp *app = [deployments objectAtIndex:row];
    
    DeploymentInfo *deploymentInfo = [DeploymentInfo new];
    deploymentInfo.appName = app.name;
    deploymentInfo.target = [CloudInfo new];
    deploymentInfo.target.hostname = target.hostname;
    deploymentInfo.target.email = target.email;
    deploymentInfo.target.password = target.password;
    
    DeploymentController *deploymentController = [[DeploymentController alloc] initWithDeploymentInfo:deploymentInfo];
    [self.breadcrumbController pushViewController:deploymentController animated:YES];
}

- (void)editClicked:(id)sender {
    self.targetPropertiesController = [[TargetPropertiesController alloc] init];
    self.targetPropertiesController.editing = YES;
    self.targetPropertiesController.target = target;
    
    NSWindow *window = [[SheetWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = self.targetPropertiesController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = targetPropertiesController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.targetPropertiesController = nil;
    [sheet orderOut:self];
}

@end
