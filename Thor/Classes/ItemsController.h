#import "BreadcrumbController.h"
#import "WizardController.h"

@class ItemsController;

@protocol ItemsControllerDataSource <NSObject>

- (NSArray *)itemsForItemsController:(ItemsController *)itemsController error:(NSError **)error;
- (NSCollectionViewItem *)itemsController:(ItemsController *)itemsController collectionViewItemForCollectionView:(NSCollectionView *) collectionView item:(id)item;

@end

@interface ItemsController : NSViewController

@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) IBOutlet NSMutableArray *items;

@property (nonatomic, strong) id<ItemsControllerDataSource> dataSource;

- (void)updateItems;

@end

@interface WizardItemsController : NSViewController <WizardControllerAware>

- (id)initWithItemsController:(ItemsController *)itemsController commitBlock:(void (^)())commit rollbackBlock:(void (^)())rollback;

@end

@interface BreadcrumbItemsController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem>

@property (nonatomic, strong) ItemsController *itemsController;

- (id)initWithItemsController:(ItemsController *)itemsController newItemBlock:(NSViewController * (^)(BreadcrumbItemsController *))newItemBlock selectionBlock:(void (^)(BreadcrumbItemsController *, id))selectionBlock;

@end
