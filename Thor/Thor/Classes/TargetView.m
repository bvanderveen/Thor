#import "TargetView.h"
#import "CollectionView.h"

@implementation TargetView

@synthesize infoBox, deploymentsBox, hostnameLabel, hostnameValueLabel, emailLabel, emailValueLabel, deploymentsGrid, editButton;

- (id)initWithTarget:(Target *)target {
    if (self = [super initWithFrame:NSMakeRect(0, 0, 100, 100)]) {
        //self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.infoBox = [[NSBox alloc] initWithFrame:NSZeroRect];
        infoBox.title = @"Cloud settings";
        infoBox.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:infoBox];
        
        self.hostnameLabel = [Label label];
        hostnameLabel.stringValue = @"Hostname";
        [infoBox.contentView addSubview:hostnameLabel];
        
        self.hostnameValueLabel = [Label label];
        hostnameValueLabel.stringValue = target.hostname;
        [infoBox.contentView addSubview:hostnameValueLabel];
        
        self.emailLabel = [Label label];
        emailLabel.stringValue = @"Email";
        [infoBox.contentView addSubview:emailLabel];
        
        self.emailValueLabel = [Label label];
        emailValueLabel.stringValue = target.email;
        [infoBox.contentView addSubview:emailValueLabel];
        
        self.editButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        editButton.translatesAutoresizingMaskIntoConstraints = NO;
        editButton.title = @"Edit settings…";
        editButton.bezelStyle = NSRoundedBezelStyle;
        [infoBox.contentView addSubview:editButton];
        
        self.deploymentsBox = [[NSBox alloc] initWithFrame:NSZeroRect];
        deploymentsBox.title = @"App Deployments";
        deploymentsBox.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:deploymentsBox];
        
        self.deploymentsGrid = [[GridView alloc] initWithFrame:NSZeroRect];
        
        [deploymentsBox.contentView addSubview:deploymentsGrid];
    }
    return self;
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
}

- (void)updateConstraints {
    NSDictionary *views = NSDictionaryOfVariableBindings(infoBox, deploymentsBox, hostnameLabel, hostnameValueLabel, emailLabel, emailValueLabel, editButton, deploymentsGrid);
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[infoBox]-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[deploymentsBox]-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[infoBox(==150)]-[deploymentsBox]" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    
    [infoBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[hostnameLabel]-[hostnameValueLabel]" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    [infoBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[emailLabel]-[emailValueLabel]" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    [infoBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[editButton]" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    [infoBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[hostnameLabel]-[emailLabel]-[editButton]" options:NSLayoutFormatAlignAllLeft metrics:nil views:views]];
    //    
    //    [deploymentsBox setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationVertical];
    //    [deploymentsBox setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    [deploymentsBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[deploymentsGrid]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    [deploymentsBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[deploymentsGrid]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    
    [hostnameValueLabel setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    [emailValueLabel setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    [super updateConstraints];
}

@end
