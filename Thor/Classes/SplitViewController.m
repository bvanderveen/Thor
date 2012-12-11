#import "SplitViewController.h"

@interface SplitViewController ()

@property (nonatomic, strong) NSSplitView *splitView;

@end

@implementation SplitViewController

@synthesize splitView;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
    }
    return self;
}

- (void)loadView {
    self.splitView = [[NSSplitView alloc] initWithFrame:NSZeroRect];
    self.splitView.dividerStyle = NSSplitViewDividerStyleThin;
    self.splitView.vertical = YES;
    self.splitView.delegate = self;
    self.splitView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.view = splitView;
}

- (CGFloat)splitView:(NSSplitView *)leSplitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    CGFloat minimum = 200 * (dividerIndex + 1);
    CGFloat maximum = leSplitView.bounds.size.width - (200 * (leSplitView.subviews.count - (dividerIndex + 1)));
    return MIN(maximum, MAX(minimum, proposedPosition));
}

@end
