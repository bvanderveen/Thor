
@interface ToolbarTabController : NSObject <NSToolbarDelegate>

@property (nonatomic, strong) NSToolbar *toolbar;
@property (nonatomic, strong, readonly) NSView *view;

@end
