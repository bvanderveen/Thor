#import "AppController.h"
#import "SheetWindow.h"
#import "DeploymentController.h"
#import "DeploymentPropertiesController.h"
#import "ThorCore.h"
#import "DeploymentCell.h"
#import "NoResultsListViewDataSource.h"
#import "WizardController.h"
#import "AddItemListViewSource.h"
#import "Sequence.h"
#import "NSAlert+Dialogs.h"
#import "AppDelegate.h"
#import "TableController.h"
#import "RACSignal+Extensions.h"

@interface AppController ()

@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> listSource;

@end

@implementation AppController

@synthesize app, deployments, breadcrumbController, title, appView, listSource;

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
    cell.pushButton.rac_command = [RACCommand commandWithBlock:^ void (id v) {
        [self pushDeployment:deployment sender:cell.pushButton];
    }];
    return cell;
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    Deployment *deployment = deployments[row];
    DeploymentController *deploymentController = [DeploymentController deploymentControllerWithDeployment:deployment];
    [self.breadcrumbController pushViewController:deploymentController animated:YES];
}

- (void)displayCreateDeploymentDialog {
    NSError *error;
    if (![[ThorBackend shared] getConfiguredTargets:&error].count)
        [self presentNoConfiguredTargetsDialog];
    
    __block WizardController *wizardController;
    __block Target *selectedTarget;
    
    TableController *tableController = [[TableController alloc] initWithSignal:[[RACSignal performBlockInBackground:^ id {
        return [[ThorBackend shared] getConfiguredTargets:nil];
    }] map:^id(id targets) {
        return [targets map:^id(id x) {
            Target *target = (Target *)x;
            
            TableItem *item = [[TableItem alloc] init];
            item.view = ^ NSView *(NSTableView *tableView, NSTableColumn *column, NSInteger row) {
                TableCell *cell = [[TableCell alloc] init];
                cell.label.stringValue = [NSString stringWithFormat:@"%@", target.displayName];
                return cell;
            };
            item.selected = ^ {
                selectedTarget = target;
            };
            return item;
        }];
    }]];
    
    WizardTableController *wizardTableController = [[WizardTableController alloc] initWithTableController:tableController commitBlock:^{
        DeploymentPropertiesController *deploymentController = [DeploymentPropertiesController newDeploymentPropertiesControllerWithApp:app target:selectedTarget];
        deploymentController.title = @"Create Deployment";
        [wizardController pushViewController:deploymentController animated:YES];
    } rollbackBlock:nil];
    
    wizardTableController.title = @"Choose Cloud";
    wizardTableController.commitButtonTitle = @"Next";

    wizardController = [[WizardController alloc] initWithRootViewController:wizardTableController];
    [wizardController presentModalForWindow:self.view.window didEndBlock:^ (NSInteger returnCode) {
        if (returnCode == NSOKButton)
            [self updateDeployments];
    }];
}

- (void)presentNoConfiguredTargetsDialog {
    NSAlert *alert = [NSAlert noConfiguredTargetsDialog];
    [alert presentSheetModalForWindow:self.view.window didEndBlock:nil];
}

- (void)pushDeployment:(Deployment *)deployment sender:(NSButton *)button {
    button.enabled = NO;
    
    FoundryClient *client = [FoundryClient clientWithEndpoint:[FoundryEndpoint endpointWithTarget:deployment.target]];
    
    RACSignal *signal = [[[[[client pushAppWithName:deployment.name fromLocalPath:deployment.app.localRoot] subscribeOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]] deliverOn:[RACScheduler mainThreadScheduler]] doCompleted:^ {
        button.enabled = YES;
    }] doError:^(NSError *error) {
        button.enabled = YES;
    }];
    
    PushActivity *activity = [[PushActivity alloc] initWithSignal:signal];
    activity.localPath = deployment.app.localRoot;
    activity.targetHostname = deployment.target.hostname;
    activity.targetAppName = deployment.name;
    
    [((AppDelegate *)[NSApplication sharedApplication].delegate).activityController insert:activity];
    [((AppDelegate *)[NSApplication sharedApplication].delegate).activityWindow makeKeyAndOrderFront:nil];
}

@end
