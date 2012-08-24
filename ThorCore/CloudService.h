
@interface CloudInfo : NSObject

@property (nonatomic, copy) NSString *hostname, *email, *password;

@end

typedef enum {
    FoundryAppStateStarted,
    FoundryAppStateStopped
} FoundryAppState;

@interface FoundryApp : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray *uris;
@property (nonatomic, assign) NSInteger 
    instances,
    memory,
    disk;
@property (nonatomic, assign) FoundryAppState state;

@end

@interface FoundryAppInstanceStats : NSObject

@property (nonatomic, copy) NSString *ID, *host;
@property (nonatomic, assign) NSInteger port, memory, disk;
@property (nonatomic, assign) float cpu, uptime;

@end


@protocol FoundryService <NSObject>

- (NSArray *)getApps;
- (FoundryApp *)getAppWithName:(NSString *)name;
- (NSArray *)getStatsForAppWithName:(NSString *)name;

@end

@interface FixtureCloudService : NSObject <FoundryService>

@end
