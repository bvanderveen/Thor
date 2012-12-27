#import <ReactiveCocoa/ReactiveCocoa.h>
#import "WizardController.h"

@interface RACSignal (Extensions)

- (RACSignal *)animateProgressIndicator:(NSProgressIndicator *)indicator;

// probably would make more sense to make this a category on view
// - (RACSignal *)showLoadingViewDuring:(RACSignal *)signal;
- (RACSignal *)showLoadingViewInView:(NSView *)view;

- (RACSignal *)showLoadingViewInWizard:(WizardController *)wizard;

// subscribe to the given signal after the reciever has completed.
// discards recievers values.
- (RACSignal *)continueWith:(RACSignal *)signal;

- (RACSignal *)continueAfter:(RACSignal *(^)(id))signal;

+ (RACSignal *)performBlockInBackground:(id (^)())block;

@end

