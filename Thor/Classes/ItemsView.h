#import "BottomBar.h"
#import "CollectionView.h"

@interface ItemsView : NSView

@property (nonatomic, strong) IBOutlet NSView *containerView;
@property (nonatomic, strong) IBOutlet CollectionView *collectionView;
@property (nonatomic, strong) IBOutlet NSScrollView *collectionScrollView;

@end
