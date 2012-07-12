#import "AppsView.h"


@implementation AppsView

@synthesize collectionView;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.collectionView = [[NSCollectionView alloc] initWithFrame:NSZeroRect];
    }
    return self;
}

- (void)layout {
    
}

@end
