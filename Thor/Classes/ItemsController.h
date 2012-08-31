#import "BreadcrumbController.h"

@class ItemsController;

@protocol ItemsControllerDataSource <NSObject>

- (NSArray *)itemsForItemsController:(ItemsController *)itemsController error:(NSError **)error;
- (NSViewController *)newItemPropertiesControllerForItemsController:(ItemsController *)itemsController;
- (NSCollectionViewItem *)itemsController:(ItemsController *)itemsController collectionViewItemForCollectionView:(NSCollectionView *) collectionView item:(id)item;

@end

@interface ItemsController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem>

@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) IBOutlet NSMutableArray *items;

@property (nonatomic, strong) id<ItemsControllerDataSource> dataSource;

- (id)initWithTitle:(NSString *)leTitle;

@end
