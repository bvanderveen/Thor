#import "ItemsController.h"
#import "ThorCore.h"

@interface ServiceInfoItemsDataSource : NSObject <ItemsControllerDataSource>

- (id)initWithClient:(FoundryClient *)client;

@end
