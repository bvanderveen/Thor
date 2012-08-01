#import "GridView.h"
#import "CollectionView.h"

@interface GridRow : NSView

@property (nonatomic, copy) NSArray *cells;

@end

@implementation GridRow

@synthesize cells = _cells;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        //self.translatesAutoresizingMaskIntoConstraints = NO;
        //self.autoresizesSubviews = NO;
    }
    return self;
}

- (void)setFrame:(NSRect)frameRect {
    NSLog(@"GridRow setFrame:%@", NSStringFromRect(frameRect));
    [super setFrame:frameRect];
}

- (void)setCells:(NSArray *)cells {
    _cells = cells;
    
    for (NSView *v in cells) {
        [self addSubview:v];
    }
}

@end

@interface GridView ()

@property (nonatomic, copy) NSArray *gridRows;

@end

@implementation GridView

@synthesize dataSource, gridRows;

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
    [self setNeedsLayout:YES];
}

- (NSView *)viewForCellAtRow:(NSUInteger)row column:(NSUInteger)column {
    NSString *title = [dataSource gridView:self titleForRow:row column:column];
    NSTextField *label = [Label label];
    label.translatesAutoresizingMaskIntoConstraints = YES;
    //label.backgroundColor = [NSColor redColor];
    label.stringValue = title;
    return label;
}

- (CGFloat)widthOfColumn:(NSUInteger)column {
    // TODO make variable, memoize
    return 100;
}

- (CGFloat)rowHeight {
    return 20;
}

- (CGFloat)totalHeight {
    return [self rowHeight] * gridRows.count;
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
        
        NSLog(@"row at %@", NSStringFromRect(row.frame));
        
        CGFloat x = 0;
        for (int j = 0; j < row.cells.count; j++) {
            NSTextField *cell = [row.cells objectAtIndex:j];
            CGFloat columnWidth = [self widthOfColumn:j];
            cell.frame = NSMakeRect(x, 0, columnWidth, rowHeight);
            NSLog(@"cell frame %@", NSStringFromRect(cell.frame));
            x += columnWidth;
        }
        
        y += row.frame.size.height;
    }
    [super layout];
}

@end
