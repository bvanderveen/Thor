#import "ItemsController.h"
#import "TargetPropertiesController.h"
#import "ItemsView.h"
#import "TargetController.h"
#import "SheetWindow.h"

@interface ItemsController ()

@property (nonatomic, strong) NSViewController *itemPropertiesController;
@property (nonatomic, readonly) ItemsView *itemsView;

@end

@implementation ItemsController

@synthesize title, breadcrumbController, itemPropertiesController, items, arrayController, dataSource;

- (ItemsView *)itemsView {
    return (ItemsView *)self.view;
}

- (id)initWithTitle:(NSString *)leTitle {
    if (self = [super initWithNibName:@"ItemsView" bundle:[NSBundle mainBundle]]) {
        self.title = leTitle;
    }
    return self;
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (void)updateItems {
    NSError *error = nil;
    self.items = [[dataSource getItems:&error] mutableCopy];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateItems];
    self.itemsView.bar.barButton.title = @"New…";
    self.itemsView.bar.barButton.target = self;
    self.itemsView.bar.barButton.action = @selector(addItemClicked);
    self.itemsView.delegate = self;
    [self.arrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)insertObject:(Target *)t inTargetsAtIndex:(NSUInteger)index {
    [items insertObject:t atIndex:index];
}

- (void)pushSelectedItem {
    id item = [self.items objectAtIndex:arrayController.selectionIndex];
    
    NSViewController<BreadcrumbControllerAware> *itemController = [dataSource getControllerForItem:item];
    
    [self.breadcrumbController pushViewController:itemController animated:YES];
    NSMutableIndexSet *empty = [NSMutableIndexSet indexSet];
    [empty removeAllIndexes];
    arrayController.selectionIndexes = empty;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == arrayController) {
        if (arrayController.selectionIndexes.count)
            [self performSelector:@selector(pushSelectedItem) withObject:nil afterDelay:0];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)removeObjectFromTargetsAtIndex:(NSUInteger)index {
    [items removeObjectAtIndex:index];
}

- (void)addItemClicked {
    self.itemPropertiesController = [dataSource getPropertiesControllerForNewItem];
    
    
    NSWindow *window = [[SheetWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = self.itemPropertiesController.view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.contentView = itemPropertiesController.view;
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [self updateItems];
    self.itemPropertiesController = nil;
    [sheet orderOut:self];
}

@end
