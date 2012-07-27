#import "VMCOperations.h"
#import "Sequence.h"

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
    NSString *result = self.shellBlock([NSArray arrayWithObjects:@"apps", nil]);
    
    if ([result rangeOfString:@"No Applications"].location != NSNotFound)
        return [NSArray array];
    
    NSArray *lines = [result componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return [[[lines filter:^ BOOL (id line) { 
        return [line length] && ![[line substringToIndex:1] isEqual:@"+"];
    }] skip:1] map:^ id (id line) {
        NSLog(@"line %@", line);
        NSString *nameCellValue = [[line componentsSeparatedByString:@"|"] objectAtIndex:1];
        return [nameCellValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }];
    
}

- (DeploymentInfo *)getStatsForApp:(NSString *)app {
    return nil;
}

@end
