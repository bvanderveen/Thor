#import "AppsView.h"

@implementation AppsView

@synthesize apps, delegate, bar;

- (id)initWithApps:(NSArray *)lesApps {
    if (self = [super initWithFrame:NSZeroRect]) {
        self.apps = [NSMutableArray array];
        
        for (App *app in lesApps) {
            NSButton *button = [[NSButton alloc] initWithFrame:NSZeroRect];
            [button setTitle:app.displayName];
            [apps addObject:button];
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
    for (NSButton *b in apps) {
        b.frame = NSMakeRect(x, self.bounds.size.height - 10 - 100, 100, 100);
        x += 120;
    }
    
    bar.frame = NSMakeRect(0, 0, self.bounds.size.width, bar.intrinsicContentSize.height);
    [super layout];
}

- (void)buttonClicked:(NSButton *)button {
    [delegate performSelector:@selector(clickedAppNamed:) withObject:button.title];
}


@end
