#import "ServicePropertiesController.h"
#import "RACSignal+Extensions.h"

@interface ServicePropertiesController ()

@property (nonatomic, strong) FoundryClient *client;

@end

@implementation ServicePropertiesController

@synthesize objectController, service, client, wizardController, title, commitButtonTitle;

- (id)initWithClient:(FoundryClient *)leClient {
    if (self = [super initWithNibName:@"ServicePropertiesView" bundle:[NSBundle mainBundle]]) {
        self.commitButtonTitle = @"OK";
        self.client = leClient;
    }
    return self;
}

- (void)commitWizardPanel {
    [objectController commitEditing];
    RACSignal *signal = [[client createService:service] showLoadingViewInWizard:self.wizardController];
    [signal subscribeNext:^ (id x) {
        NSLog(@"%@", x);
    } error:^(NSError *error) {
        [NSApp presentError:error];
        self.wizardController.commitButtonEnabled = YES;
    } completed:^{
        [self.wizardController dismissWithReturnCode:NSOKButton];
    }];
}

- (void)rollbackWizardPanel {
    
}

@end
