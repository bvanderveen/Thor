#import "TargetItemsDataSource.h"
#import "TargetPropertiesController.h"
#import "TargetController.h"

@implementation TargetItemsDataSource

- (NSArray *)getItems:(NSError **)error {
    return [[ThorBackend shared] getConfiguredTargets:error];
}

- (NSViewController *)getPropertiesControllerForNewItem {
    TargetPropertiesController *targetPropertiesController = [[TargetPropertiesController alloc] init];
    targetPropertiesController.target = [Target targetInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    return targetPropertiesController;
}

- (NSViewController *)getControllerForItem:(id)item {
    TargetController *targetController = [[TargetController alloc] init];
    targetController.target = (Target *)item;
    return targetController;
}

@end
