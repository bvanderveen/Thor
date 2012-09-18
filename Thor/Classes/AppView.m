#import "AppView.h"
#import "BoxGroupView.h"

@implementation AppView : NSView

@synthesize drawerBar, appContentView;

- (void)layout {
    self.drawerBar.frame = self.bounds;
    [super layout];
}

@end

@interface AppSettingsView : NSView

@end

@implementation AppSettingsView

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 107);
}

@end

@implementation AppContentView

@synthesize scrollView, deploymentsList, deploymentsBox, settingsBox, settingsView;

- (void)awakeFromNib {
    deploymentsList.rowHeight = 50;
}

- (void)layout {
    [BoxGroupView layoutInBounds:self.bounds scrollView:scrollView box1:settingsBox boxContent1:settingsView box2:deploymentsBox boxContent2:deploymentsList];
    
    [super layout];
}

@end
