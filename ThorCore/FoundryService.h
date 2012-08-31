#import <ReactiveCocoa/ReactiveCocoa.h>

@interface FoundryEndpoint : NSObject

@property (nonatomic, copy) NSString *hostname, *email, *password;

// result is parsed JSON of response body
- (RACSubscribable *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body;

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

+ (FoundryApp *)appWithDictionary:(NSDictionary *)appDict;

@end

@interface FoundryAppInstanceStats : NSObject

@property (nonatomic, copy) NSString *ID, *host;
@property (nonatomic, assign) NSInteger port, disk;
@property (nonatomic, assign) float cpu, memory, uptime;

+ (FoundryAppInstanceStats *)instantsStatsWithID:(NSString *)lID dictionary:(NSDictionary *)dictionary;

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
