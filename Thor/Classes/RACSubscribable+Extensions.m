#import "RACSubscribable+Extensions.h"
#import "LoadingView.h"

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

+ (RACSubscribable *)performBlockInBackground:(id (^)())block {
    return [[[RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:block()];
        [subscriber sendCompleted];
        return nil;
    }] subscribeOn:[RACScheduler backgroundScheduler]] deliverOn:[RACScheduler mainQueueScheduler]];
}

@end

