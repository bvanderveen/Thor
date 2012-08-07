#import "AppItemsDataSource.h"
#import "AppPropertiesController.h"
#import "AppController.h"

@implementation AppItemsDataSource

- (NSArray *)getItems:(NSError **)error {
    return [[ThorBackend shared] getConfiguredApps:error];
}

- (NSViewController *)getPropertiesControllerForNewItem {
    AppPropertiesController *appPropertiesController = [[AppPropertiesController alloc] init];
    appPropertiesController.app = [App appInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    return appPropertiesController;
}

- (NSViewController<BreadcrumbControllerAware> *)getControllerForItem:(id)item {
    AppController *appController = [[AppController alloc] init];
    appController.app = (App *)item;
    return appController;
}

@end
