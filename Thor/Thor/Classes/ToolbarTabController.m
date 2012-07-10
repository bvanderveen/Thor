#import "ToolbarTabController.h"
#import "AppsController.h"
#import "CloudsController.h"

NSString *ToolbarCloudsItemIdentifier = @"ToolbarCloudsItemIdentifier";
NSString *ToolbarAppsItemIdentifier = @"ToolbarAppsItemIdentifier";

@interface ToolbarTabController ()

@property (nonatomic, strong) NSView *view;
@property (nonatomic, strong) NSViewController *appsController, *cloudsController, *activeController;

@end

@implementation ToolbarTabController

@synthesize toolbar, view, appsController, cloudsController, activeController = _activeController;

- (id)init {
    if (self = [super init]) {
        self.toolbar = [[NSToolbar alloc] initWithIdentifier:@"TabToolbar"];
        toolbar.selectedItemIdentifier = ToolbarAppsItemIdentifier;
        toolbar.delegate = self;
        self.view = [[NSView alloc] initWithFrame:CGRectZero];
        self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        self.appsController = [[AppsController alloc] init];
        self.cloudsController = [[CloudsController alloc] init];
        self.activeController = appsController;
    }
    return self;
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
    if (view.subviews.count) [[view.subviews objectAtIndex:0] removeFromSuperview];
    value.view.frame = view.bounds;
    [view addSubview:value.view];
}

@end
