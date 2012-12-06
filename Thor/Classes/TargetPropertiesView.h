
@interface TargetPropertiesView : NSView

@property (nonatomic, strong) IBOutlet NSTextField
    *displayNameLabel,
    *displayNameField,
    *hostnameLabel,
    *hostnameField;

@property (nonatomic, strong) IBOutlet NSButton *confirmButton, *cancelButton;

@property (nonatomic, assign) BOOL nameAndHostnameHidden;

@end
