#import "TargetsView.h"

@implementation TargetsView

@synthesize targets, delegate, bar;

- (id)initWithTargets:(NSArray *)lesTargets {
    if (self = [super initWithFrame:NSZeroRect]) {
        self.targets = [NSMutableArray array];
        
        for (Target *t in lesTargets) {
            NSButton *button = [[NSButton alloc] initWithFrame:NSZeroRect];
            button.title = t.displayName;
            [targets addObject:button];
            [self addSubview:button];
            button.target = self;
            button.action = @selector(buttonClicked:);
        }
        
        self.bar = [[BottomBar alloc] initWithFrame:NSZeroRect];
        [bar.barButton setTitle:@"Add cloud…"];
        [self addSubview:bar];
        
        [self setNeedsLayout:YES];
    }
    return self;
}

- (void)layout {
    CGFloat x = 10;
    for (NSButton *b in targets) {
        b.frame = NSMakeRect(x, self.bounds.size.height - 10 - 100, 100, 100);
        x += 120;
    }
    
    bar.frame = NSMakeRect(0, 0, self.bounds.size.width, bar.intrinsicContentSize.height);
    [super layout];
}

- (void)buttonClicked:(NSButton *)button {
    [delegate performSelector:@selector(clickedTargetNamed:) withObject:button.title];
}


@end
