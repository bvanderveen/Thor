#import "ItemsController.h"

@interface AppItemsDataSource : NSObject <ItemsControllerDataSource>

- (id)initWithSelectionAction:(void (^)(ItemsController *, id))action;

@end
