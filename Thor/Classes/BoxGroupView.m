#import "BoxGroupView.h"

@implementation BoxGroupView

+ (void)layoutInBounds:(NSRect)bounds scrollView:(NSScrollView *)scrollView box1:(NSBox *)box1 boxContent1:(NSView *)boxContent1 box2:(NSBox *)box2 boxContent2:(NSView *)boxContent2 {
    
    scrollView.frame = bounds;
    
    CGFloat boxTopMargin = 50;
    CGFloat boxBottomMargin = 20;
    
    NSEdgeInsets boxContentInsets = NSEdgeInsetsMake(35, 0, 10, 0);
    
    NSSize boxContent1Size = boxContent1.intrinsicContentSize;
    CGFloat box1Height = boxContent1Size.height + boxContentInsets.top + boxContentInsets.bottom;
    
    NSSize boxContent2Size = boxContent2.intrinsicContentSize;
    CGFloat box2Height = boxContent2Size.height + boxContentInsets.top + boxContentInsets.bottom;
    
    NSView *documentView = ((NSView *)scrollView.documentView);
    
    CGFloat verticalMargin = 20;
    
    CGFloat documentViewHeight = verticalMargin + box1Height + verticalMargin + box2Height + verticalMargin;
    
    if (documentViewHeight < bounds.size.height)
        documentViewHeight = bounds.size.height;
    
    CGFloat horizontalMargin = 20;
    CGFloat boxWidth = bounds.size.width - horizontalMargin * 2;
    
    documentView.frame = NSMakeRect(0, 0, bounds.size.width - 2, documentViewHeight);
    
    box1.frame = NSMakeRect(horizontalMargin, documentViewHeight - (box1Height + verticalMargin), boxWidth, box1Height);
    boxContent1.frame = NSMakeRect(0, boxContentInsets.bottom, boxContent1.bounds.size.width, boxContent1Size.height);
    
    box2.frame = NSMakeRect(horizontalMargin, documentViewHeight - (box1Height + verticalMargin + box2Height + verticalMargin), boxWidth, box2Height);
    boxContent2.frame = NSMakeRect(0, boxContentInsets.bottom, boxContent2.bounds.size.width, boxContent2Size.height);
}

@end
