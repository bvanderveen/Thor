
@interface DrawerBar : NSView

@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, strong) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *drawerView;

@end
