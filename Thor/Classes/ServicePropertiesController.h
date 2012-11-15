#import "WizardController.h"
#import "ServicePropertiesView.h"
#import "ThorCore.h"

@interface ServicePropertiesController : NSViewController <WizardControllerAware>

@property (nonatomic, strong) IBOutlet NSObjectController *objectController;
//@property (nonatomic, assign) BOOL editing;
@property (nonatomic, strong) IBOutlet FoundryService *service;
@property (nonatomic, strong) IBOutlet ServicePropertiesView *servicePropertiesView;

- (id)initWithClient:(FoundryClient *)client;

@end
