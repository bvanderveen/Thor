#import "ServiceCell.h"
#import "NSFont+LineHeight.h"

@implementation ServiceCell

@synthesize service = _service, button;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.button = [[NSButton alloc] initWithFrame:NSZeroRect];
        button.bezelStyle = NSTexturedRoundedBezelStyle;
        button.title = @"-";
        [self addSubview:button];
    }
    return self;
}

- (void)setService:(FoundryService *)service {
    _service = service;
    self.needsDisplay = YES;
}

- (void)layout {
    NSSize buttonSize = button.intrinsicContentSize;
    button.frame = NSMakeRect(self.bounds.size.width - buttonSize.width - 20, (self.bounds.size.height - buttonSize.height) / 2, buttonSize.width, buttonSize.height);
    [super layout];
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