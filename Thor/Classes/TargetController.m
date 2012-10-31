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

#define CONFIRM_DELETION_ALERT_CONTEXT @"ConfirmDeletion"

@interface TargetController ()

@property (nonatomic, strong) NSArray *apps;
@property (nonatomic, strong) FoundryService *service;
@property (nonatomic, strong) TargetPropertiesController *targetPropertiesController;
@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> listSource;

@end

@implementation TargetController

@synthesize target, targetView, breadcrumbController, title, apps, service, targetPropertiesController, listSource;

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
    if ([notification.name isEqual:NSManagedObjectContextObjectsDidChangeNotification] ||
        [notification.name isEqual:NSManagedObjectContextDidSaveNotification]) {
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
    NoResultsListViewSource *noResultsSource = [[NoResultsListViewSource alloc] init];
    noResultsSource.source = self;
    AddDeploymentListViewSource *addDeploymentSource = [[AddDeploymentListViewSource alloc] init];
    addDeploymentSource.source = noResultsSource;
    addDeploymentSource.action = ^ { [self createNewDeployment]; };
    self.listSource = addDeploymentSource;
    self.targetView.deploymentsList.dataSource = listSource;
    self.targetView.deploymentsList.delegate = listSource;
}

- (void)updateApps {
    self.service = [[FoundryService alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:target]];
    self.associatedDisposable = [[[service getApps] showLoadingViewInView:self.view] subscribeNext:^(id x) {
        self.apps = x;
        [targetView.deploymentsList reloadData];
        targetView.needsLayout = YES;
    } error:^(NSError *error) {
        [NSApp presentError:error];
    }];
}

- (void)viewWillAppear {
    [self updateApps];
}

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    return apps.count;
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
        DeploymentPropertiesController *deploymentController = [DeploymentPropertiesController deploymentControllerWithDeployment:[Deployment deploymentWithApp:app target:target]];
        [wizardController pushViewController:deploymentController animated:YES];
    } rollbackBlock:nil];
    
    wizardItemsController.title = @"Deploy app";
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
        
        Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
        deployment.name = foundryApp.name;
        deployment.app = app;
        deployment.target = self.target;
        
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

- (NSView *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    AppCell *cell = [[AppCell alloc] initWithFrame:NSZeroRect];
    FoundryApp *app = apps[row];
    cell.app = app;
    cell.button.hidden = [self deploymentForApp:app] != nil;
    [cell.button addCommand:[RACCommand commandWithCanExecute:nil execute:^(id value) {
        [self createDeploymentForApp:app];
    }]];
    return cell;
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    FoundryApp *app = apps[row];
    
    Deployment *deployment = [self deploymentForApp:app];
    
    DeploymentController *deploymentController = deployment ?
        [DeploymentController deploymentControllerWithDeployment:deployment] :
        [DeploymentController deploymentControllerWithAppName:app.name target:self.target];
    
    [self.breadcrumbController pushViewController:deploymentController animated:YES];
}

- (void)editClicked:(id)sender {
    self.targetPropertiesController = [[TargetPropertiesController alloc] init];
    self.targetPropertiesController.editing = YES;
    self.targetPropertiesController.target = self.target;
    
    NSWindow *window = [SheetWindow sheetWindowWithView:targetPropertiesController.view];
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.targetPropertiesController = nil;
    [sheet orderOut:self];
    [self updateApps];
}

- (void)presentConfirmDeletionDialog {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you wish to delete this cloud?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The cloud and its deployments will no longer appear in Thor. The cloud itself will not be changed."];
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
