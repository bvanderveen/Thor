#import "SMWebRequest.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SMWebRequest (RAC)

+ (id<RACSubscribable>)requestSubscribableWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(id))parser; 

@end
