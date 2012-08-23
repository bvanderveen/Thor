#import "GridView.h"
#import "CollectionView.h"

@interface GridView ()

@property (nonatomic, copy) NSArray *gridRows;

@end

@interface GridRow : NSView

@property (nonatomic, copy) NSArray *cells;
@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, unsafe_unretained) GridView *gridView;

@end

@implementation GridRow

@synthesize cells = _cells, highlighted, gridView;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        //self.translatesAutoresizingMaskIntoConstraints = NO;
        //self.autoresizesSubviews = NO;
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
    }
    return self;
}

- (void)mouseEntered:(NSEvent *)theEvent {
    highlighted = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {
    highlighted = NO;
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
    [gridView.delegate gridView:gridView didSelectRowAtIndex:[gridView.gridRows indexOfObject:self] - 1];
}

- (void)cursorUpdate:(NSEvent *)event {
    [[NSCursor pointingHandCursor] set];
}

- (void)setCells:(NSArray *)cells {
    _cells = cells;
    
    for (NSView *v in cells) {
        [self addSubview:v];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    if (highlighted) {
        [[NSColor colorWithCalibratedRed:.84 green:.93 blue:.96 alpha:1] set];
        NSRectFill(self.bounds);
    }
    
    [[NSColor colorWithCalibratedWhite:.9 alpha:1] set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
}

@end

@implementation GridView

@synthesize delegate, dataSource, gridRows;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)reloadData {
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSUInteger columns = [dataSource numberOfColumnsForGridView:self];
    NSUInteger rows = [dataSource numberOfRowsForGridView:self];
    
    NSMutableArray *newGridRows = [NSMutableArray array];
    
    GridRow *header = [GridRow new];
    NSMutableArray *cells = [NSMutableArray array];
    for (int i = 0; i < columns; i++) {
        [cells addObject:[self headerViewForColumn:i]];
    }
    header.cells = cells;
    [newGridRows addObject:header];
    [self addSubview:header];
    
    for (int i = 0; i < rows; i++) {
        GridRow *r = [GridRow new];
        NSMutableArray *cells = [NSMutableArray array];
        for (int j = 0; j < columns; j++) {
            [cells addObject:[self viewForCellAtRow:i column:j]];
        }
        r.cells = cells;
        [newGridRows addObject:r];
        [self addSubview:r];
    }
    
    self.gridRows = newGridRows;
    [gridRows makeObjectsPerformSelector:@selector(setGridView:) withObject:self];
    [self setNeedsLayout:YES];
}

- (NSView *)headerViewForColumn:(NSUInteger)column {
    NSString *title = [dataSource gridView:self titleForColumn:column];
    NSTextField *label = [Label label];
    label.translatesAutoresizingMaskIntoConstraints = YES;
    //label.backgroundColor = [NSColor redColor];
    label.font = [NSFont systemFontOfSize:12];
    label.textColor = [NSColor colorWithCalibratedWhite:.66 alpha:1];
    label.stringValue = title;
    return label;
}

- (NSView *)viewForCellAtRow:(NSUInteger)row column:(NSUInteger)column {
    NSString *title = [dataSource gridView:self titleForRow:row column:column];
    NSTextField *label = [Label label];
    label.translatesAutoresizingMaskIntoConstraints = YES;
    //label.backgroundColor = [NSColor redColor];
    label.font = [NSFont boldSystemFontOfSize:12];
    label.textColor = [NSColor colorWithCalibratedWhite:.33 alpha:1];
    label.stringValue = title;
    return label;
}

- (CGFloat)widthOfColumn:(NSUInteger)column {
    // TODO make variable, memoize
    return 100;
}

- (CGFloat)rowHeight {
    return 30;
}

- (CGFloat)totalHeight {
    return [self rowHeight] * gridRows.count + 1;
}

- (CGSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, [self totalHeight]);
}

- (void)layout {
    CGFloat rowHeight = [self rowHeight];
    
    CGFloat y = 0;
    for (int i = 0; i < gridRows.count; i++) {
        GridRow *row = [gridRows objectAtIndex:i];
        
        assert([row superview] == self);
        row.frame = NSMakeRect(0, self.bounds.size.height - rowHeight * (i + 1), self.bounds.size.width, rowHeight);
        
        CGFloat x = 0;
        for (int j = 0; j < row.cells.count; j++) {
            NSTextField *cell = [row.cells objectAtIndex:j];
            CGFloat columnWidth = [self widthOfColumn:j];
            cell.frame = NSMakeRect(x, -5, columnWidth, rowHeight);
            x += columnWidth;
        }
        
        y += row.frame.size.height;
    }
    [super layout];
}

@end
