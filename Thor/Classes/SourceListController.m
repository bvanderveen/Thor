#import "SourceListController.h"
#import "ThorCore.h"
#import "Sequence.h"
#import "NSAlert+Dialogs.h"
#import "TargetPropertiesController.h"
#import "AppDelegate.h"

@interface SourceListToolbarButtonCell : NSButtonCell

@end

@implementation SourceListToolbarButtonCell

- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView { 
    NSImage *backgroundImage = [NSImage imageNamed:image == ((NSButton *)controlView).alternateImage ? @"SourceListButtonBackgroundHighlighted.png" : @"SourceListButtonBackground.png"];
    assert(image);
    
    [NSGraphicsContext saveGraphicsState];
    NSAffineTransform *t = [NSAffineTransform transform];
    [t scaleXBy:1 yBy:-1];
    [t translateXBy:0 yBy:-controlView.bounds.size.height - 1];
    [t concat];
    
    [backgroundImage drawInRect:controlView.bounds fromRect:(NSRect){ .origin = NSZeroPoint, .size = backgroundImage.size } operation:NSCompositeSourceOver fraction:1];

    [[NSColor grayColor] set];
    NSRectFill(NSMakeRect(controlView.bounds.size.width - 1, 0, 1, controlView.bounds.size.height));
    
    NSSize imageSize = image.size;
    [image drawInRect:frame fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1];
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView*)controlView {

}

@end

@interface SourceListToolbarButton : NSButton

@end

@implementation SourceListToolbarButton

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.cell = [[SourceListToolbarButtonCell alloc] init];
    }
    return self;
}

@end

@implementation SourceListToolbar

@synthesize addButton, removeButton;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.addButton = [[SourceListToolbarButton alloc] initWithFrame:NSZeroRect];
        self.addButton.buttonType = NSMomentaryChangeButton;
        self.addButton.target = self;
        self.addButton.action = @selector(showMenu);
        self.addButton.image = [NSImage imageNamed:@"SourceListButtonPlus.png"];
        self.addButton.alternateImage = [NSImage imageNamed:@"SourceListButtonPlusHighlighted.png"];
        [self addSubview:addButton];
        
        self.removeButton = [[SourceListToolbarButton alloc] initWithFrame:NSZeroRect];
        self.removeButton.buttonType = NSMomentaryChangeButton;
        self.removeButton.image = [NSImage imageNamed:@"SourceListButtonMinus.png"];
        self.removeButton.alternateImage = [NSImage imageNamed:@"SourceListButtonMinusHighlighted.png"];
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
    
    NSArray *popover = [[[self superview] subviews].rac_sequence filter:^BOOL(id value) {
        return [value isKindOfClass:[PopoverView class]];
    }].array;
    
    if (popover.count)
        [[popover[0] animator] setAlphaValue:0];
    [self performSelector:@selector(actuallyShowMenu:) withObject:menu afterDelay:0];
}

- (void)actuallyShowMenu:(NSMenu *)menu {
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
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"SourceListBarBackground.png"]] set];
    NSRectFill(dirtyRect);
}

@end

@implementation SourceListControllerView

@synthesize sourceList, contentView, toolbar, popover;

- (void)awakeFromNib {
    self.needsLayout = YES;
    [self layoutSubtreeIfNeeded];
}

- (void)layout {
    NSSize toolbarSize = [self.toolbar intrinsicContentSize];
    
    NSSize popoverSize = [self.popover intrinsicContentSize];
    
    self.sourceList.frame = NSMakeRect(0, 0, 200, self.bounds.size.height - toolbarSize.height);
    
    self.toolbar.frame = NSMakeRect(0, 0, self.sourceList.frame.size.width, toolbarSize.height);
    
    self.contentView.frame = NSMakeRect(self.sourceList.frame.size.width + 1, 0, self.bounds.size.width - sourceList.frame.size.width - 1, self.bounds.size.height);
    
    if (self.contentView.subviews.count)
        ((NSView *)self.contentView.subviews[0]).frame = self.contentView.bounds;
    
    self.popover.frame = NSMakeRect(2, self.toolbar.frame.size.height + 2, popoverSize.width, popoverSize.height);
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
        item.icon = [NSImage imageNamed:@"CloudIconSmall.png"];
        return item;
    }];
    
    appItem.title = @"LOCAL APPS";
    appItem.identifier = SECTION_IDENTIFIER;
    appItem.children = [apps map:^id(id a) {
        App *app = (App *)a;
        SourceListItem *item = [SourceListItem new];
        item.representedObject = app;
        item.title = app.displayName;
        item.identifier = @"row";
        item.icon = [NSImage imageNamed:@"AppIconSmall.png"];
        return item;
    }];
    
    self.sourceListItems = @[cloudItem, appItem];
    [self.controllerView.sourceList reloadData];
}

