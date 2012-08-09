#import "BottomBar.h"
#import "CollectionView.h"

@interface ItemsView : NSView

@property (nonatomic, strong) IBOutlet BottomBar *bar;
@property (nonatomic, strong) IBOutlet NSView *containerView;
@property (nonatomic, strong) IBOutlet TransparentCollectionView *collectionView;

@end
