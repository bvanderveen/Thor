#import "Log.h"
#import "SMWebRequest+RAC.h"
#import "NSObject+JSONDataRepresentation.h"

@implementation Log

+ (void)logError:(NSError *)error {
    [self log:@{
     @"code": [NSNumber numberWithInteger:error.code],
     @"domain": error.domain,
     @"userInfo": error.userInfo
     }];
}

+ (void)logMessage:(NSString *)message {
    [self log:@{@"message": message}];
}

+ (void)logFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    [self logMessage:str];
}

+ (void)log:(NSDictionary *)data {
    NSMutableDictionary *mutable = [data mutableCopy];
    mutable[@"GUID"] = [[NSProcessInfo processInfo] globallyUniqueString];
    NSData *d = [mutable JSONDataRepresentation];
    
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://logs.loggly.com/inputs/6e18413b-e18e-4039-8e8a-3398148c761e"]];
    urlRequest.HTTPMethod = @"POST";
    urlRequest.HTTPBody = d;
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSLog(@"Logging: %@", [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding]);
    
    [[SMWebRequest requestSignalWithURLRequest:urlRequest dataParser:nil] subscribeNext:^(id x) {
        NSLog(@"Logged. Response was %@", x);
    }];
}

@end
