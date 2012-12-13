#import "TargetController.h"
#import "SheetWindow.h"
#import "NSObject+AssociateDisposable.h"
#import "DeploymentController.h"
#import "AppCell.h"
#import "ServiceCell.h"
#import "NoResultsListViewDataSource.h"
#import "RACSubscribable+Extensions.h"
#import "Sequence.h"
#import "AppItemsDataSource.h"
#import "DeploymentPropertiesController.h"
#import "AddItemListViewSource.h"
#import "NSAlert+Dialogs.h"
#import "ServiceInfoItemsDataSource.h"
#import "ServicePropertiesController.h"
#import "TableController.h"

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

@interface NSObject (ServicesListViewSourceDelegate)

- (void)selectedService:(FoundryService *)service;
- (void)accessoryButtonClickedForService:(FoundryService *)service;

@end

@interface ServicesListViewSource : NSObject <ListViewDataSource, ListViewDelegate>

@property (nonatomic, strong) NSArray *services;
@property (nonatomic, weak) id delegate;

@end

@implementation ServicesListViewSource

@synthesize services, delegate;

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    return services.count;
}

- (NSView *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    ServiceCell *cell = [[ServiceCell alloc] initWithFrame:NSZeroRect];
    FoundryService *service = services[row];
    cell.service = service;
    [cell.button addCommand:[RACCommand commandWithCanExecute:nil execute:^(id value) {
        [delegate accessoryButtonClickedForService:service];
    }]];
    return cell;
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    FoundryService *service = services[row];
    [delegate selectedService:service];
}

@end

@interface TargetController ()

@property (nonatomic, strong) NSArray *apps;
@property (nonatomic, strong) FoundryClient *client;
@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> rootAppsListSource, rootServicesListSource;
@property (nonatomic, strong) AppsListViewSource *appsListSource;
@property (nonatomic, strong) ServicesListViewSource *servicesListSource;
@property (nonatomic, strong) App *tableSelectedApp;

@end

@implementation TargetController

@synthesize target, targetView, breadcrumbController, title, apps, client, appsListSource, servicesListSource, rootAppsListSource, rootServicesListSource, tableSelectedApp;

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
    NoResultsListViewSource *noAppResultsSource = [[NoResultsListViewSource alloc] init];
    noAppResultsSource.source = appsListSource;
    AddItemListViewSource *addDeploymentSource = [[AddItemListViewSource alloc] initWithTitle:@"New deployment…"];
    addDeploymentSource.source = noAppResultsSource;
    addDeploymentSource.action = ^ { [self createNewDeployment]; };
    self.rootAppsListSource = addDeploymentSource;
    
    self.targetView.deploymentsList.dataSource = rootAppsListSource;
    self.targetView.deploymentsList.delegate = rootAppsListSource;
    
    self.servicesListSource = [[ServicesListViewSource alloc] init];
    servicesListSource.delegate = self;
    NoResultsListViewSource *noServiceResultsSource = [[NoResultsListViewSource alloc] init];
    noServiceResultsSource.source = servicesListSource;
    AddItemListViewSource *addServiceSource = [[AddItemListViewSource alloc] initWithTitle:@"New service…"];
    addServiceSource.source = noServiceResultsSource;
    addServiceSource.action = ^ { [self createNewService]; };
    
    self.rootServicesListSource = addServiceSource;
    
    self.targetView.servicesList.dataSource = rootServicesListSource;
    self.targetView.servicesList.delegate = rootServicesListSource;
}

