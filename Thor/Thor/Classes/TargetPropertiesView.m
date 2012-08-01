#import "TargetPropertiesView.h"
#import "CollectionView.h"

@implementation TargetPropertiesView

@synthesize displayNameLabel, displayNameField, hostnameLabel, hostnameField, emailLabel, emailField, passwordLabel, passwordField, confirmButton, cancelButton, fieldContainer, buttonContainer;

- (NSTextField *)createLabel {
    NSTextField *result = [Label label];
    [fieldContainer addSubview:result];
    return result;
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        //self.autoresizingMask = NSViewWidthSizable;
        //self.autoresizesSubviews = NO;
        //self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.fieldContainer = [[NSView alloc] initWithFrame:NSZeroRect];
        fieldContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:fieldContainer];
        
        self.buttonContainer = [[NSView alloc] initWithFrame:NSZeroRect];
        buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:buttonContainer];
        
        self.displayNameLabel = [self createLabel];
        displayNameLabel.stringValue = @"Name";
        [fieldContainer addSubview:displayNameLabel];
        
        self.displayNameField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        displayNameField.translatesAutoresizingMaskIntoConstraints = NO;
        [displayNameField.cell setPlaceholderString:@"My app"];
        [fieldContainer addSubview:displayNameField];
        
        self.hostnameLabel = [self createLabel];
        hostnameLabel.stringValue = @"Host";
        [fieldContainer addSubview:hostnameLabel];
        
        self.hostnameField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        hostnameField.translatesAutoresizingMaskIntoConstraints = NO;
        [hostnameField.cell setPlaceholderString:@"api.myhost.com"];
        [fieldContainer addSubview:hostnameField];
        
        self.emailLabel = [self createLabel];
        emailLabel.stringValue = @"Email";
        [fieldContainer addSubview:emailLabel];
        
        self.emailField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        emailField.translatesAutoresizingMaskIntoConstraints = NO;
        [emailField.cell setPlaceholderString:@"Email"];
        [fieldContainer addSubview:emailField];
        
        self.passwordLabel = [self createLabel];
        passwordLabel.stringValue = @"Password";
        [fieldContainer addSubview:passwordLabel];
        
        self.passwordField = [[NSSecureTextField alloc] initWithFrame:NSZeroRect];
        passwordField.translatesAutoresizingMaskIntoConstraints = NO;
        [passwordField.cell setPlaceholderString:@"Password"];
        [fieldContainer addSubview:passwordField];
        
        self.confirmButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
        confirmButton.bezelStyle = NSRoundedBezelStyle;
        confirmButton.keyEquivalent = @"\r";
        confirmButton.title = @"Add Cloud";
        [buttonContainer addSubview:confirmButton];
        
        self.cancelButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
        cancelButton.keyEquivalent = @"\e";
        cancelButton.title = @"Cancel";
        cancelButton.bezelStyle = NSRoundedBezelStyle;
        [buttonContainer addSubview:cancelButton];
    }
    return self;
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(500, 300);
}

- (void)updateConstraints {
    NSDictionary *views = NSDictionaryOfVariableBindings(displayNameLabel, displayNameField, hostnameLabel, hostnameField, emailLabel, emailField, passwordLabel, passwordField, cancelButton, confirmButton, fieldContainer, buttonContainer);
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[displayNameLabel(==100)]-[displayNameField(>=100)]-|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    [fieldContainer addConstraints:constraints];
    [fieldContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[hostnameLabel(==100)]-[hostnameField(>=100)]-|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    
    [fieldContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[emailLabel(==100)]-[emailField(>=100)]-|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    [fieldContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[passwordLabel(==100)]-[passwordField(>=100)]-|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    
    [displayNameField setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    [hostnameField setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    [emailField setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    [passwordField setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    [fieldContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[displayNameLabel]-[hostnameLabel]-[emailLabel]-[passwordLabel]-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [buttonContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=100)-[cancelButton]-[confirmButton]-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[fieldContainer]-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[buttonContainer]-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[fieldContainer]-[buttonContainer]-|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views]];
    
    
    [super updateConstraints];
}

@end
