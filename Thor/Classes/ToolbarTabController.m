#import "ToolbarTabController.h"
#import "ItemsController.h"
#import "ServicesController.h"
#import "TargetItemsDataSource.h"
#import "AppItemsDataSource.h"
#import "BreadcrumbController.h"
#import "Sequence.h"
#import "TargetController.h"
#import "TargetPropertiesController.h"
#import "AppController.h"
#import "ViewVisibilityAware.h"

NSString *ToolbarTargetsItemIdentifier = @"ToolbarTargetsItemIdentifier";
NSString *ToolbarAppsItemIdentifier = @"ToolbarAppsItemIdentifier";
NSString *ToolbarServicesItemIdentifier = @"ToolbarServicesItemIdentifier";

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

@property (nonatomic, strong) NSViewController<ViewVisibilityAware> *appsController, *targetsController, *servicesController, *activeController;

@end

@implementation ToolbarTabController

@synthesize toolbar, appsController, targetsController, servicesController, activeController = _activeController;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.toolbar = [[NSToolbar alloc] initWithIdentifier:@"TabToolbar"];
        toolbar.delegate = self;
        toolbar.selectedItemIdentifier = ToolbarAppsItemIdentifier;
        
        ItemsController *targets = [[ItemsController alloc] init];
        targets.dataSource = [[TargetItemsDataSource alloc] init];
        
        BreadcrumbItemsController *targetsWrapper = [[BreadcrumbItemsController alloc] initWithItemsController:targets newItemBlock:^ NSViewController * (BreadcrumbItemsController *breadcrumbItemsController) {
            TargetPropertiesController *targetPropertiesController = [[TargetPropertiesController alloc] init];
            targetPropertiesController.target = [Target targetInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
            return targetPropertiesController;
        } selectionBlock:^ (BreadcrumbItemsController *breadcrumbItemsController, id item) {
            TargetController *targetController = [[TargetController alloc] init];
            targetController.target = (Target *)item;
            [breadcrumbItemsController.breadcrumbController pushViewController:targetController animated:YES];
        }];
        targetsWrapper.title = @"Clouds";
        
        ItemsController *apps = [[ItemsController alloc] init];
        apps.dataSource = [[AppItemsDataSource alloc] init];
        
        BreadcrumbItemsController *appsWrapper = [[BreadcrumbItemsController alloc] initWithItemsController:apps newItemBlock:^ NSViewController * (BreadcrumbItemsController *breadcrumbItemsController) {
            //[((id)[NSApplication sharedApplication].delegate) newApp:nil];
            return nil;
        } selectionBlock:^(BreadcrumbItemsController *breadcrumbItemsController, id item) {
            AppController *appController = [[AppController alloc] init];
            appController.app = (App *)item;
            [breadcrumbItemsController.breadcrumbController pushViewController:appController animated:YES];
        }];
        appsWrapper.title = @"Apps";
        
        self.appsController = [[BreadcrumbController alloc] initWithRootViewController:appsWrapper];
        self.targetsController = [[BreadcrumbController alloc] initWithRootViewController:targetsWrapper];
        
        self.servicesController = [[ServicesController alloc] init];
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
        item.image = [NSImage imageNamed:@"AppToolbarIcon"];
        item.target = self;
        item.action = @selector(itemClicked:);
        return item;
    } 
    else if ([itemIdentifier isEqual:ToolbarTargetsItemIdentifier]) {
        NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        item.label = @"Clouds";
        item.image = [NSImage imageNamed:@"CloudToolbarIcon"];
        item.target = self;
        item.action = @selector(itemClicked:);
        return item;
    }
    else if ([itemIdentifier isEqual:ToolbarServicesItemIdentifier]) {
        NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
        item.label = @"Services";
        item.image = [NSImage imageNamed:@"ServicesToolbarIcon"];
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
    return @[ToolbarAppsItemIdentifier, ToolbarTargetsItemIdentifier, ToolbarServicesItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)leToolbar {
    return [self toolbarDefaultItemIdentifiers:leToolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
    return @[ToolbarAppsItemIdentifier, ToolbarTargetsItemIdentifier, ToolbarServicesItemIdentifier];
}

- (void)itemClicked:(NSToolbarItem *)item {
    if ([item.itemIdentifier isEqual:ToolbarAppsItemIdentifier])
        self.activeController = appsController;
    else if ([item.itemIdentifier isEqual:ToolbarTargetsItemIdentifier])
        self.activeController = targetsController;
    else if ([item.itemIdentifier isEqual:ToolbarServicesItemIdentifier])
        self.activeController = servicesController;
}

- (void)setActiveController:(NSViewController<ViewVisibilityAware> *)value {
    _activeController = value;
    if (self.view.subviews.count) 
        [[self.view.subviews objectAtIndex:0] removeFromSuperview];
    
    if ([value respondsToSelector:@selector(viewWillAppear)])
        [value viewWillAppear];
    
    [self.view addSubview:value.view];
}

@end
