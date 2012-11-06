#import "AppDelegate.h"
#import "ToolbarTabController.h"
#import "DeploymentMemoryTransformer.h"
#import "SourceListController.h"
#import "TargetController.h"
#import "AppController.h"
#import "BreadcrumbController.h"

@interface AppDelegate ()

@property (nonatomic, strong) ToolbarTabController *toolbarTabController;
@property (nonatomic, strong) SourceListController *sourceListController;

@end

@implementation AppDelegate

@synthesize toolbarTabController, sourceListController;

+ (void)initialize {
    [NSValueTransformer setValueTransformer:[DeploymentMemoryTransformer new] forName:@"DeploymentMemoryTransformer"];
}

- (id)init {
    if (self = [super init]) {
        //self.toolbarTabController = [[ToolbarTabController alloc] init];
        self.sourceListController = [[SourceListController alloc] init];
        self.sourceListController.controllerForModel = ^ NSViewController * (id m) {
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
            
            return [[BreadcrumbController alloc] initWithRootViewController:controller];
        };
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    //window.toolbar = toolbarTabController.toolbar;
    //[view addSubview:toolbarTabController.view];
    //toolbarTabController.view.frame = view.bounds;
    
    
    [view addSubview:sourceListController.view];
    sourceListController.view.frame = view.bounds;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
}

@end
