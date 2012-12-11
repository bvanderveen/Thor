#import "ActivityController.h"
#import "NSFont+LineHeight.h"


@interface PushActivity : NSObject

@property (nonatomic, copy) NSString *localPath, *targetHostname, *targetAppName;

@end

@implementation PushActivity

@synthesize localPath, targetAppName, targetHostname;

@end

@interface ActivityCell : NSView

@property (nonatomic, strong) PushActivity *activity;
@property (nonatomic, assign) BOOL highlighted;

@end


@implementation ActivityCell

@synthesize activity = _activity, highlighted = _highlighted;

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    self.needsDisplay = YES;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
    }
    return self;
}

- (void)setActivity:(PushActivity *)activity {
    _activity = activity;
    self.needsDisplay = YES;
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
    [[NSString stringWithFormat:@"%@", _activity.localPath] drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight - memoryFont.lineHeight, self.bounds.size.width, memoryFont.lineHeight) withAttributes:@{
                                                                                            NSForegroundColorAttributeName : textColor,
                                                                                                       NSFontAttributeName : memoryFont
     }];
}

@end

@interface ActivityTableViewSource : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, copy) NSArray *activities; // of FoundryApp
@property (nonatomic, strong) ActivityCell *selectedCell;

@end

@implementation ActivityTableViewSource

@synthesize activities, selectedCell;

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
        tableView.rowHeight = 42;
        
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
        PushActivity *a = [[PushActivity alloc] init];
        a.localPath = @"/Users/bvanderveen/code/foo/whatever";
        a.targetHostname = @"api.bvanderveen.cloudfoundry.me";
        a.targetAppName = @"foowhatever";
        
        source.activities = @[ a ];
    }
    return self;
}

- (void)loadView {
    controllerView = [[ActivityControllerView alloc] initWithFrame:NSZeroRect];
    controllerView.tableView.delegate = source;
    controllerView.tableView.dataSource = source;
    
    self.view = controllerView;
}

@end
