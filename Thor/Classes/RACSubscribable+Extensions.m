#import "RACSubscribable+Extensions.h"
#import "LoadingView.h"
#import "Sequence.h"


@interface NSView (EnableDisableControls)

- (void)enableAllControls;
- (void)disableAllControls;

@end

@implementation NSView (EnableDisableControls)

- (NSArray *)selectControls {
    return [[self.subviews filter:^BOOL(id v) {
        return [v isKindOfClass:[NSControl class]];
    }] concat:[self.subviews reduce:^id(id acc, id i) {
        return [(NSArray *)acc concat:[i selectControls]];
    } seed:@[]]];
}

- (void)enableAllControls {
    [[self selectControls] each:^(id c) {
        ((NSControl *)c).enabled = YES;
    }];
}

- (void)disableAllControls {
    [[self selectControls] each:^(id c) {
        ((NSControl *)c).enabled = NO;
    }];
}

@end

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

- (RACSubscribable *)showLoadingViewInWizard:(WizardController *)wizard {
    return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        [wizard displayLoadingView];
        [wizard.view disableAllControls];
        void (^hideLoadingView)() = ^ {
            [wizard hideLoadingView];
            [wizard.view enableAllControls];
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

