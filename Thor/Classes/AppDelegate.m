#import "AppDelegate.h"
#import "DeploymentMemoryTransformer.h"
#import "SourceListController.h"
#import "TargetController.h"
#import "AppController.h"
#import "BreadcrumbController.h"
#import "ThorCore.h"
#import "TargetPropertiesController.h"
#import "NSAlert+Dialogs.h"
#import "Sequence.h"
#import "RACSignal+Extensions.h"
#import "DeploymentPropertiesController.h"
#import "ServicePropertiesController.h"

@interface AppDelegate ()

@property (nonatomic, strong) SourceListController *sourceListController;

@end

@implementation AppDelegate

+ (AppDelegate *)shared {
    return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

@synthesize activityWindow, activityController, sourceListController, selectedTarget, selectedApp, tableSelectedApp, selectedAppRefreshing, selectedTargetRefreshing;

- (id)init {
    if (self = [super init]) {
        self.sourceListController = [[SourceListController alloc] init];
        self.sourceListController.controllerForModel = ^ NSViewController *(id m) {
            NSViewController<BreadcrumbControllerAware> *controller = nil;
            if ([m isKindOfClass:[Target class]]) {
                TargetController *c = [[TargetController alloc] init];
                c.target = m;
                controller = c;
            }
            else if ([m isKindOfClass:[App class]]) {
                AppController *appController = [[AppController alloc] init];
                appController.app = m;
                controller = appController;
            }
            
            if (controller)
                return [[BreadcrumbController alloc] initWithRootViewController:controller];
            
            return nil;
        };
        
        self.sourceListController.deleteModelConfirmation = ^ NSAlert *(id m) {
            if ([m isKindOfClass:[Target class]])
                return [NSAlert confirmDeleteTargetDialog];
            if ([m isKindOfClass:[App class]])
                return [NSAlert confirmDeleteAppDialog];
            return nil;
        };
        
        self.activityController = [[ActivityController alloc] init];
        
        self.selectedTargetRefreshing = [RACSubject subject];
        self.selectedAppRefreshing = [RACSubject subject];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [window setExcludedFromWindowsMenu:YES];
    [activityWindow setExcludedFromWindowsMenu:YES];
    
    NSMenuItem *thorMenuItem = [[NSMenuItem alloc] initWithTitle:@"Main Window" action:@selector(makeKeyAndOrderFront:) keyEquivalent:@"0"];
    thorMenuItem.target = window;
    thorMenuItem.keyEquivalentModifierMask = NSCommandKeyMask;
    
    NSMenuItem *activityMenuItem = [[NSMenuItem alloc] initWithTitle:@"Activity" action:@selector(makeKeyAndOrderFront:) keyEquivalent:@"1"];
    activityMenuItem.target = activityWindow;
    activityMenuItem.keyEquivalentModifierMask = NSCommandKeyMask;
    
    [windowMenu insertItem:activityMenuItem atIndex:3];
    [windowMenu insertItem:thorMenuItem atIndex:3];
    
    [activityWindow.contentView addSubview:activityController.view];
    activityController.view.frame = ((NSView *)activityWindow.contentView).bounds;
    activityController.view.needsLayout = YES;
    [activityController.view layoutSubtreeIfNeeded];
    
    [view addSubview:sourceListController.view];
    sourceListController.view.frame = view.bounds;
    
    [self application:nil willPresentError:[NSError errorWithDomain:@"Launched" code:100 userInfo:@{@"": @"bars"}]];
}

- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error {
    [Log logError:error];
    return error;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
//    NSMenuItem *activityMenuItem = [[windowMenu.itemArray filter:^ BOOL (id i) { return [((NSMenuItem *)i).title isEqual:@"Activity"]; }] lastObject];
//    
//    [activityMenuItem setKeyEquivalent:@"1"];
//    [activityMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
//    
//    
//    NSMenuItem *thorMenuItem = [[windowMenu.itemArray filter:^ BOOL (id i) { return [((NSMenuItem *)i).title isEqual:@"Thor"]; }] lastObject];
//    
//    [thorMenuItem setKeyEquivalent:@"0"];
//    [thorMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
}

- (TableController *)createAppTableController {
    return [[TableController alloc] initWithSignal:[[RACSignal performBlockInBackground:^ id {
        return [[ThorBackend shared] getConfiguredApps:nil];
    }] map:^id(id configuredApps) {
        return [configuredApps map:^id(id x) {
            App *app = (App *)x;
            
            TableItem *item = [[TableItem alloc] init];
            item.view = ^ NSView *(NSTableView *tableView, NSTableColumn *column, NSInteger row) {
                TableCell *cell = [[TableCell alloc] init];
                cell.label.stringValue = [NSString stringWithFormat:@"%@", app.displayName];
                cell.imageView.image = [NSImage imageNamed:@"AppIconSmall.png"];
                return cell;
            };
            item.selected = ^ {
                [Log logFormat:@"createAppTableController: tableSelectedApp %@", app];
                tableSelectedApp = app;
            };
            return item;
        }];
    }]];
}

- (void)newApp:(id)sender {
    [Log logMessage:@"newApp:"];
    
    App *app = [App appInsertedIntoManagedObjectContext:nil];
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = YES;
    openPanel.allowedFileTypes = @[ @"war" ];
    openPanel.allowsMultipleSelection = NO;
    [openPanel beginSheetModalForWindow:window completionHandler:^ void (NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            app.localRoot = [[openPanel.URLs objectAtIndex:0] path];
            app.displayName = [[app.localRoot pathComponents] lastObject];
            [[ThorBackend sharedContext] insertObject:app];
            
            NSError *error = nil;
            if (![[ThorBackend sharedContext] save:&error]) {
                [NSApp presentError:error];
                NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
            }
            
            [Log logFormat:@"newApp: added app %@", app.displayName];
            
            [sourceListController updateAppsAndTargets];
        }
    }];
}

- (void)newTarget:(id)sender {
    [Log logFormat:@"newTarget:"];
    TargetPropertiesController *targetPropertiesController = [[TargetPropertiesController alloc] init];
    targetPropertiesController.target = [Target targetInsertedIntoManagedObjectContext:nil];
    targetPropertiesController.title = @"Create Cloud";
    WizardController *wizardController = [[WizardController alloc] initWithRootViewController:targetPropertiesController];
    wizardController.isSinglePage = YES;
    [wizardController presentModalForWindow:window didEndBlock:^ (NSInteger returnCode) {
        [Log logFormat:@"newTarget: return code %ld", returnCode];
        if (returnCode == NSOKButton)
            [sourceListController updateAppsAndTargets];
    }];
}

- (void)editTarget:(id)sender {
    TargetPropertiesController *targetPropertiesController = [[TargetPropertiesController alloc] init];
    targetPropertiesController.editing = YES;
    targetPropertiesController.target = self.selectedTarget;
    targetPropertiesController.title = @"Cloud Settings";
    
    WizardController *wizardController = [[WizardController alloc] initWithRootViewController:targetPropertiesController];
    wizardController.isSinglePage = YES;
    [wizardController presentModalForWindow:window didEndBlock:^ (NSInteger returnCode) {
        [Log logFormat:@"editTarget: return code %ld", returnCode];
        //if (returnCode == NSOKButton)
        //    [self updateApps];
    }];
}

- (IBAction)editDeployment:(id)sender {
    DeploymentPropertiesController *deploymentPropertiesController = [DeploymentPropertiesController deploymentPropertiesControllerWithApp:selectedApp client:[FoundryClient clientWithEndpoint:[FoundryEndpoint endpointWithTarget:selectedTarget]]];
    
    deploymentPropertiesController.title = @"Update deployment";
    
    WizardController *wizard = [[WizardController alloc] initWithRootViewController:deploymentPropertiesController];
    wizard.isSinglePage = YES;
    [wizard presentModalForWindow:window didEndBlock:^(NSInteger returnCode) {
        [selectedAppRefreshing sendNext:[RACUnit defaultUnit]];
    }];
}

- (id<FoundryClient>)clientForSelectedTarget {
    return [FoundryClient clientWithEndpoint:[FoundryEndpoint endpointWithTarget:selectedTarget]];
}

- (IBAction)startDeployment:(id)sender {
    [[[self clientForSelectedTarget] updateApp:selectedApp withState:FoundryAppStateStarted] subscribeCompleted:^{
    }];
}

- (IBAction)stopDeployment:(id)sender {
    [[[self clientForSelectedTarget] updateApp:selectedApp withState:FoundryAppStateStopped] subscribeCompleted:^{
    }];
}

- (IBAction)restartDeployment:(id)sender {
    id<FoundryClient> client = [self clientForSelectedTarget];
    
    [[client updateApp:selectedApp withState:FoundryAppStateStopped] subscribeCompleted:^{
        [[client updateApp:selectedApp withState:FoundryAppStateStarted] subscribeCompleted:^{
            
        }];
    }];
}

- (void)presentNoConfiguredAppsDialog {
    NSAlert *alert = [NSAlert noConfiguredAppsDialog];
    [alert presentSheetModalForWindow:window didEndBlock:nil];
}

- (IBAction)newDeployment:(id)sender {
    [Log logMessage:@"newDeployment:"];
    
    NSError *error;
    if (![[ThorBackend shared] getConfiguredApps:&error].count) {
        [Log logMessage:@"newDeployment: no configured apps"];
        [self presentNoConfiguredAppsDialog];
    }
    
    __block WizardController *wizardController;
    __block App *selectedApp;
    
    TableController *tableController = [self createAppTableController];
    
    WizardTableController *wizardTableController = [[WizardTableController alloc] initWithTableController:tableController commitBlock:^{
        DeploymentPropertiesController *deploymentController = [DeploymentPropertiesController newDeploymentPropertiesControllerWithApp:tableSelectedApp target:selectedTarget];
        deploymentController.title = @"Create Deployment";
        [Log logFormat:@"newDeployment: selected app %@, selected target %@", tableSelectedApp, selectedTarget];
        [wizardController pushViewController:deploymentController animated:YES];
    } rollbackBlock:nil];
    
    wizardTableController.title = @"Choose App";
    wizardTableController.commitButtonTitle = @"Next";
    
    wizardController = [[WizardController alloc] initWithRootViewController:wizardTableController];
    [wizardController presentModalForWindow:window didEndBlock:^ (NSInteger returnCode) {
        [Log logFormat:@"newDeployment: return code %ld", returnCode];
        if (returnCode == NSOKButton)
            [selectedTargetRefreshing sendNext:[RACUnit defaultUnit]];
    }];
}

- (IBAction)newService:(id)sender {
    [Log logMessage:@"newService:"];
    __block WizardController *wizardController;
    __block FoundryServiceInfo *selectedServiceInfo;
    
    TableController *tableController = [[TableController alloc] initWithSignal:[[[self clientForSelectedTarget] getServicesInfo] map:^id(id servicesInfo) {
        [Log logFormat:@"newService: gotServicesInfo %@", servicesInfo];
        return [servicesInfo map:^id(id x) {
            FoundryServiceInfo *serviceInfo = (FoundryServiceInfo *)x;
            
            TableItem *item = [[TableItem alloc] init];
            item.view = ^ NSView *(NSTableView *tableView, NSTableColumn *column, NSInteger row) {
                TableCell *cell = [[TableCell alloc] init];
                cell.imageView.image = [NSImage imageNamed:@"ServiceIconSmall.png"];
                cell.label.stringValue = [NSString stringWithFormat:@"%@ v%@", serviceInfo.vendor, serviceInfo.version];
                return cell;
            };
            item.selected = ^ {
                [Log logFormat:@"newService: selected serviceInfo %@", serviceInfo];
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
        
        [Log logFormat:@"newService: picked service %@", service];
        
        ServicePropertiesController *servicePropertiesController = [[ServicePropertiesController alloc] initWithClient:[self clientForSelectedTarget]];
        servicePropertiesController.title = @"Create service";
        servicePropertiesController.service = service;
        
        [wizardController pushViewController:servicePropertiesController animated:YES];
    } rollbackBlock:nil];
    
    wizardTableController.title = @"Create new service";
    wizardTableController.commitButtonTitle = @"Next";
    
    wizardController = [[WizardController alloc] initWithRootViewController:wizardTableController];
    [wizardController presentModalForWindow:window didEndBlock:^(NSInteger returnCode) {
        [Log logFormat:@"newService: wizard returned with code %ld", returnCode];
        if (returnCode == NSOKButton)
            [selectedTargetRefreshing sendNext:[RACUnit defaultUnit]];
    }];
}

- (IBAction)bindService:(id)sender {
    __block WizardController *wizard;
    __block FoundryService *selectedService;
    [Log logFormat:@"bindService:"];
    
    TableController *tableController = [[TableController alloc] initWithSignal:[[[self clientForSelectedTarget] getServices] map:^id(id lesServices) {
        NSArray *services = lesServices;
        [Log logFormat:@"bindService: found services %@", services];
        
        if (!services.count) {
            NSAlert *alert = [NSAlert noProvisionedServicesDialog];
            [wizard dismissWithReturnCode:NSCancelButton];
            [alert presentSheetModalForWindow:window didEndBlock:nil];
            return @[];
        }
        
        return [lesServices map:^id(id x) {
            FoundryService *service = (FoundryService *)x;
            
            TableItem *item = [[TableItem alloc] init];
            item.view = ^ NSView *(NSTableView *tableView, NSTableColumn *column, NSInteger row) {
                TableCell *cell = [[TableCell alloc] init];
                cell.label.stringValue = [NSString stringWithFormat:@"%@ %@ v%@", service.name, service.vendor, service.version];
                cell.imageView.image = [NSImage imageNamed:@"ServiceIconSmall.png"];
                return cell;
            };
            item.selected = ^ {
                [Log logFormat:@"bindService: selectedService %@", service];
                selectedService = service;
            };
            return item;
        }];
    }]];
    
    WizardTableController *wizardTableController = [[WizardTableController alloc] initWithTableController:tableController commitBlock:^{
        
        [[[[self clientForSelectedTarget] updateApp:selectedApp byAddingServiceNamed:selectedService.name] showLoadingViewInWizard:wizard] subscribeCompleted:^{
            [wizard dismissWithReturnCode:NSOKButton];
        }];
    } rollbackBlock:nil];
    
    wizardTableController.title = @"Bind service";
    wizardTableController.commitButtonTitle = @"OK";
    
    wizard = [[WizardController alloc] initWithRootViewController:wizardTableController];
    wizard.isSinglePage = YES;
    [wizard presentModalForWindow:window didEndBlock:^(NSInteger returnCode) {
        [Log logFormat:@"bindService: return code %ld", returnCode];
        [selectedAppRefreshing sendNext:[RACUnit defaultUnit]];
    }];
}

- (void)clearActivity:(id)sender {
    [activityController clear];
}

@end
