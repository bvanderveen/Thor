#import "ActivityController.h"
#import "NSFont+LineHeight.h"
#import "NSObject+AssociateDisposable.h"
#import "ThorCore.h"

@implementation PushActivity

@synthesize status, localPath, targetAppName, targetHostname, isActive;

- (id)initWithSubscribable:(RACSubscribable *)subscribable {
    if (self = [super init]) {
        self.isActive = YES;
        self.associatedDisposable = [subscribable subscribeNext:^(id x) {
            self.status = FoundryPushStageString([(NSNumber *)x intValue]);
        } error:^(NSError *error) {
            self.status = @"Error";
            [NSApp presentError:error];
            self.associatedDisposable = nil;
            self.isActive = NO;
        } completed:^{
            self.associatedDisposable = nil;
            self.isActive = NO;
        }];
    }
    return self;
}

@end

@interface ActivityCell : NSView

@property (nonatomic, strong) PushActivity *activity;
@property (nonatomic, assign) BOOL highlighted, isAnimating;
@property (nonatomic, strong) NSProgressIndicator *indicator;
@property (nonatomic, strong) NSString *status;

@end


@implementation ActivityCell

@synthesize activity = _activity, highlighted = _highlighted, indicator, status = _status, isAnimating = _isAnimating;

- (void)resetIndicator {
    [indicator stopAnimation:self];
    indicator.indeterminate = NO;
    indicator.doubleValue = 100.0;
}
- (void)setStatus:(NSString *)status {
    _status = status;
    self.needsDisplay = YES;
}

- (void)setIsAnimating:(BOOL)isAnimating {
    _isAnimating = isAnimating;
    
    if (isAnimating) {
        indicator.indeterminate = YES;
        [indicator startAnimation:self];
    }
    else {
        [self resetIndicator];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    self.needsDisplay = YES;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        indicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
        indicator.style = NSProgressIndicatorBarStyle;
        indicator.controlSize = NSSmallControlSize;
        [self resetIndicator];
        [self addSubview:indicator];
        
    }
    return self;
}

- (void)setActivity:(PushActivity *)activity {
    _activity = activity;
    [self bind:@"status" toObject:activity withKeyPath:@"status" options:nil];
    [self bind:@"isAnimating" toObject:activity withKeyPath:@"isActive" options:nil];
    self.needsDisplay = YES;
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    self.needsLayout = YES;
}

- (void)layout {
    [indicator sizeToFit];
    indicator.frame = NSMakeRect(10, 10, self.bounds.size.width - 20, indicator.frame.size.height);
    [super layout];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSFont *nameFont = [NSFont boldSystemFontOfSize:12];
    NSColor *textColor = self.highlighted ? [NSColor whiteColor] : [NSColor colorWithGenericGamma22White:.20 alpha:1];
    
    [[NSString stringWithFormat:@"%@ - %@", _activity.targetHostname, _activity.targetAppName] drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight, self.bounds.size.width, nameFont.lineHeight) withAttributes:@{
        NSForegroundColorAttributeName : textColor,
        NSFontAttributeName : nameFont
     }];
    
    NSFont *memoryFont = [NSFont systemFontOfSize:12];
    [[NSString stringWithFormat:@"%@ - %@", _activity.localPath, self.status] drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight - memoryFont.lineHeight, self.bounds.size.width, memoryFont.lineHeight) withAttributes:@{NSForegroundColorAttributeName : textColor, NSFontAttributeName : memoryFont}];
}

@end

@interface ActivityTableViewSource : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, copy) NSArray *activities; // of FoundryApp
@property (nonatomic, strong) ActivityCell *selectedCell;

@end

@implementation ActivityTableViewSource

@synthesize activities, selectedCell;

- (id)init {
    if (self = [super init]) {
        self.activities = @[];
    }
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return activities.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    ActivityCell *cell = [[ActivityCell alloc] initWithFrame:NSZeroRect];
    
    cell.activity = activities[row];
    
    return cell;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    selectedCell.highlighted = NO;
    selectedCell = nil;
    
    if (proposedSelectionIndexes.count) {
        selectedCell = (ActivityCell *)[tableView viewAtColumn:0 row:[proposedSelectionIndexes firstIndex] makeIfNecessary:YES];
        selectedCell.highlighted = YES;
    }
    
    return proposedSelectionIndexes;
}

@end

@interface ActivityControllerView : NSView

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSScrollView *scrollView;

@end

@implementation ActivityControllerView

@synthesize tableView, scrollView;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        tableView = [[NSTableView alloc] initWithFrame:frameRect];
        tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
        tableView.headerView = nil;
        tableView.rowHeight = 60;
        
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"ActivityColumn"];
        [tableView addTableColumn:column];
        
        scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
        scrollView.documentView = tableView;
        
        [self addSubview:scrollView];
    }
    return self;
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    self.needsLayout = YES;
}

- (void)layout {
    scrollView.frame = self.bounds;
    [super layout];
}

@end

@interface ActivityController ()

@property (nonatomic, strong) ActivityTableViewSource *source;
@property (nonatomic, strong) ActivityControllerView *controllerView;

@end

@implementation ActivityController

@synthesize source, controllerView;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        source = [[ActivityTableViewSource alloc] init];
    }
    return self;
}

- (void)loadView {
    controllerView = [[ActivityControllerView alloc] initWithFrame:NSZeroRect];
    controllerView.tableView.delegate = source;
    controllerView.tableView.dataSource = source;
    
    self.view = controllerView;
}

- (void)insert:(PushActivity *)activity {
    source.activities = [source.activities arrayByAddingObject:activity];
    [controllerView.tableView reloadData];
}

@end
