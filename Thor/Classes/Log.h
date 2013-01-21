
@interface Log : NSObject

+ (void)logError:(NSError *)error;
+ (void)log:(NSDictionary *)data;
+ (void)logMessage:(NSString *)message;
+ (void)logFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);

@end
