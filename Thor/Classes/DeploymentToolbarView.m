#import "DeploymentToolbarView.h"
#import "NSFont+LineHeight.h"

@interface DeploymentToolbarButton : NSButton

@end

@implementation DeploymentToolbarButton

- (NSSize)intrinsicContentSize {
    return NSMakeSize(80, 30);
}

- (void)drawRect:(NSRect)dirtyRect {
    [self.image drawInRect:NSMakeRect(7, 7, 15, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    NSFont *titleFont = [NSFont boldSystemFontOfSize:11];
    [self.title drawInRect:NSMakeRect(30, (self.bounds.size.height - titleFont.lineHeight) / 2.0 - 1, self.bounds.size.width - 30, titleFont.lineHeight) withAttributes:@{
        NSForegroundColorAttributeName : [NSColor colorWithGenericGamma22White:1.0 alpha:1],
        NSFontAttributeName : titleFont
     }];
}

@end

@interface LeftButton : DeploymentToolbarButton

@end

@implementation LeftButton

- (void)drawRect:(NSRect)dirtyRect {
    [[NSImage imageNamed:@"ToolbarButton_topleft"] drawInRect:NSMakeRect(0, 15, 5, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"ToolbarButton_bottomleft"] drawInRect:NSMakeRect(0, 0, 5, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"ToolbarButton_topcenter"] drawInRect:NSMakeRect(5, 15, self.bounds.size.width, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"ToolbarButton_bottomcenter"] drawInRect:NSMakeRect(5, 0, self.bounds.size.width, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"ToolbarButton_divider"] drawInRect:NSMakeRect(self.bounds.size.width - 1, 0, 1, 30) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [super drawRect:dirtyRect];
}

@end

@interface CenterButton : DeploymentToolbarButton

@end

@implementation CenterButton

- (void)drawRect:(NSRect)dirtyRect {
    [[NSImage imageNamed:@"ToolbarButton_topcenter"] drawInRect:NSMakeRect(0, 15, self.bounds.size.width, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"ToolbarButton_bottomcenter"] drawInRect:NSMakeRect(0, 0, self.bounds.size.width, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"ToolbarButton_divider"] drawInRect:NSMakeRect(self.bounds.size.width - 1, 0, 1, 30) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [super drawRect:dirtyRect];
}

@end

@interface RightButton : DeploymentToolbarButton

@end

@implementation RightButton

- (void)drawRect:(NSRect)dirtyRect {
    [[NSImage imageNamed:@"ToolbarButton_topcenter"] drawInRect:NSMakeRect(0, 15, self.bounds.size.width, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"ToolbarButton_bottomcenter"] drawInRect:NSMakeRect(0, 0, self.bounds.size.width, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"ToolbarButton_topright.png"] drawInRect:NSMakeRect(self.bounds.size.width - 5, 15, 5, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [[NSImage imageNamed:@"ToolbarButton_bottomright.png"] drawInRect:NSMakeRect(self.bounds.size.width - 5, 0, 5, 15) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    
    [super drawRect:dirtyRect];
}

@end

@implementation DeploymentToolbarView

@synthesize startButton, stopButton, restartButton;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.startButton = [[LeftButton alloc] initWithFrame:CGRectZero];
        startButton.title = @"Start";
        startButton.image = [NSImage imageNamed:@"DeploymentStart"];
        [self addSubview:startButton];
        
        self.stopButton = [[CenterButton alloc] initWithFrame:CGRectZero];
        stopButton.title = @"Stop";
        stopButton.image = [NSImage imageNamed:@"DeploymentStop"];
        [self addSubview:stopButton];
        
        self.restartButton = [[RightButton alloc] initWithFrame:CGRectZero];
        restartButton.title = @"Restart";
        restartButton.image = [NSImage imageNamed:@"DeploymentRestart"];
        [self addSubview:restartButton];
    }
    return self;
}

- (void)layout {
    NSSize startButtonSize = [startButton intrinsicContentSize];
    self.startButton.frame = NSMakeRect(7, 7, startButtonSize.width, startButtonSize.height);
    
    NSSize stopButtonSize = [stopButton intrinsicContentSize];
    self.stopButton.frame = NSMakeRect(7 + startButtonSize.width, 7, stopButtonSize.width, stopButtonSize.height);
    
    NSSize restartButtonSize = [restartButton intrinsicContentSize];
    self.restartButton.frame = NSMakeRect(7 + startButtonSize.width + stopButtonSize.width, 7, restartButtonSize.width, restartButtonSize.height);
    
    [super layout];
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, 44);
}

- (void)drawRect:(NSRect)dirtyRect {
    NSImage *background = [NSImage imageNamed:@"CollectionViewBackground"];
    [[NSColor colorWithPatternImage:background] set];
    NSRectFill(dirtyRect);
}

@end
