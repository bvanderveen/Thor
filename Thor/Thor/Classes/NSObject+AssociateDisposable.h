
@interface NSObject (AssociateDisposable)

@property (nonatomic, strong) RACDisposable *associatedDisposable;

@end
