#import "TargetsController.h"
#import "TargetsView.h"
#import "AddTargetController.h"

@interface CustomWindow : NSWindow

@end

@implementation CustomWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

@end

@interface TargetsController ()

@property (nonatomic, strong) AddTargetController *addTargetController;

@end

@implementation TargetsController

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
    NSArray *targets = [[ThorBackend shared] getConfiguredTargets:&error];
    
    TargetsView *targetsView = [[TargetsView alloc] initWithTargets:targets];
    
    targetsView.bar.barButton.target = self;
    targetsView.bar.barButton.action = @selector(addTargetClicked);
    targetsView.delegate = self;
    self.view = targetsView;
}

- (void)clickedTargetNamed:(NSString *)name {
    [self.breadcrumbController pushViewController:[[TargetsController alloc] initWithTitle:name] animated:YES];
}

- (void)addTargetClicked {
    self.addTargetController = [[AddTargetController alloc] init];
    
    NSWindow *window = [[CustomWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = self.addTargetController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = addTargetController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSOKButton) {
        NSError *error = nil;
        [[ThorBackend shared] createConfiguredTarget:addTargetController.target error:&error];
    }
    
    self.addTargetController = nil;
    [sheet orderOut:self];
}

@end
