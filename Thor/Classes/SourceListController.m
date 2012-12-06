#import "SourceListController.h"
#import "ThorCore.h"
#import "Sequence.h"
#import "NSAlert+Dialogs.h"
#import "TargetPropertiesController.h"
#import "AppDelegate.h"

@implementation SourceListToolbar

@synthesize addButton, removeButton;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.addButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        self.addButton.title = @"+";
        self.addButton.target = self;
        self.addButton.action = @selector(showMenu);
        [self addSubview:addButton];
        
        self.removeButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        self.removeButton.title = @"-";
        [self addSubview:removeButton];
    }
    return self;
}

- (void)showMenu {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    
    NSMenuItem *newTarget = [[NSMenuItem alloc] initWithTitle:@"New Cloud…" action:@selector(newTarget:) keyEquivalent:@"n"];
    newTarget.keyEquivalentModifierMask = NSCommandKeyMask;
    newTarget.target = [NSApplication sharedApplication].delegate;
    [menu addItem:newTarget];
    
    NSMenuItem *newApp = [[NSMenuItem alloc] initWithTitle:@"New App…" action:@selector(newApp:) keyEquivalent:@"n"];
    newTarget.keyEquivalentModifierMask = NSCommandKeyMask | NSShiftKeyMask;
    newApp.target = [NSApplication sharedApplication].delegate;
    [menu addItem:newApp];
    
    [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(self.addButton.frame.size.width, 0) inView:self.addButton];
}

- (void)layout {
    self.addButton.frame = NSMakeRect(0, 0, 24, self.bounds.size.height);
    self.removeButton.frame = NSMakeRect(24, 0, 24, self.bounds.size.height);
    [super layout];
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 24);
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithDeviceWhite:.8 alpha:1] set];
    NSRectFill(dirtyRect);
}

@end

@implementation SourceListControllerView

@synthesize sourceList, contentView, toolbar;

- (void)awakeFromNib {
    self.needsLayout = YES;
    [self layoutSubtreeIfNeeded];
}

- (void)layout {
    NSSize toolbarSize = [self.toolbar intrinsicContentSize];
    
    self.sourceList.frame = NSMakeRect(0, 0, 200, self.bounds.size.height - toolbarSize.height);
    
    self.toolbar.frame = NSMakeRect(0, 0, self.sourceList.frame.size.width, toolbarSize.height);
    
    self.contentView.frame = NSMakeRect(self.sourceList.frame.size.width + 1, 0, self.bounds.size.width - sourceList.frame.size.width - 1, self.bounds.size.height);
    
    if (self.contentView.subviews.count)
        ((NSView *)self.contentView.subviews[0]).frame = self.contentView.bounds;
    
    [super layout];
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor colorWithDeviceWhite:.7 alpha:1] set];
    NSRectFill(NSMakeRect(sourceList.frame.size.width, 0, 1, self.bounds.size.height));
}

@end

@interface SourceListItem : NSObject

@property (nonatomic, copy) NSString *title, *identifier;
@property (nonatomic, strong) NSImage *icon;
@property (nonatomic, copy) NSArray *children;
@property (nonatomic, strong) id representedObject;

@end

#define SECTION_IDENTIFIER @"section"

@implementation SourceListItem

@synthesize title, identifier, icon, children, representedObject;

@end

@interface SourceListController ()

@property (nonatomic, readonly) SourceListControllerView *controllerView;
@property (nonatomic, copy) NSArray *sourceListItems, *targets, *apps;
@property (nonatomic, strong) NSViewController *currentController;

@end


@implementation SourceListController

@synthesize sourceListItems, targets, apps, controllerForModel, deleteModelConfirmation, currentController = _currentController;

- (SourceListControllerView *)controllerView {
    return (SourceListControllerView *)self.view;
}

- (void)setCurrentController:(NSViewController<ViewVisibilityAware> *)currentController {
    _currentController = currentController;
    [self.controllerView.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.controllerView.contentView addSubview:currentController.view];
    self.controllerView.needsLayout = YES;
    [self.controllerView layoutSubtreeIfNeeded];
    if ([currentController respondsToSelector:@selector(viewWillAppear)]) {
        [currentController viewWillAppear];
    }
}

- (id)init {
    if (self = [super initWithNibName:@"SourceListView" bundle:[NSBundle mainBundle]]) {
        
    }
    return self;
}

- (void)updateAppsAndTargets {
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
        item.representedObject = target;
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
        item.representedObject = app;
        item.title = app.displayName;
        item.identifier = @"row";
        item.icon = [NSImage imageNamed:@"audiobooks.png"];
        return item;
    }];
    
    self.sourceListItems = @[cloudItem, appItem];
    [self.controllerView.sourceList reloadData];
}

- (void)awakeFromNib {
    self.controllerView.toolbar.removeButton.target = self;
    self.controllerView.toolbar.removeButton.action = @selector(remove);
    [self updateAppsAndTargets];
}

