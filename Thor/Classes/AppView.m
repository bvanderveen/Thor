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
    [BoxGroupView layoutInBounds:self.bounds scrollView:scrollView boxes:@[ settingsBox, deploymentsBox ] contentViews:@[ settingsView, deploymentsList ]];
    
    [super layout];
}

@end
