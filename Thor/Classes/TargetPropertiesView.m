#import "TargetPropertiesView.h"
#import "CollectionView.h"

@implementation TargetPropertiesView

@synthesize windowLabel, displayNameLabel, displayNameField, hostnameLabel, hostnameField, emailLabel, emailField, passwordLabel, passwordField, confirmButton, cancelButton, fieldContainer, buttonContainer;

- (NSSize)intrinsicContentSize {
   return NSMakeSize(480, 272);
}

@end
