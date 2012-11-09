#import "TargetController.h"
#import "TargetPropertiesController.h"
#import "SheetWindow.h"
#import "NSObject+AssociateDisposable.h"
#import "DeploymentController.h"
#import "AppCell.h"
#import "NoResultsListViewDataSource.h"
#import "RACSubscribable+Extensions.h"
#import "Sequence.h"
#import "AppItemsDataSource.h"
#import "DeploymentPropertiesController.h"
#import "AddDeploymentListViewSource.h"
#import "NSAlert+Dialogs.h"

@interface NSObject (AppsListViewSourceDelegate)

- (void)accessoryButtonClickedForApp:(FoundryApp *)app;
- (void)selectedApp:(FoundryApp *)app;
- (BOOL)showsAccessoryButtonForApp:(FoundryApp *)app;

@end

@interface AppsListViewSource : NSObject <ListViewDataSource, ListViewDelegate>

@property (nonatomic, strong) NSArray *apps;
@property (nonatomic, weak) id delegate;

@end

@implementation AppsListViewSource

@synthesize apps, delegate;

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    return apps.count;
}

- (NSView *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    AppCell *cell = [[AppCell alloc] initWithFrame:NSZeroRect];
    FoundryApp *app = apps[row];
    cell.app = app;
    cell.button.hidden = ![delegate showsAccessoryButtonForApp:app];
    [cell.button addCommand:[RACCommand commandWithCanExecute:nil execute:^(id value) {
        [delegate accessoryButtonClickedForApp:app];
    }]];
    return cell;
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    FoundryApp *app = apps[row];
    [delegate selectedApp:app];
}

@end

@interface TargetController ()

@property (nonatomic, strong) NSArray *apps;
@property (nonatomic, strong) FoundryClient *client;
@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> rootAppsListSource;
@property (nonatomic, strong) AppsListViewSource *appsListSource;

@end

@implementation TargetController

@synthesize target, targetView, breadcrumbController, title, apps, client, appsListSource, rootAppsListSource;

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (id)init {
    if (self = [super initWithNibName:@"TargetView" bundle:[NSBundle mainBundle]]) {
        self.title = @"Cloud";
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)managedObjectContextNotification:(NSNotification *)notification {
    if ([notification.name isEqual:NSManagedObjectContextDidSaveNotification]) {
        BOOL (^isRelevantDeployment)(id) = ^BOOL(id d) {
            return [d isKindOfClass:[Deployment class]] && [((Deployment *)d).target isEqual:self.target];
        };
        
        NSArray *inserted = [notification.userInfo[NSInsertedObjectsKey] allObjects];
        NSArray *deleted = [notification.userInfo[NSDeletedObjectsKey] allObjects];
        
        if ([[[@[] concat:inserted] concat:deleted] any:isRelevantDeployment])
            [self updateApps];
    }
}

- (void)awakeFromNib {
    self.appsListSource = [[AppsListViewSource alloc] init];
    appsListSource.delegate = self;
    NoResultsListViewSource *noResultsSource = [[NoResultsListViewSource alloc] init];
    noResultsSource.source = appsListSource;
    AddDeploymentListViewSource *addDeploymentSource = [[AddDeploymentListViewSource alloc] init];
    addDeploymentSource.source = noResultsSource;
    addDeploymentSource.action = ^ { [self createNewDeployment]; };
    self.rootAppsListSource = addDeploymentSource;
    
    
    self.targetView.deploymentsList.dataSource = rootAppsListSource;
    self.targetView.deploymentsList.delegate = rootAppsListSource;
}

- (void)updateApps {
    self.client = [[FoundryClient alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:target]];
    
    NSArray *subscriables = @[[client getApps], [client getServices] ];
    
    self.associatedDisposable = [[[RACSubscribable combineLatest:subscriables] showLoadingViewInView:self.view] subscribeNext:^(id x) {
        RACTuple *t = (RACTuple *)x;
        appsListSource.apps = t.first;
        NSLog(@"services: %@", t.second);
        [targetView.deploymentsList reloadData];
        targetView.needsLayout = YES;
    } error:^(NSError *error) {
        [NSApp presentError:error];
    }];
}

- (void)viewWillAppear {
    [self updateApps];
}

- (void)accessoryButtonClickedForApp:(FoundryApp *)app {
    [self createDeploymentForApp:app];
}

- (void)selectedApp:(FoundryApp *)app {
    Deployment *deployment = [self deploymentForApp:app];
    
    DeploymentController *deploymentController = deployment ?
    [DeploymentController deploymentControllerWithDeployment:deployment] :
    [DeploymentController deploymentControllerWithAppName:app.name target:self.target];
    
    [self.breadcrumbController pushViewController:deploymentController animated:YES];
}

- (BOOL)showsAccessoryButtonForApp:(FoundryApp *)app {    
    return [self deploymentForApp:app] == nil;
}

- (Deployment *)deploymentForApp:(FoundryApp *)app {
    NSError *error;
    NSArray *deployments = [[[ThorBackend shared] getDeploymentsForTarget:self.target error:&error] filter:^ BOOL (id d) { return [((Deployment *)d).name isEqual:app.name]; }];
    return deployments.count ? deployments[0] : nil;
}

- (ItemsController *)createAppItemsController {
    ItemsController *appsController = [[ItemsController alloc] init];
    appsController.dataSource = [[AppItemsDataSource alloc] init];
    return appsController;
}

- (void)createNewDeployment {
    __block WizardController *wizardController;
    
    ItemsController *appsController = [self createAppItemsController];
    
    WizardItemsController *wizardItemsController = [[WizardItemsController alloc] initWithItemsController:appsController commitBlock:^{
        App *app = [appsController.arrayController.selectedObjects objectAtIndex:0];
        Deployment *deployment = [Deployment deploymentWithApp:app target:target];
        DeploymentPropertiesController *deploymentController = [DeploymentPropertiesController deploymentPropertiesControllerWithDeployment:deployment create:YES];
        deploymentController.title = @"Create Deployment";
        [wizardController pushViewController:deploymentController animated:YES];
    } rollbackBlock:nil];
    
    wizardItemsController.title = @"Choose App";
    wizardItemsController.commitButtonTitle = @"Next";
    
    wizardController = [[WizardController alloc] initWithRootViewController:wizardItemsController];
    [wizardController presentModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSOKButton)
            [self updateApps];
    }];
}

