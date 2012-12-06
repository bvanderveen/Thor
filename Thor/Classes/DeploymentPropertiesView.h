
@interface DeploymentPropertiesView : NSView

@property (nonatomic, strong) IBOutlet NSView *contentView;
@property (nonatomic, strong) IBOutlet NSView *nameLabel, *nameField;
@property (nonatomic, assign) BOOL nameHidden;

@end
