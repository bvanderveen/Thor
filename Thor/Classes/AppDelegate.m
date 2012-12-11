#import "AppDelegate.h"
#import "DeploymentMemoryTransformer.h"
#import "SourceListController.h"
#import "TargetController.h"
#import "AppController.h"
#import "BreadcrumbController.h"
#import "ThorCore.h"
#import "TargetPropertiesController.h"
#import "NSAlert+Dialogs.h"
#import "SplitViewController.h"
#import "AppListController.h"
#import "DeploymentController.h"

@interface AppDelegate ()

@property (nonatomic, strong) SplitViewController *splitViewController;

@property (nonatomic, strong) SourceListController *sourceListController;
@property (nonatomic, strong) AppListController *appListController;
@property (nonatomic, strong) DeploymentController *deploymentController;

@end

@implementation AppDelegate

@synthesize splitViewController, sourceListController, appListController, deploymentController, selectedTarget, selectedAppName;

- (id)init {
    if (self = [super init]) {
        self.splitViewController = [[SplitViewController alloc] init];
        
        self.sourceListController = [[SourceListController alloc] init];
        
        self.sourceListController.selectedModel = ^ (id m) {
            self.selectedTarget = m;
        };
        self.sourceListController.deleteModelConfirmation = ^ NSAlert *(id m) {
            return [NSAlert confirmDeleteTargetDialog];
        };
        
        self.appListController = [[AppListController alloc] init];
        [appListController bind:@"target" toObject:self withKeyPath:@"selectedTarget" options:nil];
        
        self.deploymentController = [[DeploymentController alloc] init];
        [deploymentController bind:@"target" toObject:self withKeyPath:@"selectedTarget" options:nil];
        [deploymentController bind:@"appName" toObject:self withKeyPath:@"selectedAppName" options:nil];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    window.delegate = self;
    [splitViewController.view addSubview:sourceListController.view];
    [splitViewController.view addSubview:appListController.view];
    [splitViewController.view addSubview:deploymentController.view];
    
    [view addSubview:splitViewController.view];
    splitViewController.view.frame = view.bounds;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
}

//- (void)newApp:(id)sender {
//    App *app = [App appInsertedIntoManagedObjectContext:nil];
//    
//    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//    openPanel.canChooseDirectories = YES;
//    openPanel.canChooseFiles = NO;
//    openPanel.allowsMultipleSelection = NO;
//    [openPanel beginSheetModalForWindow:window completionHandler:^ void (NSInteger result) {
//        if (result == NSFileHandlingPanelOKButton) {
//            app.localRoot = [[openPanel.URLs objectAtIndex:0] path];
//            app.displayName = app.lastPathComponent;
//            [[ThorBackend sharedContext] insertObject:app];
//            
//            NSError *error = nil;
//            if (![[ThorBackend sharedContext] save:&error]) {
//                [NSApp presentError:error];
//                NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
//            }
//            
//            [sourceListController updateAppsAndTargets];
//        }
//    }];
//}

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

@end
