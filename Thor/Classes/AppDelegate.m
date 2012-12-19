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
#import "RACSubscribable+Extensions.h"
#import "DeploymentPropertiesController.h"

@interface AppDelegate ()

@property (nonatomic, strong) SourceListController *sourceListController;

@end

@implementation AppDelegate

@synthesize activityController, sourceListController, selectedTarget, selectedDeployment, tableSelectedApp, targetController;

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

- (void)newApp:(id)sender {
    App *app = [App appInsertedIntoManagedObjectContext:nil];
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    openPanel.allowsMultipleSelection = NO;
    [openPanel beginSheetModalForWindow:window completionHandler:^ void (NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            app.localRoot = [[openPanel.URLs objectAtIndex:0] path];
            app.displayName = app.lastPathComponent;
            [[ThorBackend sharedContext] insertObject:app];
            
            NSError *error = nil;
            if (![[ThorBackend sharedContext] save:&error]) {
                [NSApp presentError:error];
                NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
            }
            
            [sourceListController updateAppsAndTargets];
        }
    }];
}

- (void)newTarget:(id)sender {
    TargetPropertiesController *targetPropertiesController = [[TargetPropertiesController alloc] init];
    targetPropertiesController.target = [Target targetInsertedIntoManagedObjectContext:nil];
    WizardController *wizardController = [[WizardController alloc] initWithRootViewController:targetPropertiesController];
    targetPropertiesController.title = @"Create Cloud";
    [wizardController presentModalForWindow:window didEndBlock:^ (NSInteger returnCode) {
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
        //if (returnCode == NSOKButton)
        //    [self updateApps];
    }];
}

- (IBAction)editDeployment:(id)sender {
    [selectedDeployment editClicked:nil];
}

- (IBAction)startDeployment:(id)sender {
    [selectedDeployment startClicked:nil];
}

- (IBAction)stopDeployment:(id)sender {
    [selectedDeployment stopClicked:nil];
}

- (IBAction)restartDeployment:(id)sender {
    [selectedDeployment restartClicked:nil];
}

- (void)presentNoConfiguredAppsDialog {
    NSAlert *alert = [NSAlert noConfiguredAppsDialog];
    [alert presentSheetModalForWindow:window didEndBlock:nil];
}

- (IBAction)newDeployment:(id)sender {
    NSError *error;
    if (![[ThorBackend shared] getConfiguredApps:&error].count)
        [self presentNoConfiguredAppsDialog];
    
    __block WizardController *wizardController;
    __block App *selectedApp;
    
    TableController *tableController = [self createAppTableController];
    
    WizardTableController *wizardTableController = [[WizardTableController alloc] initWithTableController:tableController commitBlock:^{
        DeploymentPropertiesController *deploymentController = [DeploymentPropertiesController newDeploymentPropertiesControllerWithApp:tableSelectedApp target:selectedTarget];
        deploymentController.title = @"Create Deployment";
        [wizardController pushViewController:deploymentController animated:YES];
    } rollbackBlock:nil];
    
    wizardTableController.title = @"Choose App";
    wizardTableController.commitButtonTitle = @"Next";
    
    wizardController = [[WizardController alloc] initWithRootViewController:wizardTableController];
    [wizardController presentModalForWindow:window didEndBlock:^ (NSInteger returnCode) {
        if (returnCode == NSOKButton)
            [targetController updateApps];
    }];
}

- (IBAction)newService:(id)sender {
    
}

- (IBAction)bindService:(id)sender {
    
}

@end
