#import "AppView.h"
#import "BoxGroupView.h"

@implementation AppView

@synthesize scrollView, deploymentsList, deploymentsBox;

- (void)awakeFromNib {
    deploymentsList.rowHeight = 50;
}

- (void)layout {
    [BoxGroupView layoutInBounds:self.bounds scrollView:scrollView boxes:@[ deploymentsBox ] contentViews:@[ deploymentsList ]];
    
    [super layout];
}

@end