- (void)remove {
    SourceListItem *selectedItem = (SourceListItem *)[self.controllerView.sourceList itemAtRow:[self.controllerView.sourceList selectedRow]];
    
    [self presentDeletionDialogForModel:selectedItem.representedObject];
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

- (void)sourceList:(PXSourceList*)aSourceList setObjectValue:(id)object forItem:(id)item {
    ((SourceListItem *)item).title = object;
    [((SourceListItem *)item).representedObject setDisplayName:object];
    
    NSError *error;
    if (![[ThorBackend sharedContext] save:&error])
        [NSApp presentError:error];
}

- (BOOL)sourceList:(PXSourceList *)aSourceList isItemExpandable:(id)item {
    return ((SourceListItem *)item).children.count > 0;
}

- (BOOL)sourceList:(PXSourceList *)aSourceList isGroupAlwaysExpanded:(id)group {
    return [((SourceListItem *)group).identifier isEqual:SECTION_IDENTIFIER];
}

- (BOOL)sourceList:(PXSourceList*)aSourceList itemHasIcon:(id)item {
	return ((SourceListItem *)item).icon != nil;
}

- (NSImage*)sourceList:(PXSourceList*)aSourceList iconForItem:(id)item {
	return ((SourceListItem *)item).icon;
}

- (id)modelForIndexSet:(NSIndexSet *)indexSet {
    NSUInteger selectedIndex = [indexSet firstIndex];
    
    if (selectedIndex == NSNotFound)
        return nil;
    
    while (YES) {
        NSUInteger nextIndex = [indexSet indexGreaterThanIndex:selectedIndex];
        if (nextIndex == NSNotFound)
            break;
        selectedIndex = nextIndex;
    }
    
    id selectedModel = nil;
    
    if (selectedIndex < self.targets.count + 1) {
        selectedModel = self.targets[selectedIndex - 1];
        ((AppDelegate *)[NSApplication sharedApplication].delegate).selectedTarget = selectedModel;
    }
    else {
        selectedModel = self.apps[selectedIndex - 2 - self.targets.count];
        ((AppDelegate *)[NSApplication sharedApplication].delegate).selectedTarget = nil;
    }
    
    return selectedModel;
}

- (void)sourceListSelectionDidChange:(NSNotification *)notification {
	id selectedModel = [self modelForIndexSet:self.controllerView.sourceList.selectedRowIndexes];
    self.currentController = self.controllerForModel(selectedModel);
}

- (void)sourceListDeleteKeyPressedOnRows:(NSNotification *)notification {
	NSIndexSet *rows = [[notification userInfo] objectForKey:@"rows"];
    id selectedModel = [self modelForIndexSet:rows];
    [self presentDeletionDialogForModel:selectedModel];
}

- (void)presentDeletionDialogForModel:(id)model {
    NSAlert *alert = self.deleteModelConfirmation(model);
    
    [alert presentSheetModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSAlertDefaultReturn) {
            [[ThorBackend sharedContext] deleteObject:model];
            NSError *error;
            
            if (![[ThorBackend sharedContext] save:&error]) {
                [NSApp presentError:error];
                return;
            }
            
            [self updateAppsAndTargets];
        }
    }];
}

- (NSMenu *)sourceList:(PXSourceList *)sourceList menuForEvent:(NSEvent*)theEvent item:(id)item {
    id representedObject = ((SourceListItem *)item).representedObject;
    
    if ([representedObject isKindOfClass:[App class]]) {
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        
        NSMenuItem *reveal = [[NSMenuItem alloc] initWithTitle:@"Reveal in Finder" action:@selector(reveal:) keyEquivalent:@""];
        reveal.target = self;
        reveal.representedObject = item;
        [menu addItem:reveal];
        
        return menu;
    } else if ([representedObject isKindOfClass:[Target class]]) {
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        
        NSMenuItem *reveal = [[NSMenuItem alloc] initWithTitle:@"Settings…" action:@selector(settings:) keyEquivalent:@"i"];
        reveal.keyEquivalentModifierMask = NSCommandKeyMask;
        reveal.target = self;
        reveal.representedObject = item;
        [menu addItem:reveal];
        
        return menu;
    }
    return nil;
}

- (void)reveal:(NSMenuItem *)menuItem {
    SourceListItem *sourceListItem = (SourceListItem *)menuItem.representedObject;
    App *app = (App *)sourceListItem.representedObject;
    
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:app.localRoot]]];
}

- (void)settings:(NSMenuItem *)menuItem {
    SourceListItem *sourceListItem = (SourceListItem *)menuItem.representedObject;
    Target *target = (Target *)sourceListItem.representedObject;

    [(AppDelegate *)([NSApplication sharedApplication].delegate) setSelectedTarget:target];
    [(AppDelegate *)([NSApplication sharedApplication].delegate) editTarget:nil];
}

@end
