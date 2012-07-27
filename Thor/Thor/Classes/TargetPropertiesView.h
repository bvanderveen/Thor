
@interface AddTargetView : NSView

@property (nonatomic, strong) NSTextField 
    *displayNameLabel,
    *displayNameField,
    *hostnameLabel,
    *hostnameField, 
    *emailLabel,
    *emailField, 
    *passwordLabel,
    *passwordField;

@property (nonatomic, strong) NSButton *confirmButton, *cancelButton;
@property (nonatomic, strong) NSView *fieldContainer, *buttonContainer;

@end
