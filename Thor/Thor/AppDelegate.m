#import "AppDelegate.h"
#import "ToolbarTabController.h"

@interface AppDelegate ()

@property (nonatomic, strong) ToolbarTabController *toolbarTabController;

@end

@implementation AppDelegate

@synthesize toolbarTabController;

- (id)init {
    if (self = [super init]) {
        self.toolbarTabController = [[ToolbarTabController alloc] init];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    window.toolbar = toolbarTabController.toolbar;
    [view addSubview:toolbarTabController.view];
    toolbarTabController.view.frame = view.bounds;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
}

@end
