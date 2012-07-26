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

@implementation Label

+ (NSTextField *)label {
    NSTextField *result = [[NSTextField alloc] initWithFrame:NSZeroRect];
    result.editable = NO;
    result.bordered = NO;
    result.translatesAutoresizingMaskIntoConstraints = NO;
    result.drawsBackground = NO;
    result.alignment = NSRightTextAlignment;
    return  result;
}

@end