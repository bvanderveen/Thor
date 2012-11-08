#import "BoxGroupView.h"
#import "Sequence.h"

@implementation BoxGroupView

+ (void)layoutInBounds:(NSRect)bounds scrollView:(NSScrollView *)scrollView boxes:(NSArray *)boxes contentViews:(NSArray *)contentViews {
    
    scrollView.frame = bounds;
    
    NSEdgeInsets boxContentInsets = NSEdgeInsetsMake(35, 0, -2, 0);
    
    NSArray *boxHeights = [contentViews map:^ id (id c) {
        NSView *contentView = (NSView *)c;
        return [NSNumber numberWithFloat:contentView.intrinsicContentSize.height];
    }];
    
    NSView *documentView = ((NSView *)scrollView.documentView);
    
    CGFloat verticalMargin = 20;
    
    CGFloat documentViewHeight = [[boxHeights reduce:^id(id acc, id i) {
        return [NSNumber numberWithFloat:[(NSNumber *)acc floatValue] + [i floatValue]];
    } seed:@0.0] floatValue] + (boxContentInsets.top + boxContentInsets.bottom) * boxHeights.count + verticalMargin * (boxHeights.count + 1);
    
    if (documentViewHeight < bounds.size.height)
        documentViewHeight = bounds.size.height;
    
    CGFloat horizontalMargin = 20;
    CGFloat boxWidth = bounds.size.width - horizontalMargin * 2;
    
    documentView.frame = NSMakeRect(0, 0, bounds.size.width - 2, documentViewHeight);
    
    CGFloat y = documentViewHeight;
    
    for (int i = 0; i < boxes.count; i++) {
        NSBox *box = boxes[i];
        NSView *contentView = contentViews[i];
        CGFloat contentHeight = [boxHeights[i] floatValue];
        CGFloat boxHeight = contentHeight + boxContentInsets.top + boxContentInsets.bottom;
        y -= boxHeight + verticalMargin;
        
        box.frame = NSMakeRect(horizontalMargin, y, boxWidth, boxHeight);
        contentView.frame = NSMakeRect(0, boxContentInsets.bottom, boxWidth, contentHeight);
    }
    
    // probably this should not happen at every layout. but it works for now.
    [documentView scrollPoint:NSMakePoint(0, NSMaxY(documentView.frame) - NSHeight(scrollView.contentView.bounds))];
}

@end
