#import <ReactiveCocoa/ReactiveCocoa.h>

@interface PushActivity : NSObject

@property (nonatomic, copy) NSString *localPath, *targetHostname, *targetAppName, *status;
@property (nonatomic, assign) BOOL isActive;

- (id)initWithSubscribable:(RACSubscribable *)subscribable;

@end

@interface ActivityController : NSViewController

- (void)insert:(PushActivity *)activity;

@end
