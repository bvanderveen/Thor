#import "AppController.h"
#import "SheetWindow.h"
#import "DeploymentController.h"
#import "TargetItemsDataSource.h"
#import "DeploymentPropertiesController.h"
#import "ThorCore.h"
#import "DeploymentCell.h"
#import "NoResultsListViewDataSource.h"
#import "WizardController.h"
#import "AddItemListViewSource.h"
#import "Sequence.h"
#import "NSAlert+Dialogs.h"

@interface AppController ()

@property (nonatomic, strong) TargetItemsDataSource *targetItemsDataSource;
@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> listSource;

@end

@implementation AppController

@synthesize app, deployments, breadcrumbController, title, appView, targetItemsDataSource, listSource;

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
    AddItemListViewSource *addDeploymentSource = [[AddItemListViewSource alloc] initWithTitle:@"New deployment…"];
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

- (void)displayCreateDeploymentDialog {
    __block WizardController *wizardController;
    
    ItemsController *targetsController = [[ItemsController alloc] init];
    targetsController.dataSource = [[TargetItemsDataSource alloc] init];
    
    WizardItemsController *wizardItemsController = [[WizardItemsController alloc] initWithItemsController:targetsController commitBlock:^{
        Target *target = [targetsController.arrayController.selectedObjects objectAtIndex:0];
        Deployment *deployment = [Deployment deploymentWithApp:app target:target];
        DeploymentPropertiesController *deploymentController = [DeploymentPropertiesController deploymentPropertiesControllerWithDeployment:deployment];
        deploymentController.title = @"Create Deployment";
        [wizardController pushViewController:deploymentController animated:YES];
    } rollbackBlock:nil];
    
    wizardItemsController.title = @"Choose Cloud";
    wizardItemsController.commitButtonTitle = @"Next";

    wizardController = [[WizardController alloc] initWithRootViewController:wizardItemsController];
    [wizardController presentModalForWindow:self.view.window didEndBlock:^ (NSInteger returnCode) {
        if (returnCode == NSOKButton)
            [self updateDeployments];
    }];
}

- (void)presentConfirmDeletionDialog {
    NSAlert *alert = [NSAlert confirmDeleteAppDialog];
    [alert presentSheetModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSAlertDefaultReturn) {
            [[ThorBackend sharedContext] deleteObject:app];
            NSError *error;
            
            if (![[ThorBackend sharedContext] save:&error]) {
                [NSApp presentError:error];
                return;
            }
            
            [self.breadcrumbController popViewControllerAnimated:YES];
        }
    }];
}

- (void)deleteClicked:(id)sender {
    [self presentConfirmDeletionDialog];
}

- (void)pushDeployment:(Deployment *)deployment sender:(NSButton *)button {
    FoundryClient *client = [[FoundryClient alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:deployment.target]];
    
    RACSubscribable *deploy = [[[RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURL *rootURL = [NSURL fileURLWithPath:deployment.app.localRoot];
        id manifest = CreateSlugManifestFromPath(rootURL);
        NSURL *slug = CreateSlugFromManifest(manifest, rootURL);
        
        return [[[client postSlug:slug manifest:manifest toAppWithName:deployment.name] subscribeOn:[RACScheduler mainQueueScheduler]] subscribe:subscriber];
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
