#import "TargetController.h"
#import "TargetPropertiesController.h"
#import "SheetWindow.h"
#import "NSObject+AssociateDisposable.h"
#import "DeploymentController.h"
#import "DeploymentMemoryTransformer.h"
#import "NSFont+LineHeight.h"

@interface AppCell : ListCell

@property (nonatomic, strong) FoundryApp *app;

@end

@implementation AppCell

@synthesize app = _app;

- (void)setApp:(FoundryApp *)app {
    _app = app;
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSFont *nameFont = [NSFont boldSystemFontOfSize:12];
    
    [_app.name drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight, self.bounds.size.width, nameFont.lineHeight) withAttributes:@{
        NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
         NSFontAttributeName : nameFont
     }];
    
    NSFont *memoryFont = [NSFont systemFontOfSize:12];
    [[NSString stringWithFormat:@"%ld MB memory", _app.memory] drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight - memoryFont.lineHeight, self.bounds.size.width, memoryFont.lineHeight) withAttributes:@{
        NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
        NSFontAttributeName : memoryFont
     }];
}

@end

@interface TargetController ()

@property (nonatomic, strong) NSArray *apps;
@property (nonatomic, strong) FoundryService *service;
@property (nonatomic, strong) TargetPropertiesController *targetPropertiesController;

@end

@implementation TargetController

@synthesize target = _target, targetView, breadcrumbController, title, apps, service, targetPropertiesController;

- (void)setTarget:(Target *)value {
    _target = value;
    self.service = [[FoundryService alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:value]];
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (id)init {
    if (self = [super initWithNibName:@"TargetView" bundle:[NSBundle mainBundle]]) {
        self.title = @"Cloud";
    }
    return self;
}

- (void)viewWillAppear {
    self.associatedDisposable = [[service getApps] subscribeNext:^(id x) {
        self.apps = x;
        [targetView.deploymentsList reloadData];
        targetView.needsLayout = YES;
    } error:^(NSError *error) {
        [NSApp presentError:error];
    }];
}

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    return apps.count;
}

- (NSView *)listView:(ListView *)listView viewForRow:(NSUInteger)row {
    AppCell *cell = [[AppCell alloc] initWithFrame:NSZeroRect];
    cell.app = apps[row];
    return cell;
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    FoundryApp *app = apps[row];
    Deployment *deployment = [Deployment deploymentInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    deployment.appName = app.name;
    deployment.target = self.target;
    
    DeploymentController *deploymentController = [[DeploymentController alloc] initWithDeployment:deployment];
    [self.breadcrumbController pushViewController:deploymentController animated:YES];
}

- (void)editClicked:(id)sender {
    self.targetPropertiesController = [[TargetPropertiesController alloc] init];
    self.targetPropertiesController.editing = YES;
    self.targetPropertiesController.target = self.target;
    
    NSWindow *window = [SheetWindow sheetWindowWithView:targetPropertiesController.view];
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.targetPropertiesController = nil;
    [sheet orderOut:self];
}

- (void)deleteClicked:(id)sender {
    [[ThorBackend sharedContext] deleteObject:self.target];
    NSError *error;
    
    if (![[ThorBackend sharedContext] save:&error]) {
        [NSApp presentError:error];
        return;
    }
    
    [self.breadcrumbController popViewControllerAnimated:YES];
}

@end
