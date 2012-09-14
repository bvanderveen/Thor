
@interface NSOutputStream (Writing)

- (void)writeData:(NSData *)data;
- (void)writeString:(NSString *)string;
- (void)writeStream:(NSInputStream *)stream;

@end
