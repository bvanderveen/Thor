#import "AppItemsDataSource.h"
#import "AppPropertiesController.h"
#import "AppController.h"
#import "CollectionItemView.h"
#import "Sequence.h"

static NSNib *nib = nil;

@interface AppItemsDataSource ()

@property (nonatomic, copy) void (^action)(ItemsController *, id);

@end

@implementation AppItemsDataSource

@synthesize action;

+ (void)initialize {
    nib = [[NSNib alloc] initWithNibNamed:@"AppCollectionItemView" bundle:nil];
}

- (id)initWithSelectionAction:(void (^)(ItemsController *, id))lAction {
    if (self = [super init]) {
        self.action = lAction;
    }
    return self;
}

- (NSArray *)itemsForItemsController:(ItemsController *)itemsController error:(NSError **)error {
    return [[ThorBackend shared] getConfiguredApps:error];
}

- (NSViewController *)newItemPropertiesControllerForItemsController:(ItemsController *)itemsController {
    AppPropertiesController *appPropertiesController = [[AppPropertiesController alloc] init];
    appPropertiesController.app = [App appInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    return appPropertiesController;
}

- (NSCollectionViewItem *)itemsController:(ItemsController *)itemsController collectionViewItemForCollectionView:(NSCollectionView *)collectionView item:(id)item   {
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
