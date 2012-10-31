#import "AppController.h"
#import "AppPropertiesController.h"
#import "SheetWindow.h"
#import "DeploymentController.h"
#import "TargetItemsDataSource.h"
#import "DeploymentPropertiesController.h"
#import "ThorCore.h"
#import "DeploymentCell.h"
#import "NoResultsListViewDataSource.h"
#import "WizardController.h"
#import "AddDeploymentListViewSource.h"
#import "Sequence.h"

#define CONFIRM_DELETION_ALERT_CONTEXT @"ConfirmDeletion"

static NSInteger AppPropertiesControllerContext;
static NSInteger DeploymentPropertiesControllerContext;

@interface AppController ()

@property (nonatomic, strong) AppPropertiesController *appPropertiesController;
@property (nonatomic, strong) DeploymentPropertiesController *deploymentPropertiesController;
@property (nonatomic, strong) TargetItemsDataSource *targetItemsDataSource;
@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> listSource;

@end

@implementation AppController

@synthesize app, deployments, appPropertiesController, deploymentPropertiesController, breadcrumbController, title, appView, targetItemsDataSource, listSource;

- (id)init {
    if (self = [super initWithNibName:@"AppView" bundle:[NSBundle mainBundle]]) {
        self.title = @"App";
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateDeployments {
    NSError *error = nil;
    self.deployments = [[ThorBackend shared] getDeploymentsForApp:app error:&error];
    [appView.deploymentsList reloadData];
    appView.needsLayout = YES;
}

- (void)managedObjectContextDidChange:(NSNotification *)notification {
    if ([notification.name isEqual:NSManagedObjectContextObjectsDidChangeNotification]) {
        
        BOOL (^isRelevantDeployment)(id) = ^BOOL(id d) {
            return [d isKindOfClass:[Deployment class]] && [((Deployment *)d).app isEqual:app];
        };
        
        NSArray *inserted = [notification.userInfo[NSInsertedObjectsKey] allObjects];
        NSArray *deleted = [notification.userInfo[NSDeletedObjectsKey] allObjects];
        
        if ([[[@[] concat:inserted] concat:deleted] any:isRelevantDeployment])
            [self updateDeployments];
    }
}

- (void)awakeFromNib {
    
    NoResultsListViewSource *noResultsSource = [[NoResultsListViewSource alloc] init];
    noResultsSource.source = self;
    AddDeploymentListViewSource *addDeploymentSource = [[AddDeploymentListViewSource alloc] init];
    addDeploymentSource.source = noResultsSource;
    addDeploymentSource.action = ^ { [self displayCreateDeploymentDialog]; };
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
    DeploymentController *deploymentController = [DeploymentController deploymentControllerWithDeployment:deployment];
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

- (void)displayCreateDeploymentDialog {
    __block WizardController *wizard;
    
    ItemsController *targetsController = [[ItemsController alloc] init];
    targetsController.dataSource = [[TargetItemsDataSource alloc] init];
    
    WizardItemsController *wizardItemsController = [[WizardItemsController alloc] initWithItemsController:targetsController commitBlock:^{
        Target *target = [targetsController.arrayController.selectedObjects objectAtIndex:0];
        
        DeploymentPropertiesController *deploymentController = [DeploymentPropertiesController deploymentControllerWithDeployment:[Deployment deploymentWithApp:app target:target]];
        [wizard pushViewController:deploymentController animated:YES];
    } rollbackBlock:nil];
    
    wizardItemsController.title = @"Deploy to cloud";
    wizardItemsController.commitButtonTitle = @"Next";

    wizard = [[WizardController alloc] initWithRootViewController:wizardItemsController];
    NSWindow *window = [SheetWindow sheetWindowWithView:wizard.view];
    [wizard viewWillAppear];
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:&DeploymentPropertiesControllerContext];
}

- (void)presentConfirmDeletionDialog {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you wish to delete this application?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The application will no longer appear in Thor. It will not be removed from your hard drive or from any cloud."];
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:CONFIRM_DELETION_ALERT_CONTEXT];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSString *contextString = (__bridge NSString *)contextInfo;
    if ([contextString isEqual:CONFIRM_DELETION_ALERT_CONTEXT]) {
        [[ThorBackend sharedContext] deleteObject:app];
        NSError *error;
        
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
            return;
        }
        
        [self.breadcrumbController popViewControllerAnimated:YES];
    }
}

- (void)deleteClicked:(id)sender {
    [self presentConfirmDeletionDialog];
}

- (void)pushDeployment:(Deployment *)deployment sender:(NSButton *)button {
    FoundryService *service = [[FoundryService alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:deployment.target]];
    
    RACSubscribable *deploy = [[[RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *rootURL = [NSURL fileURLWithPath:deployment.app.localRoot];
        id manifest = CreateSlugManifestFromPath(rootURL);
        NSURL *slug = CreateSlugFromManifest(manifest, rootURL);
        
        return [[[service postSlug:slug manifest:manifest toAppWithName:deployment.name] subscribeOn:[RACScheduler mainQueueScheduler]] subscribe:subscriber];
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
