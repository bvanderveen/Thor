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

@synthesize scrollView, settingsBox, instancesBox, instancesGrid, settingsView;

- (void)layout {
    [BoxGroupView layoutInBounds:self.bounds scrollView:scrollView box1:settingsBox boxContent1:settingsView box2:instancesBox boxContent2:instancesGrid];
    
    [super layout];
}

@end
