#import "NSOutputStream+Writing.h"

@implementation NSOutputStream (Writing)

- (void)writeData:(NSData *)data {
    int bufferSize = 1024 * 4;
    uint8_t buffer[bufferSize];
    
    NSUInteger bytesCopied = 0;
    
    while (bytesCopied < data.length) {
        NSUInteger bytesToCopy = MIN(bufferSize, data.length - bytesCopied);
        [data getBytes:buffer range:NSMakeRange(bytesCopied, bytesToCopy)];
        
        int bytesWritten = 0;
        while (bytesWritten < bytesToCopy)
        {
            NSInteger written = [self write:(&buffer)[bytesWritten] maxLength:bytesToCopy - bytesWritten];
            bytesWritten += written;
        }
        
        bytesCopied += bytesToCopy;
    }
}

- (void)writeString:(NSString *)string {
    [self writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)writeStream:(NSInputStream *)stream {
    int bufferSize = 1024 * 4;
    uint8_t buffer[bufferSize];
    
    while (true) {
        NSInteger bytesRead = [stream read:&buffer maxLength:bufferSize];
        
        if (bytesRead == -1) {
            NSLog(@"Error while reading stream: %@", [stream.streamError localizedDescription]);
            break;
        }
        
        if (bytesRead == 0)
            break;
        
        int bytesWritten = 0;
        while (bytesWritten < bytesRead)
        {
            bytesWritten += [self write:(&buffer)[bytesWritten] maxLength:bytesRead - bytesWritten];
        }
    }

}

@end
