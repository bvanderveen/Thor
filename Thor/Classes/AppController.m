#import "AppController.h"
#import "AppPropertiesController.h"
#import "SheetWindow.h"

@interface AppController ()

@property (nonatomic, strong) AppPropertiesController *appPropertiesController;

@end

@implementation AppController

@synthesize app, appPropertiesController, breadcrumbController, title;

- (id)init {
    if (self = [super initWithNibName:@"AppView" bundle:[NSBundle mainBundle]]) {
        //if (self = [super initWithNibName:nil bundle:nil]) {
        self.title = @"App";
    }
    return self;
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
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
