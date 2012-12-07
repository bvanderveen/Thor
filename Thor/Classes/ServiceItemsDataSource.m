#import "ServiceItemsDataSource.h"
#import "CollectionItemView.h"
#import "Sequence.h"

static NSNib *nib = nil;

@interface ServiceItemsDataSource ()

@property (nonatomic, strong) NSArray *services;

@end

@implementation ServiceItemsDataSource

@synthesize services;

+ (void)initialize {
    nib = [[NSNib alloc] initWithNibNamed:@"ServiceCollectionItemView" bundle:nil];
}

- (id)initWithServices:(NSArray *)lesServices {
    if (self = [super init]) {
        self.services = lesServices;
    }
    return self;
}

- (RACSubscribable *)itemsForItemsController:(ItemsController *)itemsController error:(NSError **)error {
    return [RACSubscribable return:services];
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
    [button bind:@"label" toObject:item withKeyPath:@"name" options:nil];
    
    [button addCommand:[RACCommand commandWithCanExecute:nil execute:^ void (id v) {
        assert([itemsController.arrayController setSelectedObjects:@[ item ]]);
    }]];
    
    return [[topLevelObjects filter:^ BOOL (id o) {
        return [o isKindOfClass:[NSCollectionViewItem class]];
    }] objectAtIndex:0];
}

@end