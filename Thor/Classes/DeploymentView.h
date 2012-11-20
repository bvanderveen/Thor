#import "GridView.h"
#import "DeploymentToolbarView.h"
#import "ListView.h"

@interface DeploymentView : NSView

@property (nonatomic, strong) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) IBOutlet NSBox *settingsBox, *instancesBox, *servicesBox;
@property (nonatomic, strong) IBOutlet GridView *instancesGrid;
@property (nonatomic, strong) IBOutlet ListView *servicesList;
@property (nonatomic, strong) IBOutlet NSView *settingsView;
@property (nonatomic, strong) IBOutlet DeploymentToolbarView *toolbarView;

@end
