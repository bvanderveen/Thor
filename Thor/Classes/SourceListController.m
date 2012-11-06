#import "SourceListController.h"
#import "ThorCore.h"
#import "Sequence.h"

@implementation SourceListControllerView

@synthesize sourceList, contentView;

- (void)layout {
    self.contentView.frame = NSMakeRect(sourceList.frame.size.width, 0, self.bounds.size.width - sourceList.frame.size.width, self.bounds.size.height);
    ((NSView *)self.contentView.subviews[0]).frame = self.contentView.bounds;
    [super layout];
}

@end

@interface SourceListItem : NSObject

@property (nonatomic, copy) NSString *title, *identifier;
@property (nonatomic, strong) NSImage *icon;
@property (nonatomic, copy) NSArray *children;

@end

#define SECTION_IDENTIFIER @"section"

@implementation SourceListItem

@synthesize title, identifier, icon, children;

@end

@interface SourceListController ()

@property (nonatomic, readonly) SourceListControllerView *controllerView;
@property (nonatomic, copy) NSArray *sourceListItems, *targets, *apps;
@property (nonatomic, strong) NSViewController *currentController;

@end


@implementation SourceListController

@synthesize sourceListItems, targets, apps, controllerForModel, currentController = _currentController;

- (SourceListControllerView *)controllerView {
    return (SourceListControllerView *)self.view;
}

- (void)setCurrentController:(NSViewController *)currentController {
    _currentController = currentController;
    [self.controllerView.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.controllerView.contentView addSubview:currentController.view];
    self.controllerView.needsLayout = YES;
}

- (id)init {
    if (self = [super initWithNibName:@"SourceListView" bundle:[NSBundle mainBundle]]) {
        
    }
    return self;
}

- (void)awakeFromNib {
    NSError *error;
    self.targets = [[ThorBackend shared] getConfiguredTargets:&error];
    self.apps = [[ThorBackend shared] getConfiguredApps:&error];
    
    SourceListItem
        *cloudItem = [SourceListItem new],
        *appItem = [SourceListItem new];
    
    cloudItem.title = @"CLOUDS";
    cloudItem.identifier = SECTION_IDENTIFIER;
    cloudItem.children = [targets map:^id(id t) {
        Target *target = (Target *)t;
        SourceListItem *item = [SourceListItem new];
        item.title = target.displayName;
        item.identifier = @"row";
        item.icon = [NSImage imageNamed:@"audiobooks.png"];
        return item;
    }];
    
    appItem.title = @"APPS";
    appItem.identifier = SECTION_IDENTIFIER;
    appItem.children = [apps map:^id(id a) {
        App *app = (App *)a;
        SourceListItem *item = [SourceListItem new];
        item.title = app.displayName;
        item.identifier = @"row";
        item.icon = [NSImage imageNamed:@"audiobooks.png"];
        return item;
    }];
    
    self.sourceListItems = @[cloudItem, appItem];
    [self.controllerView.sourceList reloadData];
}

- (NSUInteger)sourceList:(PXSourceList *)sourceList numberOfChildrenOfItem:(id)item {
    return item ? ((SourceListItem *)item).children.count : sourceListItems.count;
}

- (id)sourceList:(PXSourceList *)aSourceList child:(NSUInteger)index ofItem:(id)item {
    return item ? [((SourceListItem *)item).children objectAtIndex:index] : [sourceListItems objectAtIndex:index];
}

- (id)sourceList:(PXSourceList *)aSourceList objectValueForItem:(id)item {
    return ((SourceListItem *)item).title;
}

- (BOOL)sourceList:(PXSourceList *)aSourceList isItemExpandable:(id)item {
    return ((SourceListItem *)item).children.count > 0;
}

- (BOOL)sourceList:(PXSourceList *)aSourceList isGroupAlwaysExpanded:(id)group {
    return [((SourceListItem *)group).identifier isEqual:SECTION_IDENTIFIER];
}

- (BOOL)sourceList:(PXSourceList*)aSourceList itemHasIcon:(id)item
{
	return ((SourceListItem *)item).icon != nil;
}

- (NSImage*)sourceList:(PXSourceList*)aSourceList iconForItem:(id)item
{
	return ((SourceListItem *)item).icon;
}

- (void)sourceListSelectionDidChange:(NSNotification *)notification
{
	NSIndexSet *selectedIndexes = self.controllerView.sourceList.selectedRowIndexes;
    
    NSUInteger selectedIndex = [selectedIndexes firstIndex];
    while (YES) {
        NSUInteger nextIndex = [selectedIndexes indexGreaterThanIndex:selectedIndex];
        if (nextIndex == NSNotFound)
            break;
        selectedIndex = nextIndex;
    }
    
    id selectedModel = nil;
    
    if (selectedIndex < self.targets.count + 1) {
        selectedModel = self.targets[selectedIndex - 1];
    }
    else {
        selectedModel = self.apps[selectedIndex - 3];
    }
    
    self.currentController = self.controllerForModel(selectedModel);
}

- (void)sourceListDeleteKeyPressedOnRows:(NSNotification *)notification
{
	NSIndexSet *rows = [[notification userInfo] objectForKey:@"rows"];
	
	NSLog(@"Delete key pressed on rows %@", rows);
	
	//Do something here
}

@end
