#import "NSObject+AssociateDisposable.h"
#import <objc/runtime.h>

@implementation NSObject (AssociateDisposable)

static NSUInteger kAssociatedDisposableKey;

- (void)setAssociatedDisposable:(RACDisposable *)associatedDisposable {
    objc_setAssociatedObject(self, &kAssociatedDisposableKey, [RACScopedDisposable scopedDisposableWithDisposable:associatedDisposable], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (RACDisposable *)associatedDisposable {
    return objc_getAssociatedObject(self, &kAssociatedDisposableKey);
}

@end
