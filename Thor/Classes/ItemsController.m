#import "ItemsController.h"
#import "TargetPropertiesController.h"
#import "ItemsView.h"
#import "TargetController.h"
#import "SheetWindow.h"
#import "NSObject+AssociateDisposable.h"

@interface ItemsController ()

@property (nonatomic, readonly) ItemsView *itemsView;

@end

@implementation ItemsController

@synthesize items, arrayController, dataSource;

- (ItemsView *)itemsView {
    return (ItemsView *)self.view;
}

- (id)init {
    if (self = [super initWithNibName:@"ItemsView" bundle:[NSBundle mainBundle]]) {
    }
    return self;
}

- (void)updateItems {
    NSError *error = nil;
    self.associatedDisposable = [[dataSource itemsForItemsController:self error:&error] subscribeNext:^ (id x) {
        self.items = [x mutableCopy];
    } error:^(NSError *error) {
        [NSApp presentError:error];
    }];
}

- (NSCollectionViewItem *)collectionView:(CollectionView *)collectionView newItemForRepresentedObject:(id)object {
    return [dataSource itemsController:self collectionViewItemForCollectionView:collectionView item:object];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.itemsView.collectionView.dataSource = self;
    
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

@end

@interface BreadcrumbItemsControllerView : NSView

@property (nonatomic, strong) BottomBar *bottomBar;
@property (nonatomic, strong) NSView *contentView;

@end

@implementation BreadcrumbItemsControllerView

@synthesize bottomBar, contentView;

- (id)initWithContentView:(NSView *)lContentView {
    if (self = [super initWithFrame:CGRectZero]) {
        self.bottomBar = [[BottomBar alloc] initWithFrame:CGRectZero];
        [self addSubview:bottomBar];
        
        self.contentView = lContentView;
        [self addSubview:contentView];
    }
    return self;
}

- (void)layout {
    NSSize bottomBarSize = [bottomBar intrinsicContentSize];
    bottomBar.frame = NSMakeRect(0, 0, self.bounds.size.width, bottomBarSize.height);
    
    contentView.frame = NSMakeRect(0, bottomBarSize.height, self.bounds.size.width, self.bounds.size.height - bottomBarSize.height);
    
    [super layout];
}

@end

@interface BreadcrumbItemsController ()

@property (nonatomic, strong) NSViewController *itemPropertiesController;
@property (nonatomic, copy) NSViewController *(^newItem)();
@property (nonatomic, copy) void (^selection)(BreadcrumbItemsController *, id);
@property (nonatomic, assign) NSArrayController *arrayController;

@end

@implementation BreadcrumbItemsController

@synthesize arrayController = _arrayController, itemPropertiesController, newItem, selection, itemsController, breadcrumbController, title;

- (void)setArrayController:(NSArrayController *)value {
    [_arrayController removeObserver:self forKeyPath:@"selection"];
    _arrayController = value;
    [_arrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (id)initWithItemsController:(ItemsController *)lItemsController newItemBlock:(NSViewController *(^)(BreadcrumbItemsController *))newItemBlock selectionBlock:(void (^)(BreadcrumbItemsController *, id))selectionBlock {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.itemsController = lItemsController;
        self.newItem = newItemBlock;
        self.selection = selectionBlock;
    }
    return self;
}

- (void)dealloc {
    self.arrayController = nil;
}

- (void)loadView {
    BreadcrumbItemsControllerView *breadcrumbItemsControllerView = [[BreadcrumbItemsControllerView alloc] initWithContentView:itemsController.view];
    
    self.arrayController = itemsController.arrayController;
    
    breadcrumbItemsControllerView.bottomBar.barButton.title = @"New…";
    breadcrumbItemsControllerView.bottomBar.barButton.target = self;
    breadcrumbItemsControllerView.bottomBar.barButton.action = @selector(addItemClicked);
    
    self.view = breadcrumbItemsControllerView;
}

- (void)viewWillAppear {
    [itemsController viewWillAppear];
}

- (void)addItemClicked {
    self.itemPropertiesController = newItem();
    
    if (itemPropertiesController) {
        NSWindow *window = [SheetWindow sheetWindowWithView:itemPropertiesController.view];
        
        [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [self.itemsController updateItems];
    self.itemPropertiesController = nil;
    [sheet orderOut:self];
}

- (void)deselectItems {
    itemsController.arrayController.selectedObjects = @[];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.arrayController && [keyPath isEqual:@"selection"]) {
        [self performSelector:@selector(deselectItems) withObject:nil afterDelay:0];
        
        if (itemsController.arrayController.selectedObjects.count)
            selection(self, itemsController.arrayController.selectedObjects[0]);
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

@interface WizardItemsController ()

@property (nonatomic, copy) void (^commit)();
@property (nonatomic, copy) void (^rollback)();
@property (nonatomic, strong) ItemsController *itemsController;
@property (nonatomic, strong) NSArrayController *arrayController;

@end

@implementation WizardItemsController

@synthesize title, commitButtonTitle, wizardController, commit, rollback, itemsController, arrayController = _arrayController;

- (void)setArrayController:(NSArrayController *)value {
    [_arrayController removeObserver:self forKeyPath:@"selection"];
    _arrayController = value;
    [_arrayController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionNew context:nil];
}

- (id)initWithItemsController:(ItemsController *)lItemsController commitBlock:(void (^)())commitBlock rollbackBlock:(void (^)())rollbackBlock {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.itemsController = lItemsController;
        self.commit = commitBlock;
        self.rollback = rollbackBlock;
    }
    return self;
}

- (void)dealloc {
    self.arrayController = nil;
}

- (void)loadView {
    self.view = itemsController.view;
    self.arrayController = itemsController.arrayController;
}

- (void)viewWillAppear {
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