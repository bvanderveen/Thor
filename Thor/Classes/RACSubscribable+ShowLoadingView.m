#import "RACSubscribable+ShowLoadingView.h"

@implementation RACSubscribable (ShowLoadingView)

- (RACSubscribable *)showLoadingViewInView:(NSView *)view {
    return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        [view showModalLoadingView];
        return [[self doCompleted:^ {
            [view hideLoadingView];
        }] subscribe:subscriber];
    }];
}

@end