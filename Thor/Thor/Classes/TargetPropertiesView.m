#import "TargetPropertiesView.h"
#import "CollectionView.h"

@implementation TargetPropertiesView

@synthesize displayNameLabel, displayNameField, hostnameLabel, hostnameField, emailLabel, emailField, passwordLabel, passwordField, confirmButton, cancelButton, fieldContainer, buttonContainer;

- (NSSize)intrinsicContentSize {
   return NSMakeSize(500, 300);
}

@end
