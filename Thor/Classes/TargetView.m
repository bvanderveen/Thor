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

@synthesize scrollView, deploymentsList, deploymentsBox, servicesBox, servicesList;

- (void)layout {
    [BoxGroupView layoutInBounds:self.bounds scrollView:scrollView boxes:@[ deploymentsBox, servicesBox ] contentViews:@[ deploymentsList, servicesList ]];
    
    [super layout];
}

@end
