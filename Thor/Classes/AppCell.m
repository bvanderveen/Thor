#import "AppCell.h"
#import "DeploymentMemoryTransformer.h"
#import "NSFont+LineHeight.h"

@implementation AppCell

@synthesize app = _app;

- (void)setApp:(FoundryApp *)app {
    _app = app;
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSFont *nameFont = [NSFont boldSystemFontOfSize:12];
    
    [_app.name drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight, self.bounds.size.width, nameFont.lineHeight) withAttributes:@{
NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
     NSFontAttributeName : nameFont
     }];
    
    NSFont *memoryFont = [NSFont systemFontOfSize:12];
    [[NSString stringWithFormat:@"%ld MB memory", _app.memory] drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight - memoryFont.lineHeight, self.bounds.size.width, memoryFont.lineHeight) withAttributes:@{
                                          NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
                                                     NSFontAttributeName : memoryFont
     }];
}

@end