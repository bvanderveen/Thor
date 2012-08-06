#import "AppItemsDataSource.h"
//#import "AppPropertiesController.h"

@implementation AppItemsDataSource

- (NSArray *)getItems:(NSError **)error {
    return [[ThorBackend shared] getConfiguredApps:error];
}

- (NSViewController *)getPropertiesControllerForNewItem {
    return nil;
//    
//    AppPropertiesController *appPropertiesController = [[AppPropertiesController alloc] init];
//    appPropertiesController.app = [App targetInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
//    return appPropertiesController;
}

- (NSViewController<BreadcrumbControllerAware> *)getControllerForItem:(id)item {
    return nil;
}

@end
