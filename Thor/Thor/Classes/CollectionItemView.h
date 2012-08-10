
@interface CollectionItemViewButton : NSButton

@property (nonatomic, copy) NSString *label;

@end

@interface CollectionItemView : NSView

@property (nonatomic, strong) IBOutlet CollectionItemViewButton *button;

@end
