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

@property (nonatomic, copy) NSString *name, *stagingModel, *stagingStack;
@property (nonatomic, copy) NSArray *uris, *services;
@property (nonatomic, assign) NSUInteger
    instances,
    memory,
    disk;
@property (nonatomic, assign) FoundryAppState state;

+ (FoundryApp *)appWithDictionary:(NSDictionary *)appDict;
- (NSDictionary *)dictionaryRepresentation;

@end

@interface FoundryAppInstanceStats : NSObject

@property (nonatomic, copy) NSString *ID, *host;
@property (nonatomic, assign) NSInteger port, disk;
@property (nonatomic, assign) float cpu, memory, uptime;

+ (FoundryAppInstanceStats *)instantsStatsWithID:(NSString *)lID dictionary:(NSDictionary *)dictionary;

@end

@interface FoundrySlug : NSObject

@property (nonatomic, strong) NSURL *zipFile;
@property (nonatomic, copy) NSArray *resources;

@end

// this is a potentially long-running operation that involves
// recursively traversing the file system and generating
// checksums
FoundrySlug *CreateSlugFromPath(NSURL *path);

@protocol FoundryService <NSObject>

- (RACSubscribable *)getApps; // NSArray of FoundryApp
- (RACSubscribable *)getAppWithName:(NSString *)name; // FoundryApp
- (RACSubscribable *)getStatsForAppWithName:(NSString *)name; // NSArray of FoundryAppInstanceStats

- (RACSubscribable *)createApp:(FoundryApp *)app;
- (RACSubscribable *)postSlug:(FoundrySlug *)slug toAppWithName:(NSString *)name;

@end

@interface FoundryService : NSObject <FoundryService>

@property (nonatomic, strong) FoundryEndpoint *endpoint;

- (id)initWithEndpoint:(FoundryEndpoint *)endpoint;

@end
