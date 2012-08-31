#import "ItemsView.h"

@implementation ItemsView

@synthesize containerView, collectionView, bar, collectionScrollView;

- (void)awakeFromNib {
    self.collectionView.minItemSize = NSMakeSize(175, 175);
    self.collectionView.maxItemSize = NSMakeSize(175, 175);
}

- (void)layout {
    // TODO factor bar out of items view
    bar.frame = NSZeroRect;
    collectionScrollView.frame = self.bounds;
    [super layout];
}

@end
