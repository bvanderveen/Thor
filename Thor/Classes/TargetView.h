#import "ListView.h"

@interface TargetHeadingView : NSView

@end

@interface TargetView : NSView

@property (nonatomic, strong) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) IBOutlet NSBox *headingBox, *deploymentsBox, *servicesBox;
@property (nonatomic, strong) IBOutlet ListView *deploymentsList, *servicesList;
@property (nonatomic, strong) IBOutlet TargetHeadingView *headingView;

@end
