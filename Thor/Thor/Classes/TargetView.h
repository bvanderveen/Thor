#import "GridView.h"

@interface TargetView : NSView

@property (nonatomic, strong) NSBox *infoBox, *deploymentsBox;
@property (nonatomic, strong) NSTextField *hostnameLabel, *hostnameValueLabel, *emailLabel, *emailValueLabel;
@property (nonatomic, strong) GridView *deploymentsGrid;
@property (nonatomic, strong) NSButton *editButton;

- (id)initWithTarget:(Target *)target;

@end