- (void)updateApps {
    self.client = [[FoundryClient alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:target]];
    
    NSArray *subscriables = @[ [client getApps], [client getServices] ];
    
    self.associatedDisposable = [[[RACSubscribable combineLatest:subscriables] showLoadingViewInView:self.view] subscribeNext:^ (id x) {
        RACTuple *t = (RACTuple *)x;
        appsListSource.apps = t.first;
        servicesListSource.services = t.second;
        [targetView.deploymentsList reloadData];
        [targetView.servicesList reloadData];
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
    NSError *error;
    NSArray *configuredApps = [[ThorBackend shared] getConfiguredApps:&error];
    return [self deploymentForApp:app] == nil && configuredApps.count > 0;
}

- (Deployment *)deploymentForApp:(FoundryApp *)app {
    NSError *error;
    NSArray *deployments = [[[ThorBackend shared] getDeploymentsForTarget:self.target error:&error] filter:^ BOOL (id d) { return [((Deployment *)d).name isEqual:app.name]; }];
    return deployments.count ? deployments[0] : nil;
}

- (void)selectedService:(FoundryService *)service {
    NSLog(@"clicked on service %@", service);
}

- (void)accessoryButtonClickedForService:(FoundryService *)service {
    NSAlert *alert = [NSAlert confirmDeleteServiceDialog];
    
    [alert presentSheetModalForWindow:self.view.window didEndBlock:^ (NSInteger returnCode) {
        if (returnCode == NSAlertDefaultReturn) {
            self.associatedDisposable = [[client deleteServiceWithName:service.name] subscribeError:^(NSError *error) {
                [NSApp presentError:error];
            } completed:^{
                [self updateApps];
            }];
        }
    }];
}

- (void)createNewService {
    
    __block WizardController *wizardController;
    __block FoundryServiceInfo *selectedServiceInfo;
    
    TableController *tableController = [[TableController alloc] initWithSubscribable:[[client getServicesInfo] select:^id(id servicesInfo) {
        return [servicesInfo map:^id(id x) {
            FoundryServiceInfo *serviceInfo = (FoundryServiceInfo *)x;
            
            TableItem *item = [[TableItem alloc] init];
            item.view = ^ NSView *(NSTableView *tableView, NSTableColumn *column, NSInteger row) {
                TableCell *cell = [[TableCell alloc] init];
                cell.label.stringValue = [NSString stringWithFormat:@"%@ v%@", serviceInfo.vendor, serviceInfo.version];
                return cell;
            };
            item.selected = ^ {
                selectedServiceInfo = serviceInfo;
            };
            return item;
        }];
    }]];
    
    WizardTableController *wizardTableController = [[WizardTableController alloc] initWithTableController:tableController commitBlock:^{
        
        FoundryService *service = [[FoundryService alloc] init];
        service.name = selectedServiceInfo.vendor;
        service.vendor = selectedServiceInfo.vendor;
        service.version = selectedServiceInfo.version;
        service.type = selectedServiceInfo.type;
        
        ServicePropertiesController *servicePropertiesController = [[ServicePropertiesController alloc] initWithClient:self.client];
        servicePropertiesController.title = @"Create service";
        servicePropertiesController.service = service;
        
        [wizardController pushViewController:servicePropertiesController animated:YES];
    } rollbackBlock:nil];
    
    
    wizardTableController.title = @"Create new service";
    wizardTableController.commitButtonTitle = @"Next";
    
    wizardController = [[WizardController alloc] initWithRootViewController:wizardTableController];
    [wizardController presentModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSOKButton)
            [self updateApps];
    }];

}

- (TableController *)createAppTableController {
    return [[TableController alloc] initWithSubscribable:[[RACSubscribable performBlockInBackground:^ id {
        return [[ThorBackend shared] getConfiguredApps:nil];
    }] select:^id(id configuredApps) {
        return [configuredApps map:^id(id x) {
            App *app = (App *)x;
            
            TableItem *item = [[TableItem alloc] init];
            item.view = ^ NSView *(NSTableView *tableView, NSTableColumn *column, NSInteger row) {
                TableCell *cell = [[TableCell alloc] init];
                cell.label.stringValue = [NSString stringWithFormat:@"%@", app.displayName];
                return cell;
            };
            item.selected = ^ {
                tableSelectedApp = app;
            };
            return item;
        }];
    }]];
}

- (void)createNewDeployment {
    NSError *error;
    if (![[ThorBackend shared] getConfiguredApps:&error].count)
        [self presentNoConfiguredAppsDialog];
    
    __block WizardController *wizardController;
    __block App *selectedApp;
    
    TableController *tableController = [self createAppTableController];
        
    WizardTableController *wizardTableController = [[WizardTableController alloc] initWithTableController:tableController commitBlock:^{
        DeploymentPropertiesController *deploymentController = [DeploymentPropertiesController newDeploymentPropertiesControllerWithApp:tableSelectedApp target:target];
        deploymentController.title = @"Create Deployment";
        [wizardController pushViewController:deploymentController animated:YES];
    } rollbackBlock:nil];
    
    wizardTableController.title = @"Choose App";
    wizardTableController.commitButtonTitle = @"Next";
    
    wizardController = [[WizardController alloc] initWithRootViewController:wizardTableController];
    [wizardController presentModalForWindow:self.view.window didEndBlock:^ (NSInteger returnCode) {
        if (returnCode == NSOKButton)
            [self updateApps];
    }];
}

- (void)createDeploymentForApp:(FoundryApp *)foundryApp {
    __block WizardController *wizardController;
    
    TableController *tableController = [self createAppTableController];
    
    WizardTableController *wizardTableController = [[WizardTableController alloc] initWithTableController:tableController commitBlock:^{
        
        Deployment *deployment = [Deployment deploymentWithApp:tableSelectedApp target:self.target];
        deployment.name = foundryApp.name;
        
        NSError *error;
        
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
        }
        
        [wizardController dismissWithReturnCode:NSOKButton];
    } rollbackBlock:nil];
    
    wizardTableController.title = @"Associate deployment with app";
    wizardTableController.commitButtonTitle = @"Done";
    
    wizardController = [[WizardController alloc] initWithRootViewController:wizardTableController];
    [wizardController presentModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSOKButton)
            [self updateApps];
    }];
}

- (void)presentNoConfiguredAppsDialog {
    NSAlert *alert = [NSAlert noConfiguredAppsDialog];
    [alert presentSheetModalForWindow:self.view.window didEndBlock:nil];
}

@end
