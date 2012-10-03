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
}

- (void)viewWillAppear {
    [self updateItems];
}

- (void)insertObject:(Target *)t inTargetsAtIndex:(NSUInteger)index {
    [items insertObject:t atIndex:index];
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

- (void)commitWizardPanel {
    
}

@end


@interface WizardItemsController ()

@property (nonatomic, copy) void (^commit)();
@property (nonatomic, copy) void (^rollback)();
@property (nonatomic, strong) ItemsController *itemsController;

@end

@implementation WizardItemsController

@synthesize title, wizardController, commit, rollback, itemsController;

- (id)initWithItemsController:(ItemsController *)lItemsController commitBlock:(void (^)())commitBlock rollbackBlock:(void (^)())rollbackBlock {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.itemsController = lItemsController;
        self.commit = commitBlock;
        self.rollback = rollbackBlock;
    }
    return self;
}

- (void)loadView {
    self.view = itemsController.view;
}

- (void)viewWillAppear {
    [itemsController.arrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
    [itemsController viewWillAppear];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == itemsController.arrayController && [keyPath isEqual:@"selection"]) {
        self.wizardController.commitButtonEnabled = itemsController.arrayController.selectionIndexes.count > 0;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)commitWizardPanel {
    if (commit)
        commit();
}

- (void)rollbackWizardPanel {
    if (rollback)
        rollback();
}

@end