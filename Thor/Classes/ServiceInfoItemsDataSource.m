#import "ServiceInfoItemsDataSource.h"
#import "CollectionItemView.h"
#import "Sequence.h"

static NSNib *nib = nil;

@interface ServiceInfoItemsDataSource ()

@property (nonatomic, strong) FoundryClient *client;

@end

@implementation ServiceInfoItemsDataSource

@synthesize client;

+ (void)initialize {
    nib = [[NSNib alloc] initWithNibNamed:@"ServiceInfoCollectionItemView" bundle:nil];
}

- (id)initWithClient:(id)leClient {
    if (self = [super init]) {
        self.client = leClient;
    }
    return self;
}

- (RACSubscribable *)itemsForItemsController:(ItemsController *)itemsController error:(NSError **)error {
    return [client getServicesInfo];
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
    [button bind:@"label" toObject:item withKeyPath:@"description" options:nil];
    
    [button addCommand:[RACCommand commandWithCanExecute:nil execute:^ void (id v) {
        assert([itemsController.arrayController setSelectedObjects:@[ item ]]);
    }]];
    
    return [[topLevelObjects filter:^ BOOL (id o) {
        return [o isKindOfClass:[NSCollectionViewItem class]];
    }] objectAtIndex:0];
}

@end