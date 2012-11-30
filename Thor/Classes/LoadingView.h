
@interface LoadingView : NSView

@property (nonatomic, strong) NSProgressIndicator *progressIndicator;

@end

@interface NSView (LoadingView)

- (void)showModalLoadingView;
- (void)hideLoadingView;

@end
