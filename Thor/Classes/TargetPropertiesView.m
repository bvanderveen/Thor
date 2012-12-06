#import "TargetPropertiesView.h"
#import "CollectionView.h"

@implementation TargetPropertiesView

@synthesize displayNameLabel, displayNameField, hostnameField, hostnameLabel, nameAndHostnameHidden = _nameAndHostnameHidden;

- (void)setNameAndHostnameHidden:(BOOL)value {
    _nameAndHostnameHidden = value;
    displayNameLabel.hidden = value;
    displayNameField.hidden = value;
    hostnameLabel.hidden = value;
    hostnameField.hidden = value;
}

- (NSSize)intrinsicContentSize {
   return NSMakeSize(480, 272);
}

@end
