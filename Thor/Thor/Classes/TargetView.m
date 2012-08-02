#import "TargetView.h"
#import "CollectionView.h"

@implementation TargetView

@synthesize infoBox, deploymentsBox, hostnameLabel, hostnameValueLabel, emailLabel, emailValueLabel, deploymentsGrid, editButton;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.deploymentsGrid = [[GridView alloc] initWithFrame:NSZeroRect];
    [deploymentsBox.contentView addSubview:deploymentsGrid];
}

- (void)updateConstraints {
    //hostnameLabel, hostnameValueLabel, emailLabel, emailValueLabel,
    NSDictionary *views = NSDictionaryOfVariableBindings(infoBox, deploymentsBox, deploymentsGrid);
    
    [self removeConstraints:self.constraints];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[infoBox]-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[deploymentsBox]-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[infoBox(==150)]-[deploymentsBox(>=150)]" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    
    [deploymentsBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[deploymentsGrid]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    [deploymentsBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[deploymentsGrid]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    
    [super updateConstraints];
}

@end
