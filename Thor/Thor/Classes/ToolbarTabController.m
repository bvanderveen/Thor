#import "ToolbarTabController.h"
#import "AppsController.h"
#import "CloudsController.h"
#import "BreadcrumbController.h"

NSString *ToolbarCloudsItemIdentifier = @"ToolbarCloudsItemIdentifier";
NSString *ToolbarAppsItemIdentifier = @"ToolbarAppsItemIdentifier";

@interface TabView : NSView

@end

@implementation TabView

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    }
    return self;
}

- (void)didAddSubview:(NSView *)subview {
    [self setNeedsLayout:YES];
}

- (void)layout {
    NSView *subview = [self.subviews objectAtIndex:0];
    subview.frame = self.bounds;
    [super layout];
}

@end

@interface ToolbarTabController ()

@property (nonatomic, strong) NSViewController *appsController, *cloudsController, *activeController;

@end

@implementation ToolbarTabController

@synthesize toolbar, appsController, cloudsController, activeController = _activeController;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.toolbar = [[NSToolbar alloc] initWithIdentifier:@"TabToolbar"];
        toolbar.delegate = self;
        toolbar.selectedItemIdentifier = ToolbarAppsItemIdentifier;
        
        self.appsController = [[BreadcrumbController alloc] initWithRootViewController:[[AppsController alloc] init]];
        self.cloudsController = [[BreadcrumbController alloc] initWithRootViewController:[[CloudsController alloc] init]];
    }
    return self;
}

- (void)loadView {
    self.view = [[TabView alloc] initWithFrame:CGRectZero];
    
    self.activeController = appsController;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    
    if ([itemIdentifier isEqual:ToolbarAppsItemIdentifier]) {
        NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        item.label = @"Apps";
        item.target = self;
        item.action = @selector(itemClicked:);
        return item;
    } 
    else if ([itemIdentifier isEqual:ToolbarCloudsItemIdentifier]) {
        NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        item.label = @"Clouds";
        item.target = self;
        item.action = @selector(itemClicked:);
        return item;
    }
    else if ([itemIdentifier isEqual:NSToolbarFlexibleSpaceItemIdentifier]) {
        return [[NSToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier];
    }
    return nil;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:ToolbarAppsItemIdentifier, ToolbarCloudsItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:ToolbarAppsItemIdentifier, ToolbarCloudsItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, nil];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:ToolbarAppsItemIdentifier, ToolbarCloudsItemIdentifier, nil];
}

- (void)itemClicked:(NSToolbarItem *)item {
    self.activeController = [item.itemIdentifier isEqual:ToolbarAppsItemIdentifier] ? appsController : cloudsController;
}

- (void)setActiveController:(NSViewController *)value {
    _activeController = value;
    if (self.view.subviews.count) 
        [[self.view.subviews objectAtIndex:0] removeFromSuperview];
    
    [self.view addSubview:value.view];
}

@end
