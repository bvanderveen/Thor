
@interface TargetPropertiesView : NSView

@property (nonatomic, strong) IBOutlet NSTextField 
    *windowLabel,
    *displayNameLabel,
    *displayNameField,
    *hostnameLabel,
    *hostnameField, 
    *emailLabel,
    *emailField, 
    *passwordLabel,
    *passwordField;

@property (nonatomic, strong) IBOutlet NSButton *confirmButton, *cancelButton;
@property (nonatomic, strong) IBOutlet NSView *fieldContainer, *buttonContainer;

@end
