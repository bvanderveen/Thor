#import "ItemsController.h"
#import "ThorCore.h"

@interface ServiceItemsDataSource : NSObject <ItemsControllerDataSource>

- (id)initWithClient:(FoundryClient *)client;

@end