- (void)createDeploymentForApp:(FoundryApp *)foundryApp {
    __block WizardController *wizardController;
    
    ItemsController *appsController = [self createAppItemsController];
    
    WizardItemsController *wizardItemsController = [[WizardItemsController alloc] initWithItemsController:appsController commitBlock:^{
        App *app = [appsController.arrayController.selectedObjects objectAtIndex:0];
        
        Deployment *deployment = [Deployment deploymentWithApp:app target:self.target];
        deployment.name = foundryApp.name;
        
        NSError *error;
        
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
        }
        
        [wizardController dismissWithReturnCode:NSOKButton];
    } rollbackBlock:nil];
    
    wizardItemsController.title = @"Associate deployment with app";
    wizardItemsController.commitButtonTitle = @"Done";
    
    wizardController = [[WizardController alloc] initWithRootViewController:wizardItemsController];
    [wizardController presentModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSOKButton)
            [self updateApps];
    }];
}

- (void)editClicked:(id)sender {
    TargetPropertiesController *targetPropertiesController = [[TargetPropertiesController alloc] init];
    targetPropertiesController.editing = YES;
    targetPropertiesController.target = self.target;
    targetPropertiesController.title = @"Edit Cloud";
    
    WizardController *wizardController = [[WizardController alloc] initWithRootViewController:targetPropertiesController];
    [wizardController presentModalForWindow:self.view.window didEndBlock:^ (NSInteger returnCode) {
        if (returnCode == NSOKButton)
            [self updateApps];
    }];
}

- (void)presentConfirmDeletionDialog {
    NSAlert *alert = [NSAlert confirmDeleteTargetDialog];
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:CONFIRM_DELETION_ALERT_CONTEXT];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSString *contextString = (__bridge NSString *)contextInfo;
    if ([contextString isEqual:CONFIRM_DELETION_ALERT_CONTEXT]) {
        [[ThorBackend sharedContext] deleteObject:target];
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

@end
