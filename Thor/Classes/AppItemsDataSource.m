#import "AppItemsDataSource.h"
#import "AppPropertiesController.h"
#import "AppController.h"
#import "CollectionItemView.h"

static NSNib *nib = nil;

@implementation AppItemsDataSource

+ (void)initialize {
    nib = [[NSNib alloc] initWithNibNamed:@"AppCollectionItemView" bundle:nil];
}

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

- (NSCollectionViewItem *)itemsController:(ItemsController *)itemsController getCollectionViewItemForItem:(id)item collectionView:(NSCollectionView *)collectionView  {
    NSArray *topLevelObjects;
    [nib instantiateNibWithOwner:collectionView topLevelObjects:&topLevelObjects];
    
    NSView *view = [[topLevelObjects filter:^ BOOL (id o) { 
        return [o isKindOfClass:[NSView class]];
    }] objectAtIndex:0];
    
    CollectionItemViewButton *button = [view.subviews objectAtIndex:0];
    [button bind:@"label" toObject:item withKeyPath:@"displayName" options:nil];
    
    [button addCommand:[RACCommand commandWithCanExecute:nil execute:^ void (id v) {
        [itemsController.breadcrumbController pushViewController:[self getControllerForItem:item] animated:YES];
    }]];
        
    return [[topLevelObjects filter:^ BOOL (id o) { 
        return [o isKindOfClass:[NSCollectionViewItem class]]; 
    }] objectAtIndex:0];
}

@end
