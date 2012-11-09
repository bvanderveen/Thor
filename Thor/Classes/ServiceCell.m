#import "ServiceCell.h"
#import "NSFont+LineHeight.h"

@implementation ServiceCell

@synthesize service = _service;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
    }
    return self;
}

- (void)setService:(FoundryService *)service {
    _service = service;
    self.needsDisplay = YES;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSFont *nameFont = [NSFont boldSystemFontOfSize:12];
    
    [_service.name drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight, self.bounds.size.width, nameFont.lineHeight) withAttributes:@{
NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
     NSFontAttributeName : nameFont
     }];
    
    NSFont *memoryFont = [NSFont systemFontOfSize:12];
    [[NSString stringWithFormat:@"%@ - v%@", _service.vendor, _service.version] drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight - memoryFont.lineHeight, self.bounds.size.width, memoryFont.lineHeight) withAttributes:@{
                                                                                            NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
                                                                                                       NSFontAttributeName : memoryFont
     }];
}

@end