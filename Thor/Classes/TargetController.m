#import "TargetController.h"
#import "TargetPropertiesController.h"
#import "SheetWindow.h"
#import "NSObject+AssociateDisposable.h"
#import "DeploymentController.h"

@interface TargetController ()

@property (nonatomic, strong) NSArray *apps;
@property (nonatomic, strong) FoundryService *service;
@property (nonatomic, strong) TargetPropertiesController *targetPropertiesController;

@end

static NSArray *appColumns = nil;

@implementation TargetController

+ (void)initialize {
    appColumns = [NSArray arrayWithObjects:@"Name", @"URI", @"Instances", @"Memory", @"Disk", nil];
}

@synthesize target = _target, targetView, breadcrumbController, title, apps, service, targetPropertiesController;

- (void)setTarget:(Target *)value {
    _target = value;
    
    CloudInfo *info = [CloudInfo new];
    
    info.hostname = value.hostname;
    info.email = value.email;
    info.password = value.password;
    
    self.service = [[FoundryService alloc] initWithCloudInfo:info];
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

- (void)awakeFromNib {
    self.associatedDisposable = [[service getApps] subscribeNext:^(id x) {
        self.apps = x;
        [targetView.deploymentsGrid reloadData];
        targetView.needsLayout = YES;
    } error:^(NSError *error) {
        [NSApp presentError:error];
    }];
}

- (NSUInteger)numberOfColumnsForGridView:(GridView *)gridView {
    return appColumns.count;
}

- (NSString *)gridView:(GridView *)gridView titleForColumn:(NSUInteger)columnIndex {
    return [appColumns objectAtIndex:columnIndex];
}

- (NSUInteger)numberOfRowsForGridView:(GridView *)gridView {
    return apps.count;
}

- (NSString *)gridView:(GridView *)gridView titleForRow:(NSUInteger)row column:(NSUInteger)columnIndex {
    FoundryApp *app = [apps objectAtIndex:row];
    
    switch (columnIndex) {
        case 0:
            return app.name;
        case 1:
            return [app.uris objectAtIndex:0];
        case 2:
            return [NSString stringWithFormat:@"%d", app.instances];
        case 3:
            return [NSString stringWithFormat:@"%d", app.memory];
        case 4:
            return [NSString stringWithFormat:@"%d", app.disk];
    }
    
    BOOL columnIndexIsValid = NO;
    assert(columnIndexIsValid);
    return nil;
}

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row {
    FoundryApp *app = [apps objectAtIndex:row];
    
    DeploymentInfo *deploymentInfo = [DeploymentInfo new];
    deploymentInfo.appName = app.name;
    deploymentInfo.target = service.cloudInfo;
    
    DeploymentController *deploymentController = [[DeploymentController alloc] initWithDeploymentInfo:deploymentInfo];
    [self.breadcrumbController pushViewController:deploymentController animated:YES];
}

- (void)editClicked:(id)sender {
    self.targetPropertiesController = [[TargetPropertiesController alloc] init];
    self.targetPropertiesController.editing = YES;
    self.targetPropertiesController.target = self.target;
    
    NSWindow *window = [[SheetWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = self.targetPropertiesController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = targetPropertiesController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.targetPropertiesController = nil;
    [sheet orderOut:self];
}

@end
