#import "ListView.h"

@interface TargetView : NSView

@property (nonatomic, strong) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) IBOutlet NSBox *deploymentsBox, *servicesBox;
@property (nonatomic, strong) IBOutlet ListView *deploymentsList, *servicesList;

@end
