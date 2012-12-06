#import "AppDelegate.h"
#import "DeploymentMemoryTransformer.h"
#import "SourceListController.h"
#import "TargetController.h"
#import "AppController.h"
#import "BreadcrumbController.h"
#import "ThorCore.h"
#import "TargetPropertiesController.h"
#import "NSAlert+Dialogs.h"

@interface AppDelegate ()

@property (nonatomic, strong) SourceListController *sourceListController;

@end

@implementation AppDelegate

@synthesize sourceListController, selectedTarget;

- (id)init {
    if (self = [super init]) {
        self.sourceListController = [[SourceListController alloc] init];
        self.sourceListController.controllerForModel = ^ NSViewController *(id m) {
            NSViewController<BreadcrumbControllerAware> *controller = nil;
            if ([m isKindOfClass:[Target class]]) {
                TargetController *targetController = [[TargetController alloc] init];
                targetController.target = m;
                controller = targetController;
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
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [view addSubview:sourceListController.view];
    sourceListController.view.frame = view.bounds;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
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

@end
