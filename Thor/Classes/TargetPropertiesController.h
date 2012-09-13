#import "TargetPropertiesView.h"
#import "ThorCore.h"

@interface TargetPropertiesController : NSViewController {
    
}

@property (nonatomic, strong) IBOutlet NSObjectController *objectController;
@property (nonatomic, assign) BOOL editing;
@property (nonatomic, strong) IBOutlet Target *target;
@property (nonatomic, strong) IBOutlet TargetPropertiesView *targetPropertiesView;

- (IBAction)buttonClicked:(NSButton *)button;

@end
