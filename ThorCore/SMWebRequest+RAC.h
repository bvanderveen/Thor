#import "SMWebRequest.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface NSObject (SMWebRequestForResult)

@property (nonatomic, unsafe_unretained) SMWebRequest *associatedWebRequest;

@end

@interface SMWebRequest (RAC)

+ (RACSignal *)requestSignalWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(id))parser; 

@end
