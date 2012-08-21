#import "AppView.h"

@interface AppSettingsView : NSView

@end

@implementation AppSettingsView

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 135);
}

@end

@implementation AppView

@synthesize scrollView, deploymentsGrid, deploymentsBox, settingsBox, settingsView;

- (void)layout {
    scrollView.frame = self.bounds;
    
    CGFloat boxTopMargin = 50;
    CGFloat boxBottomMargin = 20;
    
    NSEdgeInsets boxContentInsets = NSEdgeInsetsMake(35, 0, 10, 0);
    
    NSSize settingsViewSize = settingsView.intrinsicContentSize;
    CGFloat settingsBoxHeight = settingsViewSize.height + boxContentInsets.top + boxContentInsets.bottom;
    
    NSSize gridSize = deploymentsGrid.intrinsicContentSize;
    CGFloat gridBoxHeight = gridSize.height + boxContentInsets.top + boxContentInsets.bottom;
    
    NSView *documentView = ((NSView *)scrollView.documentView);
    
    CGFloat verticalMargin = 20;
    
    CGFloat documentViewHeight = verticalMargin + settingsBoxHeight + verticalMargin + gridBoxHeight + verticalMargin;
    
    if (documentViewHeight < self.bounds.size.height)
        documentViewHeight = self.bounds.size.height;
    
    CGFloat horizontalMargin = 20;
    CGFloat boxWidth = self.bounds.size.width - horizontalMargin * 2;
    
    documentView.frame = NSMakeRect(0, 0, self.bounds.size.width - 2, documentViewHeight);
    
    settingsBox.frame = NSMakeRect(horizontalMargin, documentViewHeight - (settingsBoxHeight + verticalMargin), boxWidth, settingsBoxHeight);
    settingsView.frame = NSMakeRect(0, boxContentInsets.bottom, settingsBox.bounds.size.width, settingsViewSize.height);
    
    deploymentsBox.frame = NSMakeRect(horizontalMargin, documentViewHeight - (settingsBoxHeight + verticalMargin + gridBoxHeight + verticalMargin), boxWidth, gridBoxHeight);
    deploymentsGrid.frame = NSMakeRect(0, boxContentInsets.bottom, deploymentsBox.bounds.size.width, gridSize.height);
    
    [super layout];
}

@end
