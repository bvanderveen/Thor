#import "LoadingView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSubscribable (Extensions)

// probably would make more sense to make this a category on view
// - (RACSubscribable *)showLoadingViewDuring:(RACSubscribable *)subscribable;
- (RACSubscribable *)showLoadingViewInView:(NSView *)view;

// subscribe to the given subscribable after the reciever has completed.
// discards recievers values.
- (RACSubscribable *)continueWith:(RACSubscribable *)subscribable;

- (RACSubscribable *)continueAfter:(RACSubscribable *(^)(id))subscribable;

@end

