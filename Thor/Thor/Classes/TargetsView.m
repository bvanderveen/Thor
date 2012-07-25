#import "TargetsView.h"

@implementation TargetsView

@synthesize collectionView, delegate, bar;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.bar = [[BottomBar alloc] initWithFrame:NSZeroRect];
        self.bar.translatesAutoresizingMaskIntoConstraints = NO;
        [bar.barButton setTitle:@"Add cloud…"];
        [self addSubview:bar];
    }
    return self;
}

- (void)updateConstraints {
    NSDictionary *views = NSDictionaryOfVariableBindings(collectionView, bar);
    
    [self removeConstraints:self.constraints];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[collectionView]|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[bar]|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView][bar]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];
    
    
    [super updateConstraints];
}

- (void)buttonClicked:(NSButton *)button {
    [delegate performSelector:@selector(clickedTargetNamed:) withObject:button.title];
}


@end
