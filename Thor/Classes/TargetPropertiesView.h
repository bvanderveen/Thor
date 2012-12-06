
@interface TargetPropertiesView : NSView

@property (nonatomic, strong) IBOutlet NSTextField
    *hostnameLabel,
    *hostnameField;

@property (nonatomic, assign) BOOL hostnameHidden;

@end
