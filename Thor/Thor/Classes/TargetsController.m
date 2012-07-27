#import "TargetsController.h"
#import "TargetPropertiesController.h"
#import "TargetsView.h"
#import "TargetController.h"

@interface CustomWindow : NSWindow

@end

@implementation CustomWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

@end

@interface TargetsController ()

@property (nonatomic, strong) TargetPropertiesController *targetPropertiesController;
@property (nonatomic, readonly) TargetsView *targetsView;

@end

@implementation TargetsController

@synthesize title, breadcrumbController, targetPropertiesController, targets;

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

- (void)targetClicked:(NSButton *)sender {
    // heinous!
    NSUInteger index = [[[[sender superview] superview] subviews] indexOfObject:[sender superview]];
    Target *target = [targets objectAtIndex:index];
    
    [self.breadcrumbController pushViewController:[[TargetController alloc] initWithTarget:target] animated:YES];
}

- (void)addTargetClicked {
    self.targetPropertiesController = [[TargetPropertiesController alloc] init];
    
    NSWindow *window = [[CustomWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = self.targetPropertiesController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = targetPropertiesController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [self updateTargets];
    self.targetPropertiesController = nil;
    [sheet orderOut:self];
}

@end
