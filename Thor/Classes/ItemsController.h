#import "BreadcrumbController.h"

@class ItemsController;

@protocol ItemsControllerDataSource <NSObject>

- (NSArray *)getItems:(NSError **)error;
- (NSViewController *)getPropertiesControllerForNewItem;
- (NSCollectionViewItem *)itemsController:(ItemsController *)itemsController getCollectionViewItemForItem:(id)item collectionView:(NSCollectionView *)collectionView;
- (NSViewController<BreadcrumbControllerAware> *)getControllerForItem:(id)item;

@end

@interface ItemsController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem>

@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) IBOutlet NSMutableArray *items;

@property (nonatomic, strong) id<ItemsControllerDataSource> dataSource;

- (id)initWithTitle:(NSString *)leTitle;

@end
