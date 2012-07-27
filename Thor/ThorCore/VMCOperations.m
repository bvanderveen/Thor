#import "VMCOperations.h"

SynchronousExecuteShellBlock SynchronousExecuteShell = ^ NSString * (NSString *command, NSArray *arguments) {
    NSTask *task = [NSTask new];
    task.launchPath = command;
    task.arguments = arguments;
    
    NSPipe *outputPipe = [NSPipe pipe];
    task.standardOutput = outputPipe;
    
    NSFileHandle *outputHandle = outputPipe.fileHandleForReading;
    
    [task launch];
    
    NSData *outputData = [outputHandle readDataToEndOfFile];
    
    return [[NSString alloc] initWithData:outputData encoding:NSASCIIStringEncoding];
};


@interface VMCOperationsImpl ()

@property (nonatomic, copy) NSString * (^shellBlock)(NSArray *);

@end

@implementation VMCOperationsImpl

@synthesize shellBlock;

- (id)initWithShellBlock:(SynchronousExecuteShellBlock)leShellBlock {
    if (self = [super init]) {
        self.shellBlock = ^ NSString * (NSArray *args) {
            return leShellBlock(@"vmc", [args arrayByAddingObject:@"--non-interactive"]);
        };
    }
    return self;
}

- (BOOL)targetHostname:(NSString *)target {
    NSString *result = self.shellBlock([NSArray arrayWithObjects:@"target",
                                                target, nil]);
    
    return [result rangeOfString:@"Successfully targeted to"].location != NSNotFound;
}


- (BOOL)loginWithEmail:(NSString *)email password:(NSString *)password {
    NSString *result = self.shellBlock([NSArray arrayWithObjects:@"login", 
                                                @"--email", email,
                                                @"--password", password,
                                                nil]);
    
    return [result rangeOfString:@"Successfully logged into"].location != NSNotFound;
}

- (NSArray *)getApps {
    return nil;
}

- (DeploymentInfo *)getStatsForApp:(NSString *)app {
    return nil;
}

@end
