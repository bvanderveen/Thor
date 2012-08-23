
@interface CloudInfo

@property (nonatomic, copy) NSString *hostname, *email, *password;

@end

typedef enum {
    CloudAppStateStarted,
    CloudAppStateStopped
} CloudAppState;

@interface CloudApp : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *uris;
@property (nonatomic, assign) NSInteger 
    instances,
    memory,
    disk;
@property (nonatomic, assign) CloudAppState state;

@end


@protocol CloudService <NSObject>

- (CloudApp *)getAppWithName:(NSString *)name;

@end

@interface FixtureCloudService : NSObject <CloudService>

@end
