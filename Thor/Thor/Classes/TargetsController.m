#import "TargetsController.h"
#import "AddTargetController.h"
#import "TargetsView.h"

@interface CustomWindow : NSWindow

@end

@implementation CustomWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

@end

@interface TargetsController ()

@property (nonatomic, strong) AddTargetController *addTargetController;
@property (nonatomic, readonly) TargetsView *targetsView;

@end

@implementation TargetsController

@synthesize title, breadcrumbController, addTargetController, targets;

- (TargetsView *)targetsView {
    return (TargetsView *)self.view;
}

- (id)init {
    return [self initWithTitle:@"Apps"];
}

- (id)initWithTitle:(NSString *)leTitle {
    if (self = [super initWithNibName:@"TargetsView" bundle:[NSBundle mainBundle]]) {
        self.title = leTitle;
    }
    return self;
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (void)updateTargets {
    NSError *error = nil;
    self.targets = [[[ThorBackend shared] getConfiguredTargets:&error] mutableCopy];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateTargets];
    self.targetsView.bar.barButton.target = self;
    self.targetsView.bar.barButton.action = @selector(addTargetClicked);
    self.targetsView.delegate = self;
}

-(void)insertObject:(Target *)t inTargetsAtIndex:(NSUInteger)index {
    [targets insertObject:t atIndex:index];
}

-(void)removeObjectFromTargetsAtIndex:(NSUInteger)index {
    [targets removeObjectAtIndex:index];
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
    [self updateTargets];
    self.addTargetController = nil;
    [sheet orderOut:self];
}

@end
