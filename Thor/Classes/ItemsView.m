#import "ItemsView.h"

@implementation ItemsView

@synthesize containerView, collectionView, bar, collectionScrollView;

- (void)awakeFromNib {
    self.collectionView.minItemSize = NSMakeSize(175, 175);
    self.collectionView.maxItemSize = NSMakeSize(175, 175);
}

- (void)layout {
    // TODO factor bar out of items view
    NSSize barSize = bar.intrinsicContentSize;
    bar.frame = NSMakeRect(0, 0, self.bounds.size.width, barSize.height);
    collectionScrollView.frame = NSMakeRect(0, barSize.height, self.bounds.size.width, self.bounds.size.height - barSize.height);
    [super layout];
}

@end
