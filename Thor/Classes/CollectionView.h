
@interface CollectionScrollView : NSScrollView

@end

@class CollectionView;

@interface NSObject (CollectionViewDataSource)

- (NSCollectionViewItem *)collectionView:(CollectionView *)collectionView newItemForRepresentedObject:(id)object;

@end

@interface CollectionView : NSCollectionView

@property (nonatomic, unsafe_unretained) id dataSource;

@end