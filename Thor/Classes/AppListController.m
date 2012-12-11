#import "AppListController.h"
#import "NSObject+AssociateDisposable.h"
#import "AppCell.h"
#import "AppDelegate.h"

@interface FoundryAppTableViewSource : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, copy) NSArray *apps; // of FoundryApp
@property (nonatomic, strong) AppCell *selectedCell;

@end

@implementation FoundryAppTableViewSource

@synthesize apps, selectedCell;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return apps.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    AppCell *cell = [[AppCell alloc] initWithFrame:NSZeroRect];
    
    cell.app = apps[row];
    
    return cell;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    selectedCell.highlighted = NO;
    selectedCell = nil;
    
    if (proposedSelectionIndexes.count) {
        selectedCell = (AppCell *)[tableView viewAtColumn:0 row:[proposedSelectionIndexes firstIndex] makeIfNecessary:YES];
        selectedCell.highlighted = YES;
        ((AppDelegate *)[NSApplication sharedApplication].delegate).selectedAppName = selectedCell.app.name;
    }
    
    return proposedSelectionIndexes;
}

@end

@interface AppListView : NSView

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSScrollView *scrollView;

@end

@implementation AppListView

@synthesize tableView, scrollView;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        tableView = [[NSTableView alloc] initWithFrame:NSZeroRect];
        tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
        tableView.headerView = nil;
        tableView.rowHeight = 50;
        
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"AppColumn"];
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

@interface AppListController ()

@property (nonatomic, strong) AppListView *controllerView;
@property (nonatomic, strong) FoundryAppTableViewSource *appTableSource;
@property (nonatomic, strong) FoundryClient *client;

@end

@implementation AppListController

@synthesize controllerView, appTableSource, client;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.appTableSource = [[FoundryAppTableViewSource alloc] init];
    }
    return self;
}

- (void)setTarget:(Target *)target {
    _target = target;
    
    if (target) {
        self.client = [[FoundryClient alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:target]];
        
        self.associatedDisposable = [[client getApps] subscribeNext:^(id x) {
            self.appTableSource.apps = x;
            [self.controllerView.tableView reloadData];
        } error:^(NSError *error) {
            [NSApp presentError:error];
        } completed:^{
            
        }];
    }
}

- (void)loadView {
    self.controllerView = [[AppListView alloc] initWithFrame:NSZeroRect];
    controllerView.tableView.delegate = appTableSource;
    controllerView.tableView.dataSource = appTableSource;
    
    self.view = self.controllerView;
}

@end
