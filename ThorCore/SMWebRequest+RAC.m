#import "SMWebRequest+RAC.h"
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

@interface WebRequestBlockProducer : NSObject <SMWebRequestDelegate> {
    id (^parser)(NSData *);
    NSURLRequest *urlRequest;
    SMWebRequest *webRequest;
    id<RACSubscriber> subscriber;
}

- (id)initWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(NSData *))parser;

@end

@implementation WebRequestBlockProducer

- (id)initWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(NSData *))leParser  {
    if ((self = [super init])) {
        urlRequest = [request retain];
        parser = [leParser copy];
    }
    return self;
}

- (void)cancel {
    if (webRequest != nil) {
        //[[UIApplication sharedApplication] networkActivityDidEnd];
    }
    
    [webRequest cancel];
    [webRequest release];
    webRequest = nil;
}

- (void)dealloc {
    [self cancel];
    [urlRequest release];
    [parser release];
    [super dealloc];
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

- (RACSubscribable *)subscribable {
    return [RACSubscribable createSubscribable:^ RACDisposable * (id<RACSubscriber> s) {
        subscriber = [s retain];
        //[[UIApplication sharedApplication] networkActivityDidBegin];
        webRequest = [[SMWebRequest alloc] initWithURLRequest:urlRequest delegate:self context:nil];
        [webRequest start];
        return [RACDisposable disposableWithBlock:^ { [self cancel]; }];
    }];
}

@end

@implementation SMWebRequest (RAC)

+ (RACSubscribable *)requestSubscribableWithURLRequest:(NSURLRequest *)request dataParser:(id (^)(id))parser {
    WebRequestBlockProducer *p = [[WebRequestBlockProducer alloc] initWithURLRequest:request dataParser:parser];
    RACSubscribable *result = [p subscribable];
    [p release];
    return result;
}

@end
