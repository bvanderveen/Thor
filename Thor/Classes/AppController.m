#import "AppController.h"
#import "AppPropertiesController.h"
#import "SheetWindow.h"
#import "DeploymentController.h"
#import "TargetItemsDataSource.h"
#import "DeploymentPropertiesController.h"
#import "ThorCore.h"
#import "GridView.h"
#import "NSFont+LineHeight.h"

@interface DeploymentCell : ListCell

@property (nonatomic, strong) Deployment *deployment;
@property (nonatomic, strong) NSButton *pushButton;

@end

@implementation DeploymentCell

@synthesize deployment, pushButton;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.pushButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        pushButton.title = @"Push";
        pushButton.bezelStyle = NSTexturedRoundedBezelStyle;
        
        [self addSubview:pushButton];
    }
    return self;
}

- (void)layout {
    NSSize buttonSize = pushButton.intrinsicContentSize;
    pushButton.frame = NSMakeRect(self.bounds.size.width - buttonSize.width - 20, (self.bounds.size.height - buttonSize.height) / 2, buttonSize.width, buttonSize.height);
    [super layout];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSImage *icon = [NSImage imageNamed:@"DeploymentIconSelected.png"];
    
    [icon drawAtPoint:NSMakePoint(10, 5) fromRect:NSMakeRect(0, 0, icon.size.width, icon.size.height) operation:NSCompositeSourceOver fraction:1];
    
    NSFont *titleFont = [NSFont boldSystemFontOfSize:12];
    
    [[NSString stringWithFormat:@"%@ – %@", deployment.displayName, deployment.target.displayName] drawInRect:NSMakeRect(85, self.bounds.size.height - titleFont.lineHeight - 8, self.bounds.size.width, titleFont.lineHeight) withAttributes:@{
NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
     NSFontAttributeName : titleFont
     }];
    
    NSFont *subtitleFont = [NSFont systemFontOfSize:12];
    [deployment.appName drawInRect:NSMakeRect(85, self.bounds.size.height - titleFont.lineHeight - subtitleFont.lineHeight - 8, self.bounds.size.width, subtitleFont.lineHeight) withAttributes:@{
                                          NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
                                                     NSFontAttributeName : subtitleFont
     }];
}

@end

static NSInteger AppPropertiesControllerContext;
static NSInteger DeploymentPropertiesControllerContext;

@interface AppController ()

@property (nonatomic, strong) AppPropertiesController *appPropertiesController;
@property (nonatomic, strong) DeploymentPropertiesController *deploymentPropertiesController;
@property (nonatomic, strong) ItemsController *targetsController;
@property (nonatomic, strong) TargetItemsDataSource *targetItemsDataSource;

@end

@implementation AppController

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
    [appView.appContentView.deploymentsList reloadData];
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

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    return deployments.count;
}

- (ListCell *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    Deployment *deployment = deployments[row];
    DeploymentCell *cell = [[DeploymentCell alloc] initWithFrame:NSZeroRect];
    cell.deployment = deployment;
    [cell.pushButton addCommand:[RACCommand commandWithCanExecute:nil execute:^ void (id v) {
        [self pushDeployment:deployment sender:cell.pushButton];
    }]];
    return cell;
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    Deployment *deployment = deployments[row];
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
