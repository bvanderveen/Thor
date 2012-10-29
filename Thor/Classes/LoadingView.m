#import "LoadingView.h"

#define LOADING_VIEW_TAG 0x10ad

@interface LoadingView : NSView

@property (nonatomic, strong) NSProgressIndicator *progressIndicator;

@end

@implementation LoadingView

@synthesize progressIndicator;

- (NSInteger)tag {
    return LOADING_VIEW_TAG;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
        progressIndicator.style = NSProgressIndicatorSpinningStyle;
        [self addSubview:progressIndicator];
    }
    return self;
}

- (void)layout {
    NSSize indicatorSize = progressIndicator.intrinsicContentSize;
    
    progressIndicator.frame = NSMakeRect((self.bounds.size.width - indicatorSize.width) / 2, (self.bounds.size.height - indicatorSize.height) / 2, indicatorSize.width, indicatorSize.height);

    [super layout];
}

@end


@implementation NSView (LoadingView)

- (void)showModalLoadingView {
    LoadingView *loadingView = [[LoadingView alloc] initWithFrame:self.frame];
    [loadingView.progressIndicator startAnimation:self];
    self.hidden = YES;
    [self.superview addSubview:loadingView];
}

- (void)hideLoadingView {
    LoadingView *loadingView = (LoadingView *)[self.superview viewWithTag:LOADING_VIEW_TAG];
    [loadingView.progressIndicator stopAnimation:self];
    self.hidden = NO;
    [loadingView removeFromSuperview];
}

@end
