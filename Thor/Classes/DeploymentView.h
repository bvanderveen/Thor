#import "GridView.h"

@interface DeploymentView : NSView

@property (nonatomic, strong) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) IBOutlet NSBox *settingsBox, *instancesBox;
@property (nonatomic, strong) IBOutlet GridView *instancesGrid;
@property (nonatomic, strong) IBOutlet NSView *settingsView;

@end
