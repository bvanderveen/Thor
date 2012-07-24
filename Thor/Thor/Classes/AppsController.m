#import "AppsController.h"
#import "AppsView.h"
#import "AddTargetController.h"

@interface CustomWindow : NSWindow

@end

@implementation CustomWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

@end

@interface AppsController ()

@property (nonatomic, strong) AddTargetController *addTargetController;

@end

@implementation AppsController

@synthesize title, breadcrumbController, addTargetController;

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
    self.addTargetController = [[AddTargetController alloc] init];
    
    NSWindow *window = [[CustomWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = self.addTargetController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = addTargetController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSLog(@"sheet did end");
    self.addTargetController = nil;
    [sheet orderOut:self];
}

@end
