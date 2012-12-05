#import "ListView.h"

@interface AppView : NSView

@property (nonatomic, strong) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) IBOutlet NSBox *deploymentsBox;
@property (nonatomic, strong) IBOutlet ListView *deploymentsList;

@end
