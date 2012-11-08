#import "TargetView.h"
#import "BoxGroupView.h"

@interface TargetSettingsView : NSView

@end

@implementation TargetSettingsView

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 135);
}

@end

@implementation TargetView

@synthesize scrollView, deploymentsList, deploymentsBox, servicesBox, settingsBox, settingsView, servicesList;

- (void)layout {
    [BoxGroupView layoutInBounds:self.bounds scrollView:scrollView boxes:@[ settingsBox, deploymentsBox, servicesBox ] contentViews:@[ settingsView, deploymentsList, servicesList ]];
    
    [super layout];
}

@end
