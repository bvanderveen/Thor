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

@interface TargetController ()

@property (nonatomic, strong) NSArray *apps;
@property (nonatomic, strong) FoundryService *service;
@property (nonatomic, strong) TargetPropertiesController *targetPropertiesController;
@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> listSource;

@end

@implementation TargetController

@synthesize target = _target, targetView, breadcrumbController, title, apps, service, targetPropertiesController, listSource;

- (void)setTarget:(Target *)value {
    _target = value;
    self.service = [[FoundryService alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:value]];
}

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

- (BOOL)hasDeploymentForApp:(FoundryApp *)app {
    NSError *error;
    NSArray *deployments = [[ThorBackend shared] getDeploymentsForTarget:self.target error:&error];
    return [deployments any:^ BOOL (id d) { return [((Deployment *)d).appName isEqual:app.name]; }];
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
        DeploymentPropertiesController *deploymentController = [DeploymentPropertiesController newDeploymentControllerWithTarget:self.target app:app];
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
        deployment.appName = foundryApp.name;
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
    cell.button.hidden = [self hasDeploymentForApp:app];
    [cell.button addCommand:[RACCommand commandWithCanExecute:nil execute:^(id value) {
        [self createDeploymentForApp:app];
    }]];
    return cell;
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    FoundryApp *app = apps[row];
    Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    deployment.appName = app.name;
    deployment.target = self.target;
    
    DeploymentController *deploymentController = [[DeploymentController alloc] initWithDeployment:deployment];
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

- (void)deleteClicked:(id)sender {
    [[ThorBackend sharedContext] deleteObject:self.target];
    NSError *error;
    
    if (![[ThorBackend sharedContext] save:&error]) {
        [NSApp presentError:error];
        return;
    }
    
    [self.breadcrumbController popViewControllerAnimated:YES];
}

@end
