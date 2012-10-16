#import "RACSubscribable+Extensions.h"

@implementation RACSubscribable (Extensions)

- (RACSubscribable *)showLoadingViewInView:(NSView *)view {
    return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        [view showModalLoadingView];
        return [[self doCompleted:^ {
            [view hideLoadingView];
        }] subscribe:subscriber];
    }];
}

- (RACSubscribable *)continueWith:(RACSubscribable *)subscribable {
    return [[self select:^id(id x) {
        return subscribable;
    }] selectMany:^id<RACSubscribable>(id x) {
        return x;
    }];
}

@end

