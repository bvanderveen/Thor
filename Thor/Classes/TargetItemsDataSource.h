#import "ItemsController.h"

@interface TargetItemsDataSource : NSObject <ItemsControllerDataSource>

- (id)initWithSelectionAction:(void(^)(id item, ItemsController *itemsController))action;

@end
