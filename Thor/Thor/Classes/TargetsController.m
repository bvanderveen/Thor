#import "TargetsController.h"
#import "TargetPropertiesController.h"
#import "TargetsView.h"
#import "TargetController.h"
#import "SheetWindow.h"

@interface TargetsController ()

@property (nonatomic, strong) TargetPropertiesController *targetPropertiesController;
@property (nonatomic, readonly) TargetsView *targetsView;

@end

@implementation TargetsController

@synthesize title, breadcrumbController, targetPropertiesController, targets, arrayController;

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
    [self.arrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)insertObject:(Target *)t inTargetsAtIndex:(NSUInteger)index {
    [targets insertObject:t atIndex:index];
}

- (void)pushSelectedTarget {
    
    Target *target = [self.targets objectAtIndex:arrayController.selectionIndex];
    
    TargetController *targetController = [[TargetController alloc] init];
    targetController.target = target;
    
    [self.breadcrumbController pushViewController:targetController animated:YES];
    NSMutableIndexSet *empty = [NSMutableIndexSet indexSet];
    [empty removeAllIndexes];
    arrayController.selectionIndexes = empty;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == arrayController) {
        if (arrayController.selectionIndexes.count)
            [self performSelector:@selector(pushSelectedTarget) withObject:nil afterDelay:0];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)removeObjectFromTargetsAtIndex:(NSUInteger)index {
    [targets removeObjectAtIndex:index];
}

- (void)addTargetClicked {
    self.targetPropertiesController = [[TargetPropertiesController alloc] init];
    self.targetPropertiesController.target = [Target targetInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    
    NSWindow *window = [[SheetWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = self.targetPropertiesController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = targetPropertiesController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [self updateTargets];
    self.targetPropertiesController = nil;
    [sheet orderOut:self];
}

@end
