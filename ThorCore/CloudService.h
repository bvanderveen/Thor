
@interface CloudInfo : NSObject

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

@interface CloudAppInstanceStats : NSObject

@property (nonatomic, copy) NSString *ID, *host;
@property (nonatomic, assign) NSInteger port, memory, disk;
@property (nonatomic, assign) float cpu, uptime;

@end


@protocol CloudService <NSObject>

- (NSArray *)getApps;
- (CloudApp *)getAppWithName:(NSString *)name;
- (NSArray *)getStatsForAppWithName:(NSString *)name;

@end

@interface FixtureCloudService : NSObject <CloudService>

@end
