#import "SMWebRequest+RAC.h"
#import <objc/runtime.h>

NSInteger AssociatedWebRequestKey;

@implementation NSObject (SMWebRequestForResult)

- (SMWebRequest *)associatedWebRequest {
    return objc_getAssociatedObject(self, &AssociatedWebRequestKey);
}

- (void)setAssociatedWebRequest:(SMWebRequest *)associatedWebRequest {
    objc_setAssociatedObject(self, &AssociatedWebRequestKey, associatedWebRequest, OBJC_ASSOCIATION_ASSIGN);
}

@end

//
//@interface UIApplication (NetworkActivity)
//
//- (void)networkActivityDidBegin;
//- (void)networkActivityDidEnd;
//
//@end
//
//static NSInteger count;
//
//@implementation UIApplication (NetworkActivity)
//
//- (void)networkActivityDidBegin {
//    if (++count == 1)
//        self.networkActivityIndicatorVisible = YES;
//    
//}
//- (void)networkActivityDidEnd {
//    
//    if (--count == 0)
//        self.networkActivityIndicatorVisible = NO;
//}
//
//@end

@interface WebRequestBlockProducer : NSObject <SMWebRequestDelegate>

@property (nonatomic, copy) id (^parser)(NSData *);
@property (nonatomic, strong) SMWebRequest *webRequest;
@property (nonatomic, strong) id<RACSubscriber> subscriber;

@end

@implementation WebRequestBlockProducer

@synthesize parser, webRequest, subscriber;

- (id)initWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(NSData *))leParser subscriber:(id<RACSubscriber>)leSubscriber {
    if ((self = [super init])) {
        parser = [leParser copy];
        subscriber = leSubscriber;
        webRequest = [[SMWebRequest alloc] initWithURLRequest:request delegate:self context:nil];
        [webRequest start];
    }
    return self;
}

- (void)cancel {
    [webRequest cancel];
    webRequest = nil;
}

- (void)dealloc {
    [self cancel];
}

- (NSURLRequest *)webRequest:(SMWebRequest *)webRequest willSendRequest:(NSURLRequest *)newRequest redirectResponse:(NSURLResponse *)redirectResponse {
    if (redirectResponse)
        return nil;
    else
        return newRequest;
}

- (id)webRequest:(SMWebRequest *)webRequest resultObjectForData:(NSData *)data context:(id)context {
    return parser ? parser(data) : data;
}

- (void)webRequest:(SMWebRequest *)webRequest didCompleteWithResult:(id)result context:(id)context {
    [self cancel];
    [subscriber sendNext:result];
    [subscriber sendCompleted];
}

- (void)webRequest:(SMWebRequest *)webRequest didFailWithError:(NSError *)error context:(id)context {
    [self cancel];
    [subscriber sendError:error];
}

@end

@implementation SMWebRequest (RAC)

+ (RACSignal *)requestSignalWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(id))parser {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        WebRequestBlockProducer *p = [[WebRequestBlockProducer alloc] initWithURLRequest:request dataParser:parser subscriber:subscriber];
        return [RACDisposable disposableWithBlock:^ { [p cancel]; }];
    }];
}

@end
