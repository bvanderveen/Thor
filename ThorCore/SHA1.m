#import "SHA1.h"
#import <CommonCrypto/CommonCrypto.h>

NSString *CalculateSHA1OfFileAtPath(NSURL *path) {
    NSInputStream *input = [[NSInputStream alloc] initWithURL:path];
    
    [input open];
    
    CC_SHA1_CTX ctx;
    CC_SHA1_Init(&ctx);
    
    NSUInteger bufferSize = 1020 * 4;
    uint8_t buffer[bufferSize];
    
    while (true) {
        NSInteger read = [input read:buffer maxLength:bufferSize];
        
        if (read <= 0)
            break;
        
        CC_SHA1_Update(&ctx, buffer, (CC_LONG)read);
    }
    
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1_Final(digest, &ctx);
    
    [input close];
    
    NSMutableString *result = [NSMutableString stringWithCapacity:sizeof(digest) * 2];
    for (int i = 0; i < sizeof(digest); i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    
    return [result copy];
}