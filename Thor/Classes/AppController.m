#import "AppController.h"
#import "AppPropertiesController.h"
#import "SheetWindow.h"
#import "DeploymentController.h"

@interface AppController ()

@property (nonatomic, strong) AppPropertiesController *appPropertiesController;

@end

static NSArray *deploymentColumns = nil;

@implementation AppController

+ (void)initialize {
    deploymentColumns = [NSArray arrayWithObjects:@"App name", @"Cloud name", @"Cloud hostname", nil];
}

@synthesize app, deployments, appPropertiesController, breadcrumbController, title, appView;

- (id)init {
    if (self = [super initWithNibName:@"AppView" bundle:[NSBundle mainBundle]]) {
        //if (self = [super initWithNibName:nil bundle:nil]) {
        self.title = @"App";
    }
    return self;
}

- (void)awakeFromNib {
    Deployment *d0 = [Deployment new];
    d0.displayName = @"Cloud 1 Foo";
    d0.appName = @"foo";
    d0.hostname = @"api.cloud1.com";
    
    Deployment *d1 = [Deployment new];
    d1.displayName = @"Cloud 2 Foo";
    d1.appName = @"foo";
    d1.hostname = @"api.cloud2.com";
    
    self.deployments = [NSArray arrayWithObjects:d0, d1, d0, d1, d0, d1, d0, d1, d1, d0, d1, d0, d1, d0, d1, nil];
    
    [self.appView.deploymentsGrid reloadData];
    //[self.appView setNeedsLayout:YES];
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
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
    Deployment *deployment = [deployments objectAtIndex:row];
    
    switch (columnIndex) {
        case 0:
            return deployment.appName;
        case 1:
            return deployment.hostname;
        case 2:
            return deployment.hostname;
    }
    
    BOOL columnIndexIsValid = NO;
    assert(columnIndexIsValid);
    return nil;
}

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row {
    
    Deployment *deployment = [deployments objectAtIndex:row];
    
    DeploymentInfo *deploymentInfo = [DeploymentInfo new];
    
    deploymentInfo.appName = deployment.appName;
    deploymentInfo.target = [VMCTarget new];
    deploymentInfo.target.hostname = deployment.hostname;
    
    // need to get these from the configured target. e.g.,
    // deploymentInfo.target.email = deployment.target.email;
    // deploymentInfo.target.password = deployment.target.password;
    // although the target may be provided by a lookup…
    
    deploymentInfo.target.email = @"some email";
    deploymentInfo.target.password = @"some password";
    
    DeploymentController *deploymentController = [[DeploymentController alloc] initWithDeploymentInfo:deploymentInfo];
    [self.breadcrumbController pushViewController:deploymentController animated:YES];
}

- (void)editClicked:(id)sender {
    self.appPropertiesController = [[AppPropertiesController alloc] init];
    self.appPropertiesController.app = app;
    
    NSWindow *window = [[SheetWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = appPropertiesController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = appPropertiesController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.appPropertiesController = nil;
    [sheet orderOut:self];
}

@end
