#import "AppController.h"
#import "AppPropertiesController.h"
#import "SheetWindow.h"
#import "DeploymentController.h"
#import "TargetItemsDataSource.h"

@interface AppController ()

@property (nonatomic, strong) AppPropertiesController *appPropertiesController;
@property (nonatomic, strong) ItemsController *targetsController;
@property (nonatomic, strong) TargetItemsDataSource *targetItemsDataSource;

@end

static NSArray *deploymentColumns = nil;

@implementation AppController

+ (void)initialize {
    deploymentColumns = @[@"App name", @"Cloud name", @"Cloud hostname"];
}

@synthesize app, deployments, appPropertiesController, breadcrumbController, title, appView, targetsController, targetItemsDataSource;

- (id)init {
    if (self = [super initWithNibName:@"AppView" bundle:[NSBundle mainBundle]]) {
        self.title = @"App";
    }
    return self;
}

- (void)awakeFromNib {
    NSError *error = nil;
    self.deployments = [[ThorBackend shared] getDeploymentsForApp:app error:&error];
    
    self.targetsController = [[ItemsController alloc] initWithTitle:@"Clouds"];
    targetsController.dataSource = [[TargetItemsDataSource alloc] initWithSelectionAction:^(ItemsController *itemsController, id item) {
        [self displayDeploymentDialogWithTarget:(Target *)item];
    }];
    
    self.appView.drawerBar.drawerView = targetsController.view;
    
    [self.appView.appContentView.deploymentsGrid reloadData];
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
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
    Deployment *deployment = [deployments objectAtIndex:row];
    
    switch (columnIndex) {
        case 0:
            return deployment.appName;
        case 1:
            return deployment.hostname;
        case 2:
            return deployment.hostname;
    }
    
    BOOL columnIndexIsValid = NO;
    assert(columnIndexIsValid);
    return nil;
}

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row {
    Deployment *deployment = [deployments objectAtIndex:row];
    NSError *error = nil;
    Target *targetOfDeployment = [[ThorBackend shared] getTargetForDeployment:deployment error:&error];
    
    DeploymentInfo *deploymentInfo = [DeploymentInfo new];
    deploymentInfo.appName = deployment.appName;
    deploymentInfo.endpoint = [FoundryEndpoint endpointWithTarget:targetOfDeployment];
    
    DeploymentController *deploymentController = [[DeploymentController alloc] initWithDeploymentInfo:deploymentInfo];
    [self.breadcrumbController pushViewController:deploymentController animated:YES];
}

- (void)editClicked:(id)sender {
    self.appPropertiesController = [[AppPropertiesController alloc] init];
    appPropertiesController.editing = YES;
    appPropertiesController.app = app;
    
    NSWindow *window = [[SheetWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = appPropertiesController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = appPropertiesController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.appPropertiesController = nil;
    [sheet orderOut:self];
}

- (void)displayDeploymentDialogWithTarget:(Target *)target {
    
}

@end
