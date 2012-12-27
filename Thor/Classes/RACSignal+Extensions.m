#import "RACSignal+Extensions.h"
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

@implementation RACSignal (Extensions)

- (RACSignal *)animateProgressIndicator:(NSProgressIndicator *)indicator {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [indicator startAnimation:self];
        void (^stopAnimation)() = ^ {
            [indicator stopAnimation:self];
        };
        return [[[self doCompleted:stopAnimation] doError:stopAnimation] subscribe:subscriber];
    }];
}

- (RACSignal *)showLoadingViewInView:(NSView *)view {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [view showModalLoadingView];
        void (^hideLoadingView)() = ^ {
            [view hideLoadingView];
        };
        return [[[self doCompleted:hideLoadingView] doError:hideLoadingView] subscribe:subscriber];
    }];
}

- (RACSignal *)showLoadingViewInWizard:(WizardController *)wizard {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [wizard displayLoadingView];
        [wizard.view disableAllControls];
        void (^hideLoadingView)() = ^ {
            [wizard hideLoadingView];
            [wizard.view enableAllControls];
        };
        return [[[self doCompleted:hideLoadingView] doError:hideLoadingView] subscribe:subscriber];
    }];
}

- (RACSignal *)continueWith:(RACSignal *)signal {
    return [self continueAfter:^ RACSignal * (id x) {
        return signal;
    }];
}

- (RACSignal *)continueAfter:(RACSignal *(^)(id))signal {
    return [[self map:^id(id x) {
        return signal(x);
    }] flattenMap:^RACStream *(id x) {
        return x;
    }];
}

+ (RACSignal *)performBlockInBackground:(id (^)())block {
    return [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:block()];
        [subscriber sendCompleted];
        return nil;
    }] subscribeOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]] deliverOn:[RACScheduler mainThreadScheduler]];
}

@end

