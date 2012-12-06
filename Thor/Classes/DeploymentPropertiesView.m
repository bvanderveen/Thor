#import "DeploymentPropertiesView.h"

@implementation DeploymentPropertiesView

@synthesize contentView, nameHidden = _nameHidden, nameLabel, nameField;

- (void)setNameHidden:(BOOL)value {
    _nameHidden = value;
    nameLabel.hidden = value;
    nameField.hidden = value;
}


- (NSSize)intrinsicContentSize {
    return NSMakeSize(480, 279);
}

@end
