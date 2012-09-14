#import "NSOutputStream+Writing.h"

@implementation NSOutputStream (Writing)

- (void)writeData:(NSData *)data {
    int bufferSize = 1024 * 4;
    uint8_t buffer[bufferSize];
    
    NSUInteger bytesCopied = 0;
    
    while (bytesCopied < data.length) {
        NSUInteger bytesToCopy = MIN(bufferSize, data.length - bytesCopied);
        [data getBytes:buffer length:bytesToCopy];
        
        int bytesWritten = 0;
        while (bytesWritten < bytesToCopy)
        {
            bytesWritten += [self write:(&buffer)[bytesWritten] maxLength:bytesToCopy - bytesWritten];
        }
        
        bytesCopied += bytesToCopy;
    }
}

- (void)writeString:(NSString *)string {
    [self writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)writeStream:(NSInputStream *)stream {
    NSInteger bytesRead = 0;
    int bufferSize = 1024 * 4;
    uint8_t buffer[bufferSize];
    
    while (true) {
        
        bytesRead = [stream read:(&buffer)[bytesRead] maxLength:bufferSize];
        
        if (bytesRead <= 0)
            break;
        
        int bytesWritten = 0;
        while (bytesWritten < bytesRead)
        {
            bytesWritten += [self write:(&buffer)[bytesWritten] maxLength:bytesRead - bytesWritten];
        }
    }

}

@end
