#import "RACSubscribable+Extensions.h"

@implementation RACSubscribable (Extensions)

- (RACSubscribable *)showLoadingViewInView:(NSView *)view {
    return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        [view showModalLoadingView];
        void (^hideLoadingView)() = ^ {
            [view hideLoadingView];
        };
        return [[[self doCompleted:hideLoadingView] doError:hideLoadingView] subscribe:subscriber];
    }];
}

- (RACSubscribable *)continueWith:(RACSubscribable *)subscribable {
    return [self continueAfter:^ RACSubscribable * (id x) {
        return subscribable;
    }];
}

- (RACSubscribable *)continueAfter:(RACSubscribable *(^)(id))subscribable {
    return [[self select:^id(id x) {
        return subscribable(x);
    }] selectMany:^id<RACSubscribable>(id x) {
        return x;
    }];
}

@end

