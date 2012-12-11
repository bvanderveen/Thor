#import "AppCell.h"
#import "DeploymentMemoryTransformer.h"
#import "NSFont+LineHeight.h"

@implementation AppCell

@synthesize app = _app, highlighted = _highlighted;

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    self.needsDisplay = YES;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
    }
    return self;
}

- (void)setApp:(FoundryApp *)app {
    _app = app;
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSFont *nameFont = [NSFont boldSystemFontOfSize:12];
    NSColor *textColor = self.highlighted ? [NSColor whiteColor] : [NSColor colorWithGenericGamma22White:.20 alpha:1];
    
    [_app.name drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight, self.bounds.size.width, nameFont.lineHeight) withAttributes:@{
NSForegroundColorAttributeName : textColor,
     NSFontAttributeName : nameFont
     }];
    
    NSFont *memoryFont = [NSFont systemFontOfSize:12];
    [[NSString stringWithFormat:@"%@ - %ld MB memory", _app.uris.count ? _app.uris[0] : @"no URIs", _app.memory] drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight - memoryFont.lineHeight, self.bounds.size.width, memoryFont.lineHeight) withAttributes:@{
                                          NSForegroundColorAttributeName : textColor,
                                                     NSFontAttributeName : memoryFont
     }];
}

@end