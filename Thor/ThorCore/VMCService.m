#import "VMCService.h"

NSString *VMCServiceErrorDomain = @"com.tier3.thor.VMCServiceErrorDomain";

@implementation VMCDeployment

@synthesize name, cpu, memory, disk;

@end

@implementation FixtureVMCService

- (NSArray *)getDeploymentsForTarget:(Target *)target error:(NSError **)error {
    VMCDeployment *deployment0 = [VMCDeployment new];
    deployment0.name = @"Foo";
    deployment0.cpu = @"33%";
    deployment0.memory = @"256M";
    deployment0.disk = @"128MB";
    
    VMCDeployment *deployment1 = [VMCDeployment new];
    deployment1.name = @"Bar";
    deployment1.cpu = @"66%";
    deployment1.memory = @"512M";
    deployment1.disk = @"256MB";
    
    return [NSArray arrayWithObjects:deployment0, deployment1, nil];
}

@end

@interface VMCTarget : NSObject

@property (nonatomic, copy) NSString *hostname, *email, *password;

@end

@implementation VMCTarget

@synthesize hostname, email, password;

+ (VMCTarget *)targetWithTargetModel:(Target *)target {
    VMCTarget *result = [VMCTarget new];
    result.hostname = target.hostname;
    result.email = target.email;
    result.password = target.password;
    return result;
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%@%@%@", hostname, email, password] hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[VMCTarget class]]) return NO;
    
    VMCTarget *other = (VMCTarget *)object;
    
    return 
        [other.hostname isEqual:hostname] &&
        [other.email isEqual:email] &&
        [other.password isEqual:password];
}

@end

@interface VMCServiceImpl ()

@property (nonatomic, strong) id<VMCOperations> vmc;
@property (nonatomic, strong) VMCTarget *currentTarget;

@end

@implementation VMCServiceImpl

@synthesize vmc, currentTarget;

- (id)initWithVMCOperations:(id<VMCOperations>)leVmc {
    if (self = [super init]) {
        self.vmc = leVmc;
    }
    return self;
}

- (BOOL)ensureTarget:(Target *)target error:(NSError **)error {
    VMCTarget *newTarget = [VMCTarget targetWithTargetModel:target];
    if (![currentTarget isEqual:newTarget]) {
        self.currentTarget = newTarget;
        if (![vmc targetHostname:currentTarget.hostname]) {
            NSError *e = [[NSError alloc] initWithDomain:VMCServiceErrorDomain code:FailedToTarget userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Could not connect to host '%@'", currentTarget.hostname] forKey:NSLocalizedDescriptionKey]];
            *error = e;
            return NO;
        }
        
        if (![vmc loginWithEmail:currentTarget.email password:currentTarget.password]) {
            NSError *e = [[NSError alloc] initWithDomain:VMCServiceErrorDomain code:FailedToTarget userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Could not log in to host '%@', double check the email and password.", currentTarget.hostname] forKey:NSLocalizedDescriptionKey]];
            *error = e;
            return NO;
        }
    }
    
    return YES;
}

- (NSArray *)getDeploymentsForTarget:(Target *)target error:(NSError **)error {
    if (![self ensureTarget:target error:error])
        return nil;
    
    return [[vmc getApps] map:^ id (id a) {
        VMCDeployment *d = [VMCDeployment new];
        d.name = a;
        return d;
    }];
}

@end

id<VMCService> sharedService = nil;

@implementation VMCService

+ (id<VMCService>)shared {
    if (!sharedService)
        sharedService = [[VMCServiceImpl alloc] initWithVMCOperations:[[VMCOperationsImpl alloc] initWithShellBlock:RVMExecute]];
    return sharedService;
}

@end