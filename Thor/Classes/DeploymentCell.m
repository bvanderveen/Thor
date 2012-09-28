#import "DeploymentCell.h"
#import "NSFont+LineHeight.h"

@implementation DeploymentCell

@synthesize deployment, pushButton;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.pushButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        pushButton.title = @"Push";
        pushButton.bezelStyle = NSTexturedRoundedBezelStyle;
        
        [self addSubview:pushButton];
    }
    return self;
}

- (void)layout {
    NSSize buttonSize = pushButton.intrinsicContentSize;
    pushButton.frame = NSMakeRect(self.bounds.size.width - buttonSize.width - 20, (self.bounds.size.height - buttonSize.height) / 2, buttonSize.width, buttonSize.height);
    [super layout];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSImage *icon = [NSImage imageNamed:@"DeploymentIconSelected.png"];
    
    [icon drawAtPoint:NSMakePoint(10, 5) fromRect:NSMakeRect(0, 0, icon.size.width, icon.size.height) operation:NSCompositeSourceOver fraction:1];
    
    NSFont *titleFont = [NSFont boldSystemFontOfSize:12];
    
    [[NSString stringWithFormat:@"%@", deployment.target.displayName] drawInRect:NSMakeRect(85, self.bounds.size.height - titleFont.lineHeight - 8, self.bounds.size.width, titleFont.lineHeight) withAttributes:@{
                                                                              NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
                                                                                         NSFontAttributeName : titleFont
     }];
    
    NSFont *subtitleFont = [NSFont systemFontOfSize:12];
    [deployment.appName drawInRect:NSMakeRect(85, self.bounds.size.height - titleFont.lineHeight - subtitleFont.lineHeight - 8, self.bounds.size.width, subtitleFont.lineHeight) withAttributes:@{
   NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:.20 alpha:1],
              NSFontAttributeName : subtitleFont
     }];
}

@end