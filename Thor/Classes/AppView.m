#import "AppView.h"
#import "BoxGroupView.h"

@interface AppSettingsView : NSView

@end

@implementation AppSettingsView

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 107);
}

@end

@implementation AppView

@synthesize scrollView, deploymentsList, deploymentsBox, settingsBox, settingsView;

- (void)awakeFromNib {
    deploymentsList.rowHeight = 50;
}

- (void)layout {
    [BoxGroupView layoutInBounds:self.bounds scrollView:scrollView box1:settingsBox boxContent1:settingsView box2:deploymentsBox boxContent2:deploymentsList];
    
    [super layout];
}

@end
