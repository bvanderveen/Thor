
@interface BoxGroupView : NSObject

// eventually this should take a scrollview and a list of (box, content) pairs. being lazy
// for now since we already have the two-box case implemented.
+ (void)layoutInBounds:(NSRect)bounds scrollView:(NSScrollView *)scrollView box1:(NSBox *)box1 boxContent1:(NSView *)boxContent1 box2:(NSBox *)box2 boxContent2:(NSView *)boxContent2;

@end
