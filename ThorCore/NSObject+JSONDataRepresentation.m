#import "NSObject+JSONDataRepresentation.h"
#import "SBJson.h"

@implementation NSObject (JSONDataRepresentation)

- (NSData *)JSONDataRepresentation {
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];    
    NSData *json = [writer dataWithObject:self];
    if (!json)
        NSLog(@"-JSONRepresentation failed. Error is: %@", writer.error);
    return json;
}


@end
