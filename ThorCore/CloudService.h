#import <ReactiveCocoa/ReactiveCocoa.h>

@interface FoundryEndpoint : NSObject

@property (nonatomic, copy) NSString *hostname, *email, *password;

@end

typedef enum {
    FoundryAppStateStarted,
    FoundryAppStateStopped,
    FoundryAppStateUnknown
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
@property (nonatomic, assign) NSInteger port, disk;
@property (nonatomic, assign) float cpu, memory, uptime;

@end


@protocol FoundryService <NSObject>

- (RACSubscribable *)getApps; // NSArray of FoundryApp
- (RACSubscribable *)getAppWithName:(NSString *)name; // FoundryApp
- (RACSubscribable *)getStatsForAppWithName:(NSString *)name; // NSArray of FoundryAppInstanceStats

@end

@interface FoundryService : NSObject <FoundryService>

@property (nonatomic, strong) FoundryEndpoint *endpoint;

- (id)initWithEndpoint:(FoundryEndpoint *)endpoint;

@end

@interface FixtureCloudService : NSObject <FoundryService>

@end
