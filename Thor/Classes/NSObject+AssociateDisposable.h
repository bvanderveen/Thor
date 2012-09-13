#import <ReactiveCocoa/ReactiveCocoa.h>

@interface NSObject (AssociateDisposable)

@property (nonatomic, strong) RACDisposable *associatedDisposable;

@end
