#import "TargetItemsDataSource.h"
#import "TargetPropertiesController.h"
#import "TargetController.h"
#import "CollectionItemView.h"
#import "Sequence.h"

static NSNib *nib = nil;

@interface TargetItemsDataSource ()

@property (nonatomic, copy) void (^action)(ItemsController *, id);

@end

@implementation TargetItemsDataSource

@synthesize action;

+ (void)initialize {
    nib = [[NSNib alloc] initWithNibNamed:@"TargetCollectionItemView" bundle:nil];
}

- (id)initWithSelectionAction:(void (^)(id, ItemsController *))lAction {
    if (self = [super init]) {
        self.action = lAction;
    }
    return self;
}

- (NSArray *)itemsForItemsController:(ItemsController *)itemsController error:(NSError **)error {
    NSArray *result = [[ThorBackend shared] getConfiguredTargets:error];
    
    return result;
    
// many results!
//    return [[[[[[[NSArray array] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result] arrayByAddingObjectsFromArray:result];
}

- (NSViewController *)newItemPropertiesControllerForItemsController:(ItemsController *)itemsController {
    TargetPropertiesController *targetPropertiesController = [[TargetPropertiesController alloc] init];
    targetPropertiesController.target = [Target targetInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    return targetPropertiesController;
}

- (NSCollectionViewItem *)itemsController:(ItemsController *)itemsController collectionViewItemForCollectionView:(NSCollectionView *)collectionView item:(id)item  {
    NSArray *topLevelObjects;
    [nib instantiateNibWithOwner:collectionView topLevelObjects:&topLevelObjects];
    
    NSView *view = [[topLevelObjects filter:^ BOOL (id o) { 
        return [o isKindOfClass:[NSView class]];
    }] objectAtIndex:0];
    
    CollectionItemViewButton *button = [view.subviews objectAtIndex:0];
    [button bind:@"label" toObject:item withKeyPath:@"displayName" options:nil];
    
    [button addCommand:[RACCommand commandWithCanExecute:nil execute:^ void (id v) {
        action(itemsController, item);
    }]];
    
    return [[topLevelObjects filter:^ BOOL (id o) { 
        return [o isKindOfClass:[NSCollectionViewItem class]]; 
    }] objectAtIndex:0];
}
@end
