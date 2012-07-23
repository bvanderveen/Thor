#import "AppsController.h"
#import "AppsView.h"
#import "AddTargetController.h"

@implementation AppsController

@synthesize title, breadcrumbController;

- (id)init {
    return [self initWithTitle:@"Apps"];
}

- (id)initWithTitle:(NSString *)leTitle {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.title = leTitle;
    }
    return self;
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (void)loadView {
    NSError *error = nil;
    NSArray *apps = [[ThorBackend shared] getConfiguredApps:&error];
    
    AppsView *appsView = [[AppsView alloc] initWithApps:apps];
    
    appsView.bar.barButton.target = self;
    appsView.bar.barButton.action = @selector(addCloudClicked);
    appsView.delegate = self;
    self.view = appsView;
}

- (void)clickedAppNamed:(NSString *)name {
    [self.breadcrumbController pushViewController:[[AppsController alloc] initWithTitle:name] animated:YES];
}

- (void)addCloudClicked {
    
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,500,500) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    AddTargetController *addApp = [[AddTargetController alloc] init];
    window.contentView = addApp.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
    
    
}

@end
