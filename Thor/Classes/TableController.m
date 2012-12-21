#import "TableController.h"
#import "NSObject+AssociateDisposable.h"

@implementation TableCell

@synthesize highlighted = _highlighted, label, imageView;

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    label.textColor = highlighted ? [NSColor whiteColor] : [NSColor textColor];
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        imageView = [[NSImageView alloc] initWithFrame:NSZeroRect];
        [self addSubview:imageView];
        
        label = [[NSTextField alloc] initWithFrame:NSZeroRect];
        label.bezeled = NO;
        label.drawsBackground = NO;
        label.editable = NO;
        label.selectable = NO;
        [self addSubview:label];
    }
    return self;
}

- (void)layout {
    [imageView sizeToFit];
    imageView.frame = NSMakeRect(10, (self.bounds.size.height - imageView.frame.size.height) / 2, imageView.frame.size.width, imageView.frame.size.height);
    
    [label sizeToFit];
    label.frame = NSMakeRect(10 + imageView.frame.size.width + 10, (self.bounds.size.height - label.frame.size.height) / 2, label.frame.size.width, label.frame.size.height);
    
    [super layout];
}

@end

@implementation TableItem

@synthesize view, selected;

@end

@interface TableSource ()

@property (nonatomic, strong) NSView *selectedView;
@property (nonatomic, copy) void (^selectionDidChange)();

@end

@implementation TableSource

@synthesize items, selectedView, selectionDidChange;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return items.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    TableItem *item = items[row];
    return item.view(tableView, tableColumn, row);
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    
    if ([selectedView respondsToSelector:@selector(setHighlighted:)])
        ((TableCell *)selectedView).highlighted = NO;
    
    selectedView = nil;
    
    if (proposedSelectionIndexes.count) {
        NSUInteger selectedIndex = [proposedSelectionIndexes firstIndex];
        ((TableItem *)items[selectedIndex]).selected();
        selectedView = [tableView viewAtColumn:0 row:selectedIndex makeIfNecessary:YES];
        
        if ([selectedView respondsToSelector:@selector(setHighlighted:)])
            ((TableCell *)selectedView).highlighted = YES;
    }
    
    return proposedSelectionIndexes;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (selectionDidChange)
        selectionDidChange();
}

@end

@implementation TableControllerView

@synthesize tableView, scrollView;

- (void)awakeFromNib {
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"ActivityColumn"];
    [tableView addTableColumn:column];

    tableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
}

@end

@implementation TableController

@synthesize source, controllerView;

- (id)initWithSubscribable:(RACSubscribable *)subscribable {
    if (self = [super initWithNibName:@"TableControllerView" bundle:[NSBundle mainBundle]]) {
        source = [[TableSource alloc] init];
        self.associatedDisposable = [subscribable subscribeNext:^ (id x) {
            source.items = (NSArray *)x;
            [controllerView.tableView reloadData];
            [controllerView.tableView sizeLastColumnToFit];
        } error:^(NSError *error) {
            [NSApp presentError:error];
            self.associatedDisposable = nil;
        } completed:^{
            self.associatedDisposable = nil;
        }];
    }
    return self;
}

- (void)awakeFromNib {
    controllerView.tableView.delegate = source;
    controllerView.tableView.dataSource = source;
}

@end

@interface WizardTableController ()

@property (nonatomic, copy) void (^commit)();
@property (nonatomic, copy) void (^rollback)();
@property (nonatomic, strong) TableController *tableController;

@end

@implementation WizardTableController

@synthesize title, commitButtonTitle, wizardController, commit, rollback, tableController;

- (id)initWithTableController:(TableController *)leTableController commitBlock:(void (^)())commitBlock rollbackBlock:(void (^)())rollbackBlock {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.tableController = leTableController;
        tableController.source.selectionDidChange = ^ {
            self.wizardController.commitButtonEnabled = self.tableController.controllerView.tableView.selectedRowIndexes.count > 0;
        };
        self.commit = commitBlock;
        self.rollback = rollbackBlock;
    }
    return self;
}

- (void)loadView {
    self.view = tableController.view;
    self.wizardController.commitButtonEnabled = NO;
}

- (void)commitWizardPanel {
    if (commit)
        commit();
}

- (void)rollbackWizardPanel {
    if (rollback)
        rollback();
}

@end
