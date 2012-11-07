#import "TargetPropertiesView.h"
#import "ThorCore.h"
#import "WizardController.h"

@interface TargetPropertiesController : NSViewController <WizardControllerAware> {
    
}

@property (nonatomic, strong) IBOutlet NSObjectController *objectController;
@property (nonatomic, assign) BOOL editing;
@property (nonatomic, strong) IBOutlet Target *target;
@property (nonatomic, strong) IBOutlet TargetPropertiesView *targetPropertiesView;

@end
