#import <ReactiveCocoa/ReactiveCocoa.h>
#import "Packaging.h"

@interface RestEndpoint : NSObject

- (RACSignal *)requestSignalWithURLRequest:(NSURLRequest *)urlRequest;

@end

@interface FoundryEndpoint : NSObject <NSCopying>

@property (nonatomic, copy) NSString *email, *password;
@property (nonatomic, strong) NSURL *hostURL;

// result is parsed JSON of response body
- (RACSignal *)authenticatedRequestWithMethod:(NSString *)method path:(NSString *)path headers:(NSDictionary *)headers body:(id)body;

- (RACSignal *)verifyCredentials;

@end

typedef enum {
    FoundryAppStateStarted,
    FoundryAppStateStarting,
    FoundryAppStateStopped,
    FoundryAppStateStopping,
    FoundryAppStateUnknown
} FoundryAppState;

BOOL FoundryAppStateIsTransient(FoundryAppState state);
NSString *FoundryAppStateStringFromState(FoundryAppState state);

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


typedef enum {
    FoundryAppInstanceStateUnknown,
    FoundryAppInstanceStateDown
} FoundryAppInstanceState;

@interface FoundryAppInstanceStats : NSObject

@property (nonatomic, assign) FoundryAppInstanceState state;
@property (nonatomic, copy) NSString *ID, *host;
@property (nonatomic, assign) NSInteger port, disk;
@property (nonatomic, assign) float cpu, memory, uptime;

+ (FoundryAppInstanceStats *)instantsStatsWithID:(NSString *)lID dictionary:(NSDictionary *)dictionary;

@end

NSString *DetectFrameworkFromPath(NSURL *rootURL);

@interface FoundryServiceInfo : NSObject

@property (nonatomic, copy) NSString *serviceDescription, *vendor, *version, *type;

@end

@interface FoundryService : NSObject

@property (nonatomic, copy) NSString *name, *vendor, *version, *type;

@end

typedef enum {
    FoundryPushStageBuildingManifest,
    FoundryPushStageCompressingFiles,
    FoundryPushStageWritingPackage,
    FoundryPushStageUploadingPackage,
    FoundryPushStageFinished,
} FoundryPushStage;

NSString *FoundryPushStageString(FoundryPushStage stage);

@protocol FoundryClient <NSObject>

- (RACSignal *)getApps; // NSArray of FoundryApp
- (RACSignal *)getAppWithName:(NSString *)name; // FoundryApp
- (RACSignal *)getStatsForAppWithName:(NSString *)name; // NSArray of FoundryAppInstanceStats

- (RACSignal *)createApp:(FoundryApp *)app;
- (RACSignal *)updateApp:(FoundryApp *)app;
- (RACSignal *)updateApp:(FoundryApp *)app withState:(FoundryAppState)state;
- (RACSignal *)updateApp:(FoundryApp *)app byAddingServiceNamed:(NSString *)name;
- (RACSignal *)updateApp:(FoundryApp *)app byRemovingServiceNamed:(NSString *)name;
- (RACSignal *)deleteAppWithName:(NSString *)name;

// subscription is a long-running operation. subscribe on background scheduler.
- (RACSignal *)pushAppWithName:(NSString *)name fromLocalPath:(NSString *)localPath packaging:(id<Packaging>)packaging;

- (RACSignal *)getServicesInfo; // NSArray of FoundryServiceInfo
- (RACSignal *)getServices; // NSArray of FoundryService
- (RACSignal *)getServiceWithName:(NSString *)name;
- (RACSignal *)createService:(FoundryService *)service;
- (RACSignal *)deleteServiceWithName:(NSString *)name;

@end

extern NSString *FoundryClientErrorDomain;

const static NSInteger FoundryClientInvalidCredentials = 1;

@interface FoundryClient : NSObject <FoundryClient>

@property (nonatomic, strong) FoundryEndpoint *endpoint;

+ (FoundryClient *)clientWithEndpoint:(FoundryEndpoint *)endpoint;

- (id)initWithEndpoint:(FoundryEndpoint *)endpoint;

@end
