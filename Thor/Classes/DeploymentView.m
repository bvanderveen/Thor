#import "DeploymentView.h"
#import "BoxGroupView.h"

@interface DeploymentSettingsView : NSView

@end

@implementation DeploymentSettingsView

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 155);
}

@end

@implementation DeploymentView

@synthesize scrollView, settingsBox, instancesBox, instancesGrid, settingsView, toolbarView;

- (void)layout {
    CGFloat toolbarHeight = toolbarView.intrinsicContentSize.height;
    
    toolbarView.frame = NSMakeRect(0, self.bounds.size.height - toolbarHeight, self.bounds.size.width, toolbarHeight);
    
    NSRect groupViewBounds = NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height - toolbarHeight);
    
    [BoxGroupView layoutInBounds:groupViewBounds scrollView:scrollView box1:settingsBox boxContent1:settingsView box2:instancesBox boxContent2:instancesGrid];
    
    [super layout];
}

@end
