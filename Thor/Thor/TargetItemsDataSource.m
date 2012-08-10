#import "TargetItemsDataSource.h"
#import "TargetPropertiesController.h"
#import "TargetController.h"
#import "CollectionItemView.h"

static NSNib *nib = nil;

@implementation TargetItemsDataSource

+ (void)initialize {
    nib = [[NSNib alloc] initWithNibNamed:@"TargetCollectionItemView" bundle:nil];
}

- (NSArray *)getItems:(NSError **)error {
    NSArray *result = [[ThorBackend shared] getConfiguredTargets:error];
    
    return result;
    
// many results!
//    return [[[[[[[NSArray array] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result];
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


- (NSCollectionViewItem *)itemsController:(ItemsController *)itemsController getCollectionViewItemForItem:(id)item collectionView:(NSCollectionView *)collectionView  {
    NSArray *topLevelObjects;
    [nib instantiateNibWithOwner:collectionView topLevelObjects:&topLevelObjects];
    
    NSView *view = [[topLevelObjects filter:^ BOOL (id o) { 
        return [o isKindOfClass:[NSView class]];
    }] objectAtIndex:0];
    
    CollectionItemViewButton *button = [view.subviews objectAtIndex:0];
    button.label = ((App *)item).displayName;
    
    [button addCommand:[RACCommand commandWithCanExecute:nil execute:^ void (id v) {
        [itemsController.breadcrumbController pushViewController:[self getControllerForItem:item] animated:YES];
    }]];
    
    return [[topLevelObjects filter:^ BOOL (id o) { 
        return [o isKindOfClass:[NSCollectionViewItem class]]; 
    }] objectAtIndex:0];
}
@end
