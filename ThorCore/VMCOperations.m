#import "VMCOperations.h"

@implementation VMCInstanceStats

@synthesize ID, host, cpu, memory, disk, uptime;

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%@%@%@%@%@%@", ID, host, cpu, memory, disk, uptime] hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]])
        return NO;
    
    VMCInstanceStats *other = (VMCInstanceStats *)object;
    
    return 
        [other.ID isEqual:self.ID] &&
        [other.host isEqual:self.host] &&
        [other.cpu isEqual:self.cpu] &&
        [other.memory isEqual:self.memory] &&
        [other.disk isEqual:self.disk] &&
        [other.uptime isEqual:self.uptime];
}

@end

@implementation VMCApp

@synthesize name, uris;

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%@%@", name, uris] hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]])
        return NO;
    
    VMCApp *other = (VMCApp *)object;
    
    return 
        [other.name isEqual:self.name] &&
        [other.uris isEqual:self.uris];
}

@end

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

SynchronousExecuteShellBlock RVMExecute = ^ NSString * (NSString *command, NSArray *arguments) {
    NSArray *newArgs = [NSArray arrayWithObject:@"/Users/bvanderveen/.rvm/gems/ruby-1.9.2-p320@vmc-IronFoundry/bin/vmc"];
    newArgs = [newArgs arrayByAddingObjectsFromArray:arguments];
    
    return SynchronousExecuteShell(@"/Users/bvanderveen/.rvm/bin/ruby-1.9.2-p320@vmc-IronFoundry", newArgs);
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

- (NSArray *)rowStringsFromTableString:(NSString *)table {
    return [[[table componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] filter:^ BOOL (id line) { 
        return [line length] && ![[line substringToIndex:1] isEqual:@"+"];
    }] skip:1];
}

- (NSArray *)cellsFromRowString:(NSString *)row {
    return [[row componentsSeparatedByString:@"|"] map:^ id (id value) {
        return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }];
}

- (NSArray *)getApps {
    NSString *result = self.shellBlock([NSArray arrayWithObjects:@"apps", nil]);
    
    if ([result rangeOfString:@"No Applications"].location != NSNotFound)
        return [NSArray array];
    
    NSArray *rows = [self rowStringsFromTableString:result];
    return [rows map:^ id (id line) {
        NSArray *cells = [self cellsFromRowString:line];
        VMCApp *app = [VMCApp new];
        app.name = [cells objectAtIndex:1];
        app.uris = [[[cells objectAtIndex:4] componentsSeparatedByString:@","] map:^ id (id uri) { return [uri stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]; }];
        return app;
    }];
}

- (NSArray *)getInstanceStatsForApp:(NSString *)app {
    NSString *result = self.shellBlock([NSArray arrayWithObjects:@"stats", app, nil]);
    
    if ([result rangeOfString:@"Application Not Found"].location != NSNotFound)
        return nil;
    
    NSArray *rows = [self rowStringsFromTableString:result];
    return [rows map:^ id (id line) {
        NSArray *cells = [self cellsFromRowString:line];
        VMCInstanceStats *stats = [VMCInstanceStats new];
        stats.ID = [cells objectAtIndex:1];
        stats.cpu = [cells objectAtIndex:2];
        stats.memory = [cells objectAtIndex:3];
        stats.disk = [cells objectAtIndex:4];
        stats.uptime = [cells objectAtIndex:5];
        return stats;
    }];
}

@end
