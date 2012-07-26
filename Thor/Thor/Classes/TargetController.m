#import "TargetController.h"
#import "CollectionView.h"

@interface TargetView : NSView

@property (nonatomic, strong) NSBox *infoBox, *deploymentsBox;
@property (nonatomic, strong) NSTextField *displayNameLabel, *displayNameValueLabel;
@property (nonatomic, strong) GridView *deploymentsGrid;

@end

@implementation TargetView

@synthesize infoBox, deploymentsBox, displayNameLabel, displayNameValueLabel, deploymentsGrid;

- (id)initWithTarget:(Target *)target {
    if (self = [super initWithFrame:NSMakeRect(0, 0, 100, 100)]) {
        //self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.infoBox = [[NSBox alloc] initWithFrame:NSZeroRect];
        infoBox.title = @"Cloud settings";
        infoBox.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:infoBox];
        
        self.displayNameLabel = [Label label];
        displayNameLabel.stringValue = @"Name";
        [infoBox.contentView addSubview:displayNameLabel];
        
        self.displayNameValueLabel = [Label label];
        displayNameValueLabel.stringValue = target.displayName;
        [infoBox.contentView addSubview:displayNameValueLabel];
        
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
    NSLog(@"target view frame %@", NSStringFromRect(frameRect));
    [super setFrame:frameRect];
}

- (void)updateConstraints {
    NSDictionary *views = NSDictionaryOfVariableBindings(infoBox, deploymentsBox, displayNameLabel, displayNameValueLabel, deploymentsGrid);
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[infoBox]-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[deploymentsBox]-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[infoBox(==150)]-[deploymentsBox]" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
    
    [infoBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[displayNameLabel]-[displayNameValueLabel]-|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    [infoBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[displayNameLabel]" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
//    
//    [deploymentsBox setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationVertical];
//    [deploymentsBox setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    [deploymentsBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[deploymentsGrid]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
    [deploymentsBox addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[deploymentsGrid]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    
    [displayNameValueLabel setContentHuggingPriority:NSLayoutPriorityDefaultLow - 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    [super updateConstraints];
}

@end

@interface TargetController ()

@property (nonatomic, strong) Target *target;
@property (nonatomic, strong) TargetView *targetView;

@end

@implementation TargetController

@synthesize target, targetView, breadcrumbController, title;

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (id)initWithTarget:(Target *)leTarget {
    //if (self = [super initWithNibName:@"TargetView" bundle:[NSBundle mainBundle]]) {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.target = leTarget;
        self.title = leTarget.displayName;
    }
    return self;
}

- (void)loadView {
    self.targetView = [[TargetView alloc] initWithTarget:target];
    self.targetView.deploymentsGrid.dataSource = self;
    [targetView.deploymentsGrid reloadData];
    
    self.view = targetView;
}

- (NSUInteger)numberOfColumnsForGridView:(GridView *)gridView {
    return 4;
}

- (NSString *)gridView:(GridView *)gridView titleForColumn:(NSUInteger)columnIndex {
    return [[NSArray arrayWithObjects:@"Name", @"CPU", @"Memory", @"Disk", nil] objectAtIndex:columnIndex];
}

- (NSUInteger)numberOfRowsForGridView:(GridView *)gridView {
    return 2;
}

- (NSString *)gridView:(GridView *)gridView titleForRow:(NSUInteger)row column:(NSUInteger)columnIndex {
    return [[[NSArray arrayWithObjects:
               [NSArray arrayWithObjects:@"Soap Store", @"33%", @"2 GB", @"600MB", nil],
               [NSArray arrayWithObjects:@"Project Mayhem", @"25%", @"512 MB", @"250MB", nil], 
               nil] objectAtIndex:row] objectAtIndex:columnIndex]; 
}

@end
