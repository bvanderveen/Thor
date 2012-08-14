#import "ItemsView.h"

@implementation ItemsView

@synthesize containerView, collectionView, bar;

- (void)awakeFromNib {
    self.collectionView.minItemSize = NSMakeSize(150, 150);
}

@end
