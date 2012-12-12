#import <ReactiveCocoa/ReactiveCocoa.h>

@interface PushActivity : NSObject

@property (nonatomic, copy) NSString *localPath, *targetHostname, *targetAppName, *status;

- (id)initWithSubscribable:(RACSubscribable *)subscribable;

@end

@interface ActivityController : NSViewController

- (void)insert:(PushActivity *)activity;

@end
