#import "LoadingView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RACSubscribable (ShowLoadingView)

// probably would make more sense to make this a category on view
// - (RACSubscribable *)showLoadingViewDuring:(RACSubscribable *)subscribable;
- (RACSubscribable *)showLoadingViewInView:(NSView *)view;

@end
