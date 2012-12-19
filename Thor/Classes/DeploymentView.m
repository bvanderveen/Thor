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

@synthesize scrollView, settingsBox, instancesBox, servicesBox, instancesGrid, settingsView, toolbarView, servicesList, stateProgressIndicator;

- (void)layout {
    CGFloat toolbarHeight = toolbarView.intrinsicContentSize.height;
    
    toolbarView.frame = NSMakeRect(0, self.bounds.size.height - toolbarHeight, self.bounds.size.width, toolbarHeight);
    
    NSRect groupViewBounds = NSMakeRect(0, 0, self.bounds.size.width, self.bounds.size.height - toolbarHeight);
    
    [BoxGroupView layoutInBounds:groupViewBounds scrollView:scrollView boxes:@[ settingsBox, instancesBox, servicesBox ] contentViews:@[ settingsView, instancesGrid, servicesList ]];
    
    [super layout];
}

@end
