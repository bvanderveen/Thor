#import "BreadcrumbController.h"

@protocol ItemsControllerDataSource <NSObject>

- (NSArray *)getItems:(NSError **)error;
- (NSViewController *)getPropertiesControllerForNewItem;
- (NSViewController<BreadcrumbControllerAware> *)getControllerForItem:(id)item;

@end

@interface ItemsController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem>

@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;
@property (nonatomic, strong) IBOutlet NSMutableArray *items;

@property (nonatomic, strong) id<ItemsControllerDataSource> dataSource;

- (id)initWithTitle:(NSString *)leTitle itemPrototype:(NSCollectionViewItem *(^)(NSCollectionView *))itemPrototype;

@end
