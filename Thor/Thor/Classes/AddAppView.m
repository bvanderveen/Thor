#import "AddAppView.h"

@implementation AddAppView

@synthesize displayNameLabel, displayNameField, hostnameLabel, hostnameField, emailLabel, emailField, passwordLabel, passwordField;

- (NSTextField *)createLabel {
    NSTextField *result = [[NSTextField alloc] initWithFrame:NSZeroRect];
    result.editable = NO;
    result.bordered = NO;
    result.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:result];
    return result;
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        //self.autoresizingMask = NSViewWidthSizable;
        //        self.autoresizesSubviews = NO;
        //self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.displayNameLabel = [self createLabel];
        displayNameLabel.stringValue = @"Name";
        [self addSubview:displayNameLabel];
        
        self.displayNameField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        displayNameField.translatesAutoresizingMaskIntoConstraints = NO;
        [displayNameField.cell setPlaceholderString:@"My app"];
        displayNameField.editable = YES;
        [self addSubview:displayNameField];
        
        self.hostnameLabel = [self createLabel];
        hostnameLabel.stringValue = @"Host";
        [self addSubview:hostnameLabel];
        
        self.hostnameField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        hostnameField.translatesAutoresizingMaskIntoConstraints = NO;
        [hostnameField.cell setPlaceholderString:@"api.myhost.com"];
        [self addSubview:hostnameField];
        
        self.emailLabel = [self createLabel];
        emailLabel.stringValue = @"Email";
        [self addSubview:emailLabel];
        
        self.emailField = [[NSTextField alloc] initWithFrame:NSZeroRect];
        emailField.translatesAutoresizingMaskIntoConstraints = NO;
        [emailField.cell setPlaceholderString:@"Email"];
        [self addSubview:emailField];
        
        self.passwordLabel = [self createLabel];
        passwordLabel.stringValue = @"Password";
        [self addSubview:passwordLabel];
        
        self.passwordField = [[NSSecureTextField alloc] initWithFrame:NSZeroRect];
        passwordField.translatesAutoresizingMaskIntoConstraints = NO;
        [passwordField.cell setPlaceholderString:@"Password"];
        [self addSubview:passwordField];
        
    }
    return self;
}

- (void)updateConstraints {
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(displayNameLabel, displayNameField, hostnameLabel, hostnameField, emailLabel, emailField, passwordLabel, passwordField);
    
    [self removeConstraints:self.constraints];
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[displayNameLabel(==100)]-[displayNameField(>=20)]-|" options:NSLayoutFormatAlignAllTop metrics:nil views:views];
    [self addConstraints:constraints];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[hostnameLabel(==100)]-[hostnameField(>=20)]-|" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[emailLabel(==100)]-[emailField(>=20)]-|" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[passwordLabel(==100)]-[passwordField(>=20)]-|" options:NSLayoutFormatAlignAllTop metrics:nil views:views]];
    
    [self.displayNameField setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.hostnameField setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.emailField setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    [self.passwordField setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[displayNameLabel]-[hostnameLabel]-[emailLabel]-[passwordLabel]-(>=20)-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    
    [super updateConstraints];
}

@end
