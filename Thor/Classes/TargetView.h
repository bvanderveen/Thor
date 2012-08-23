#import "GridView.h"

@interface TargetView : NSView

@property (nonatomic, strong) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) IBOutlet NSBox *settingsBox, *deploymentsBox;
@property (nonatomic, strong) IBOutlet GridView *deploymentsGrid;
@property (nonatomic, strong) IBOutlet NSView *settingsView;

@end
