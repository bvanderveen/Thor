#import "BottomBar.h"

@interface ItemsView : NSView

@property (nonatomic, strong) BottomBar *bar;
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) IBOutlet NSView *collectionView;

@end
