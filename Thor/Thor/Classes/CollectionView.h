
@interface CollectionScrollView : NSScrollView

@end

@interface TransparentCollectionView : NSCollectionView

@property (nonatomic, copy) NSCollectionViewItem *(^itemPrototypeFactory)(NSCollectionView *);

@end

@interface Label : NSTextField

+ (NSTextField *)label;

@end