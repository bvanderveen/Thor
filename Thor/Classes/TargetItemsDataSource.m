#import "TargetItemsDataSource.h"
#import "TargetController.h"
#import "CollectionItemView.h"
#import "Sequence.h"

static NSNib *nib = nil;

@implementation TargetItemsDataSource

+ (void)initialize {
    nib = [[NSNib alloc] initWithNibNamed:@"TargetCollectionItemView" bundle:nil];
}

- (NSArray *)itemsForItemsController:(ItemsController *)itemsController error:(NSError **)error {
    NSArray *result = [[ThorBackend shared] getConfiguredTargets:error];
    
    return result;
    
// many results!
//    return [[[[[[[NSArray array] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result];
}


- (NSCollectionViewItem *)itemsController:(ItemsController *)itemsController collectionViewItemForCollectionView:(NSCollectionView *)collectionView item:(id)item  {
    NSArray *topLevelObjects;
    [nib instantiateNibWithOwner:collectionView topLevelObjects:&topLevelObjects];
    
    NSView *view = [[topLevelObjects filter:^ BOOL (id o) { 
        return [o isKindOfClass:[NSView class]];
    }] objectAtIndex:0];
    
    CollectionItemViewButton *button = [[view.subviews filter:^ BOOL (id o) {
        return [o isKindOfClass:[CollectionItemViewButton class]];
    }] objectAtIndex:0];
    [button bind:@"label" toObject:item withKeyPath:@"displayName" options:nil];
    
    [button addCommand:[RACCommand commandWithCanExecute:nil execute:^ void (id v) {
        assert([itemsController.arrayController setSelectedObjects:@[ item ]]);
    }]];
    
    return [[topLevelObjects filter:^ BOOL (id o) { 
        return [o isKindOfClass:[NSCollectionViewItem class]]; 
    }] objectAtIndex:0];
}

@end
