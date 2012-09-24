#import "AppController.h"
#import "AppPropertiesController.h"
#import "SheetWindow.h"
#import "DeploymentController.h"
#import "TargetItemsDataSource.h"
#import "DeploymentPropertiesController.h"
#import "ThorCore.h"
#import "DeploymentCell.h"
#import "NoResultsListViewDataSource.h"
#import "NSFont+LineHeight.h"
#import "WizardController.h"

@interface AddDeploymentCell : ListCell

@end

@implementation AddDeploymentCell

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSCenterTextAlignment;
    NSFont *font = [NSFont boldSystemFontOfSize:12];
    [@"New deployment…" drawInRect:NSMakeRect(0, (self.bounds.size.height - font.lineHeight) / 2 + 2, self.bounds.size.width, font.lineHeight) withAttributes:@{
NSForegroundColorAttributeName : [NSColor colorWithCalibratedWhite:.2 alpha:1],
         NSFontAttributeName : font,
NSParagraphStyleAttributeName : style
     }];
}

@end

@interface AddDeploymentListViewSource : NSObject <ListViewDataSource, ListViewDelegate>

@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> source;
@property (nonatomic, copy) void (^action)();

@end

@implementation AddDeploymentListViewSource

@synthesize source, action;

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    return [source numberOfRowsForListView:listView] + 1;
}

- (BOOL)rowInListView:(ListView *)listView isWrappedCell:(NSUInteger)row {
    return row < [source numberOfRowsForListView:listView];
}

- (ListCell *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    return [self rowInListView:listView isWrappedCell:row] ?
        [source listView:listView cellForRow:row] :
        [[AddDeploymentCell alloc] initWithFrame:NSZeroRect];
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    if ([self rowInListView:listView isWrappedCell:row])
        [source listView:listView didSelectRowAtIndex:row];
    else
        action();
}

@end

static NSInteger AppPropertiesControllerContext;
static NSInteger DeploymentPropertiesControllerContext;

@interface AppController ()

@property (nonatomic, strong) AppPropertiesController *appPropertiesController;
@property (nonatomic, strong) DeploymentPropertiesController *deploymentPropertiesController;
@property (nonatomic, strong) ItemsController *targetsController;
@property (nonatomic, strong) TargetItemsDataSource *targetItemsDataSource;
@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> listSource;

@end

@implementation AppController

@synthesize app, deployments, appPropertiesController, deploymentPropertiesController, breadcrumbController, title, appView, targetsController, targetItemsDataSource, listSource;

- (id)init {
    if (self = [super initWithNibName:@"AppView" bundle:[NSBundle mainBundle]]) {
        self.title = @"App";
    }
    return self;
}

- (void)updateDeployments {
    NSError *error = nil;
    self.deployments = [[ThorBackend shared] getDeploymentsForApp:app error:&error];
    [appView.deploymentsList reloadData];
    appView.needsLayout = YES;
}

- (void)awakeFromNib {
//    self.targetsController = [[ItemsController alloc] initWithTitle:@"Clouds"];
//    targetsController.dataSource = [[TargetItemsDataSource alloc] initWithSelectionAction:^(ItemsController *itemsController, id item) {
//        [self displayDeploymentDialogWithTarget:(Target *)item];
//    }];
//    self.appView.drawerBar.drawerView = targetsController.view;
    
    NoResultsListViewSource *noResultsSource = [[NoResultsListViewSource alloc] init];
    noResultsSource.source = self;
    AddDeploymentListViewSource *addDeploymentSource = [[AddDeploymentListViewSource alloc] init];
    addDeploymentSource.source = noResultsSource;
    addDeploymentSource.action = ^ { [self displayDeploymentDialog]; };
    self.listSource = addDeploymentSource;
    self.appView.deploymentsList.dataSource = listSource;
    self.appView.deploymentsList.delegate = listSource;

}

- (void)viewWillAppear {
    [self updateDeployments];
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
        //self.appView.drawerBar.expanded = NO;
        [self updateDeployments];
    }
    [sheet orderOut:self];
}

- (void)displayDeploymentDialog {
    __block WizardController *wizard;
    
    self.targetsController = [[ItemsController alloc] initWithTitle:@"Clouds"];
    targetsController.dataSource = [[TargetItemsDataSource alloc] initWithSelectionAction:^(ItemsController *itemsController, id item) {
        DeploymentPropertiesController *wizardRoot = [[DeploymentPropertiesController alloc] init];
        wizardRoot.deployment = [Deployment deploymentInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
        wizardRoot.deployment.app = app;
        wizardRoot.deployment.target = item;
        [wizard pushViewController:wizardRoot animated:YES];
    }];

    
    wizard = [[WizardController alloc] initWithRootViewController:targetsController];
    NSWindow *window = [SheetWindow sheetWindowWithView:wizard.view];
    [wizard viewWillAppear];
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:&DeploymentPropertiesControllerContext];
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
