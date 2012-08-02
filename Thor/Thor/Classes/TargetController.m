#import "TargetController.h"
#import "TargetPropertiesController.h"
#import "SheetWindow.h"

@interface TargetController ()

@property (nonatomic, strong) NSArray *deployments;
@property (nonatomic, strong) TargetPropertiesController *targetPropertiesController;

@end

static NSArray *deploymentColumns = nil;

@implementation TargetController

+ (void)initialize {
    deploymentColumns = [NSArray arrayWithObjects:@"Name", @"CPU", @"Memory", @"Disk", nil];
}

@synthesize target, targetView, breadcrumbController, title, deployments, targetPropertiesController;

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (id)init {
    if (self = [super initWithNibName:@"TargetView" bundle:[NSBundle mainBundle]]) {
    //if (self = [super initWithNibName:nil bundle:nil]) {
        self.title = @"Cloud";
    }
    return self;
}

- (void)awakeFromNib {    
    self.deployments = [[FixtureVMCService new] getDeploymentsForTarget:target];
    targetView.deploymentsGrid.dataSource = self;
    [targetView.deploymentsGrid reloadData];
}

- (NSUInteger)numberOfColumnsForGridView:(GridView *)gridView {
    return deploymentColumns.count;
}

- (NSString *)gridView:(GridView *)gridView titleForColumn:(NSUInteger)columnIndex {
    return [deploymentColumns objectAtIndex:columnIndex];
}

- (NSUInteger)numberOfRowsForGridView:(GridView *)gridView {
    return deployments.count;
}

- (NSString *)gridView:(GridView *)gridView titleForRow:(NSUInteger)row column:(NSUInteger)columnIndex {
    VMCDeployment *deployment = [deployments objectAtIndex:row];
    
    switch (columnIndex) {
        case 0:
            return deployment.name;
        case 1:
            return deployment.cpu;
        case 2:
            return deployment.memory;
        case 3:
            return deployment.disk;
    }
    
    BOOL columnIndexIsValid = NO;
    assert(columnIndexIsValid);
    return nil;
}

- (void)editClicked:(id)sender {
    self.targetPropertiesController = [[TargetPropertiesController alloc] init];
    self.targetPropertiesController.target = target;
    
    NSWindow *window = [[SheetWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = self.targetPropertiesController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = targetPropertiesController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.targetPropertiesController = nil;
    [sheet orderOut:self];
}

@end
