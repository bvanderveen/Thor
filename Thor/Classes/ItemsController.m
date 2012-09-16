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
    self.items = [[dataSource itemsForItemsController:self error:&error] mutableCopy];
}

- (NSCollectionViewItem *)collectionView:(CollectionView *)collectionView newItemForRepresentedObject:(id)object {
    return [dataSource itemsController:self collectionViewItemForCollectionView:collectionView item:object];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.itemsView.collectionView.dataSource = self;
    
    self.itemsView.bar.barButton.title = @"New…";
    self.itemsView.bar.barButton.target = self;
    self.itemsView.bar.barButton.action = @selector(addItemClicked);
//    [self.arrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewWillAppear {
    [self updateItems];
}

- (void)insertObject:(Target *)t inTargetsAtIndex:(NSUInteger)index {
    [items insertObject:t atIndex:index];
}

- (void)clearSelection {
    arrayController.selectionIndexes = [NSIndexSet indexSet];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == arrayController) {
        if (arrayController.selectionIndexes.count)
            [self performSelector:@selector(clearSelection) withObject:nil afterDelay:0];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)removeObjectFromTargetsAtIndex:(NSUInteger)index {
    [items removeObjectAtIndex:index];
}

- (void)addItemClicked {
    self.itemPropertiesController = [dataSource newItemPropertiesControllerForItemsController:self];
    
    NSWindow *window = [SheetWindow sheetWindowWithView:itemPropertiesController.view];
    
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [self updateItems];
    self.itemPropertiesController = nil;
    [sheet orderOut:self];
}

@end
