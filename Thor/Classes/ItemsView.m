#import "ItemsView.h"

@implementation ItemsView

@synthesize containerView, collectionView, bar;

- (void)awakeFromNib {
    self.collectionView.minItemSize = NSMakeSize(175, 175);
    self.collectionView.maxItemSize = NSMakeSize(175, 175);
}

@end
