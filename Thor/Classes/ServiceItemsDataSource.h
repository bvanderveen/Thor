#import "ItemsController.h"
#import "ThorCore.h"

@interface ServiceItemsDataSource : NSObject <ItemsControllerDataSource>

- (id)initWithServices:(NSArray *)services;

@end
