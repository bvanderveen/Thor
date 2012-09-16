#import "AppController.h"
#import "AppPropertiesController.h"
#import "SheetWindow.h"
#import "DeploymentController.h"
#import "TargetItemsDataSource.h"
#import "DeploymentPropertiesController.h"
#import "ThorCore.h"
#import "GridView.h"

static NSInteger AppPropertiesControllerContext;
static NSInteger DeploymentPropertiesControllerContext;

@interface AppController ()

@property (nonatomic, strong) AppPropertiesController *appPropertiesController;
@property (nonatomic, strong) DeploymentPropertiesController *deploymentPropertiesController;
@property (nonatomic, strong) ItemsController *targetsController;
@property (nonatomic, strong) TargetItemsDataSource *targetItemsDataSource;

@end

static NSArray *deploymentColumns = nil;

@implementation AppController

+ (void)initialize {
    deploymentColumns = @[@"Title", @"App name", @"Cloud name", @"Cloud hostname", @"Push"];
}

@synthesize app, deployments, appPropertiesController, deploymentPropertiesController, breadcrumbController, title, appView, targetsController, targetItemsDataSource;

- (id)init {
    if (self = [super initWithNibName:@"AppView" bundle:[NSBundle mainBundle]]) {
        self.title = @"App";
    }
    return self;
}

- (void)updateDeployments {
    NSError *error = nil;
    self.deployments = [[ThorBackend shared] getDeploymentsForApp:app error:&error];
    [appView.appContentView.deploymentsGrid reloadData];
    appView.appContentView.needsLayout = YES;
}

- (void)awakeFromNib {
    self.targetsController = [[ItemsController alloc] initWithTitle:@"Clouds"];
    targetsController.dataSource = [[TargetItemsDataSource alloc] initWithSelectionAction:^(ItemsController *itemsController, id item) {
        [self displayDeploymentDialogWithTarget:(Target *)item];
    }];
    self.appView.drawerBar.drawerView = targetsController.view;
}

- (void)viewWillAppear {
    [self updateDeployments];
    
    // TODO really this should be done by the drawer view.
    // but I'm gonna rip the drawer view out and everything
    // will make more sense.
    [targetsController viewWillAppear];
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

- (NSView *)gridView:(GridView *)gridView viewForRow:(NSUInteger)row column:(NSUInteger)columnIndex {
    Deployment *deployment = [deployments objectAtIndex:row];
    
    NSString *labelTitle;
    
    switch (columnIndex) {
        case 0:
            labelTitle = deployment.displayName;
            break;
        case 1:
            labelTitle = deployment.appName;
            break;
        case 2:
            labelTitle = deployment.target.displayName;
            break;
        case 3:
            labelTitle = deployment.target.hostname;
            break;
        case 4:
        {
            NSButton *button = [[NSButton alloc] initWithFrame:NSZeroRect];
            button.title = @"Push";
            button.bezelStyle = NSTexturedRoundedBezelStyle;
            
            [button addCommand:[RACCommand commandWithCanExecute:nil execute:^ void (id v) {
                [self pushDeployment:deployment sender:button];
            }]];
            return button;
        }
    }
    
    return [GridLabel labelWithTitle:labelTitle];
}

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row {
    Deployment *deployment = [deployments objectAtIndex:row];
    
    DeploymentController *deploymentController = [[DeploymentController alloc] initWithDeployment:deployment];
    [self.breadcrumbController pushViewController:deploymentController animated:YES];
}

- (void)editClicked:(id)sender {
    self.appPropertiesController = [[AppPropertiesController alloc] init];
    appPropertiesController.editing = YES;
    appPropertiesController.app = app;

    NSWindow *window = [SheetWindow sheetWindowWithView:appPropertiesController.view];
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:&AppPropertiesControllerContext];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (contextInfo == &AppPropertiesControllerContext) {
        self.appPropertiesController = nil;
    }
    else if (contextInfo == &DeploymentPropertiesControllerContext) {
        self.deploymentPropertiesController = nil;
        self.appView.drawerBar.expanded = NO;
        [self updateDeployments];
    }
    [sheet orderOut:self];
}

- (void)displayDeploymentDialogWithTarget:(Target *)target {
    Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    deployment.app = app;
    deployment.target = target;
    deployment.instances = 1;
    
    self.deploymentPropertiesController = [DeploymentPropertiesController new];
    deploymentPropertiesController.deployment = deployment;
    
    NSWindow *window = [SheetWindow sheetWindowWithView:deploymentPropertiesController.view];
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:&DeploymentPropertiesControllerContext];    
}

- (void)deleteClicked:(id)sender {
    [[ThorBackend sharedContext] deleteObject:app];
    NSError *error;
    
    if (![[ThorBackend sharedContext] save:&error]) {
        [NSApp presentError:error];
        return;
    }
        
    [self.breadcrumbController popViewControllerAnimated:YES];
}

- (void)pushDeployment:(Deployment *)deployment sender:(NSButton *)button {
    FoundryService *service = [[FoundryService alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:deployment.target]];
    
    RACSubscribable *deploy = [[[RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *rootURL = [NSURL fileURLWithPath:deployment.app.localRoot];
        id manifest = CreateSlugManifestFromPath(rootURL);
        NSURL *slug = CreateSlugFromManifest(manifest, rootURL);
        
        return [[[service postSlug:slug manifest:manifest toAppWithName:deployment.appName] subscribeOn:[RACScheduler mainQueueScheduler]] subscribe:subscriber];
    }] subscribeOn:[RACScheduler backgroundScheduler]] deliverOn:[RACScheduler mainQueueScheduler]];
    
    button.enabled = NO;
    button.title = @"Pushing…";
    [deploy subscribeError:^(NSError *error) {
        [NSApp presentError:error];
        button.enabled = YES;
        button.title = @"Push";
    } completed:^{
        button.enabled = YES;
        button.title = @"Push";
    }];
}

@end
