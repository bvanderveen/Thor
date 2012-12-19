#import "TargetView.h"
#import "BoxGroupView.h"

@implementation TargetHeadingView

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 125);
}

@end

@implementation TargetView

@synthesize scrollView, headingView, deploymentsList, headingBox, deploymentsBox, servicesBox, servicesList;

- (void)layout {
    [BoxGroupView layoutInBounds:self.bounds scrollView:scrollView boxes:@[ headingBox, deploymentsBox, servicesBox ] contentViews:@[ headingView, deploymentsList, servicesList ]];
    
    [super layout];
}

@end
