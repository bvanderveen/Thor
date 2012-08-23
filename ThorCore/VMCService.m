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


- (NSArray *)getInstanceStatsForAppName:(NSString *)appname target:(VMCTarget *)target error:(NSError **)error {
    VMCInstanceStats *stats0 = [VMCInstanceStats new];
    stats0.ID = @"0";
    stats0.host = @"10.0.0.1";
    stats0.cpu = @"100%";
    stats0.memory = @"2GB";
    stats0.disk = @"2TB";
    stats0.uptime = @"Forevs";
    
    VMCInstanceStats *stats1 = [VMCInstanceStats new];
    stats1.ID = @"1";
    stats1.host = @"10.0.0.2";
    stats1.cpu = @"110%";
    stats1.memory = @"2GB";
    stats1.disk = @"3TB";
    stats1.uptime = @"Foreva";
    
    return [NSArray arrayWithObjects:stats0, stats1, nil];
    
}

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
        VMCApp *app = ((VMCApp *)a);
        NSArray *stats = [vmc getInstanceStatsForApp:app.name];
        
        VMCDeployment *d = [VMCDeployment new];
        
        d.name = app.name;
        d.memory = [stats reduce:^id(id acc, id i) {
            NSString *memory = ((VMCInstanceStats *)i).memory;
            return [NSNumber numberWithFloat:[acc floatValue] + [memory floatValue]];
        } seed:[NSNumber numberWithInt:0]];
        d.cpu = [stats reduce:^id(id acc, id i) {
            NSString *cpu = ((VMCInstanceStats *)i).cpu;
            return [NSNumber numberWithFloat:[acc floatValue] + [cpu floatValue]];
        } seed:[NSNumber numberWithInt:0]];
        d.disk = [stats reduce:^id(id acc, id i) {
            NSString *disk = ((VMCInstanceStats *)i).disk;
            return [NSNumber numberWithFloat:[acc floatValue] + [disk floatValue]];
        } seed:[NSNumber numberWithInt:0]];
        return d;
    }];
}

- (NSArray *)getInstanceStatsForAppName:(NSString *)appname target:(Target *)target error:(NSError **)error {
    if (![self ensureTarget:target error:error])
        return nil;
    
    return [vmc getInstanceStatsForApp:appname];
    
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