- (void)awakeFromNib {
    self.controllerView.toolbar.removeButton.target = self;
    self.controllerView.toolbar.removeButton.action = @selector(remove);
    [self updateAppsAndTargets];
    
    if ([PopoverView hasShownOnce]) {
        [self.controllerView.popover removeFromSuperview];
        self.controllerView.popover = nil;
    }
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
        [AppDelegate shared].selectedTarget = selectedModel;
    }
    else {
        selectedModel = self.apps[selectedIndex - 2 - self.targets.count];
        [AppDelegate shared].selectedTarget = nil;
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

    // XXX there is a bug here because the selection changes but the
    // active view does not.
    [[AppDelegate shared] setSelectedTarget:target];
    [[AppDelegate shared] editTarget:nil];
}

@end

@implementation SourceListContentView

- (void)drawRect:(NSRect)dirtyRect {
    NSImage *image = [NSImage imageNamed:@"ContentBackground.png"];
    
    [image drawInRect:CGRectMake((self.bounds.size.width - image.size.width) / 2, (self.bounds.size.height - image.size.height) / 2, image.size.width, image.size.height) fromRect:NSMakeRect(0, 0, image.size.width, image.size.height) operation:NSCompositeSourceOver fraction:.8];
}

@end

@implementation PopoverView

+ (BOOL)hasShownOnce {
    BOOL result = [[NSUserDefaults standardUserDefaults] boolForKey:@"HasShownPopover"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasShownPopover"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return result;
}

#define POPOVER_LABEL @"Add an app or cloud."
#define POPOVER_LABEL_ATTRIBUTES (@{ NSFontAttributeName: [NSFont boldSystemFontOfSize:12], NSForegroundColorAttributeName: [NSColor whiteColor] })

- (CGSize)intrinsicContentSize {
    NSImage *left = [NSImage imageNamed:@"PopoverLeft.png"];
    CGSize size = [POPOVER_LABEL sizeWithAttributes:POPOVER_LABEL_ATTRIBUTES];
    return CGSizeMake(size.width + 18, left.size.height);
}

- (void)drawRect:(NSRect)dirtyRect {
    NSImage *left = [NSImage imageNamed:@"PopoverLeft.png"];
    NSImage *right = [NSImage imageNamed:@"PopoverRight.png"];
    NSImage *middle = [NSImage imageNamed:@"PopoverMiddle.png"];
    
    [left drawInRect:NSMakeRect(0, 0, left.size.width, left.size.height) fromRect:NSMakeRect(0, 0, left.size.width, left.size.height) operation:NSCompositeSourceOver fraction:1];
    
    [middle drawInRect:NSMakeRect(left.size.width, left.size.height - middle.size.height, self.bounds.size.width - left.size.width - right.size.width, middle.size.height) fromRect:NSMakeRect(0, 0, middle.size.width, middle.size.height) operation:NSCompositeSourceOver fraction:1];
    
    [right drawInRect:NSMakeRect(self.bounds.size.width - right.size.width, left.size.height - middle.size.height, right.size.width, right.size.height) fromRect:NSMakeRect(0, 0, right.size.width, right.size.height) operation:NSCompositeSourceOver fraction:1];
    
    [POPOVER_LABEL drawAtPoint:NSMakePoint(8, 16) withAttributes:POPOVER_LABEL_ATTRIBUTES];
}

@end