#import "ItemsView.h"

@implementation ItemsView

@synthesize containerView, collectionView, collectionScrollView;

- (void)awakeFromNib {
    self.collectionView.minItemSize = NSMakeSize(175, 175);
    self.collectionView.maxItemSize = NSMakeSize(175, 175);
}

- (void)layout {
    collectionScrollView.frame = self.bounds;
    [super layout];
}

@end
