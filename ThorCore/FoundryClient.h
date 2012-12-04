#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RestEndpoint : NSObject

- (RACSubscribable *)requestWithHost:(NSString *)host method:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body;

@end

@interface FoundryEndpoint : NSObject

@property (nonatomic, copy) NSString *hostname, *email, *password;

// result is parsed JSON of response body
- (RACSubscribable *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body;

- (RACSubscribable *)verifyCredentials;

@end

typedef enum {
    FoundryAppStateStarted,
    FoundryAppStateStopped,
    FoundryAppStateUnknown
} FoundryAppState;

typedef enum {
    FoundryAppMemoryAmountUnknown = -1,
    FoundryAppMemoryAmount64 = 0,
    FoundryAppMemoryAmount128 = 1,
    FoundryAppMemoryAmount256 = 2,
    FoundryAppMemoryAmount512 = 3,
    FoundryAppMemoryAmount1024 = 4,
    FoundryAppMemoryAmount2048 = 5,
} FoundryAppMemoryAmount;

NSUInteger FoundryAppMemoryAmountIntegerFromAmount(FoundryAppMemoryAmount amount);
FoundryAppMemoryAmount FoundryAppMemoryAmountAmountFromInteger(NSUInteger integer);
NSString * FoundryAppMemoryAmountStringFromAmount(FoundryAppMemoryAmount amount);

@interface FoundryApp : NSObject

@property (nonatomic, copy) NSString *name, *stagingFramework, *stagingRuntime;
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

@property (nonatomic, assign) bool isDown;
@property (nonatomic, copy) NSString *ID, *host;
@property (nonatomic, assign) NSInteger port, disk;
@property (nonatomic, assign) float cpu, memory, uptime;

+ (FoundryAppInstanceStats *)instantsStatsWithID:(NSString *)lID dictionary:(NSDictionary *)dictionary;

@end

@interface FoundrySlug : NSObject

@property (nonatomic, strong) NSURL *zipFile;
@property (nonatomic, copy) NSArray *manifiest;

@end

// this is a potentially long-running operation that involves
// recursively traversing the file system and generating
// checksums
NSArray *CreateSlugManifestFromPath(NSURL *rootURL);

// this is a potentially long-running operation that creates
// a zip archive on disk containing all the files in the manifest.
// you should delete the file when you're done with it.
NSURL *CreateSlugFromManifest(NSArray *manifest, NSURL *rootURL);

NSString *DetectFrameworkFromPath(NSURL *rootURL);

@interface FoundryServiceInfo : NSObject

@property (nonatomic, copy) NSString *description, *vendor, *version, *type;

@end

@interface FoundryService : NSObject

@property (nonatomic, copy) NSString *name, *vendor, *version, *type;

@end

@protocol FoundryClient <NSObject>

- (RACSubscribable *)getApps; // NSArray of FoundryApp
- (RACSubscribable *)getAppWithName:(NSString *)name; // FoundryApp
- (RACSubscribable *)getStatsForAppWithName:(NSString *)name; // NSArray of FoundryAppInstanceStats

- (RACSubscribable *)createApp:(FoundryApp *)app;
- (RACSubscribable *)updateApp:(FoundryApp *)app;
- (RACSubscribable *)deleteAppWithName:(NSString *)name;
- (RACSubscribable *)postSlug:(NSURL *)slug manifest:(NSArray *)manifest toAppWithName:(NSString *)name;

- (RACSubscribable *)getServicesInfo; // NSArray of FoundryServiceInfo
- (RACSubscribable *)getServices; // NSArray of FoundryService
- (RACSubscribable *)getServiceWithName:(NSString *)name;
- (RACSubscribable *)createService:(FoundryService *)service;
- (RACSubscribable *)deleteServiceWithName:(NSString *)name;

@end

extern NSString *FoundryClientErrorDomain;

const static NSInteger FoundryClientInvalidCredentials = 1;

@interface FoundryClient : NSObject <FoundryClient>

@property (nonatomic, strong) FoundryEndpoint *endpoint;

- (id)initWithEndpoint:(FoundryEndpoint *)endpoint;

@end
