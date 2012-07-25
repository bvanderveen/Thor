#import "CollectionView.h"

@implementation CollectionScrollView

- (void)drawRect:(NSRect)dirtyRect {
    NSImage *background = [NSImage imageNamed:@"CollectionViewBackground"];
    [[NSColor colorWithPatternImage:background] set];
    NSRectFill(dirtyRect);
}

@end


@implementation TransparentCollectionView

- (void)drawRect:(NSRect)dirtyRect {
    // do nothing!
}

@end