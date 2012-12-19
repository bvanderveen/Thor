#import "GridView.h"
#import "Label.h"
#import "NoResultsCell.h"

@interface GridView ()

@property (nonatomic, copy) NSArray *gridRows;

@end

@interface GridRow : NSView

@property (nonatomic, copy) NSArray *cells;
@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, assign) BOOL selectable;
@property (nonatomic, unsafe_unretained) GridView *gridView;

@end

@implementation GridRow

@synthesize cells = _cells, selectable = _selectable, highlighted, gridView;

- (void)setSelectable:(BOOL)selectable {
    _selectable = selectable;
    
    if (selectable) {
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
    }
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
    if (_selectable)
        [[NSCursor pointingHandCursor] set];
    else
        [[NSCursor arrowCursor] set];
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
    
    NSMutableArray *newGridRows = [NSMutableArray array];
    NSUInteger rows = [dataSource numberOfRowsForGridView:self];
    if (!rows) {
        NoResultsCell *cell = [[NoResultsCell alloc] initWithFrame:NSZeroRect];
        [newGridRows addObject:cell];
        [self addSubview:cell];
    }
    else {
        NSUInteger columns = [dataSource numberOfColumnsForGridView:self];
        
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
            r.selectable = YES;
            r.gridView = self;
            NSMutableArray *cells = [NSMutableArray array];
            for (int j = 0; j < columns; j++) {
                [cells addObject:[dataSource gridView:self viewForRow:i column:j]];
            }
            r.cells = cells;
            [newGridRows addObject:r];
            [self addSubview:r];
        }
    }
    
    self.gridRows = newGridRows;
    self.needsLayout = YES;
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

- (CGFloat)widthOfColumn:(NSUInteger)column {
    // TODO make variable, memoize
    return [dataSource gridView:self widthOfColumn:column];
}

- (CGFloat)rowHeight {
    return 34;
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
        NSView *row = [gridRows objectAtIndex:i];
        
        assert([row superview] == self);
        row.frame = NSMakeRect(0, self.bounds.size.height - rowHeight * (i + 1), self.bounds.size.width, rowHeight);
        
        CGFloat x = 0;
        if ([row isKindOfClass:[GridRow class]]) {
            GridRow *gridRow = (GridRow *)row;
            for (int j = 0; j < gridRow.cells.count; j++) {
                NSView *cell = [gridRow.cells objectAtIndex:j];
                CGFloat columnWidth = [self widthOfColumn:j];
                CGFloat y = [cell isKindOfClass:[NSTextField class]] ? -7 : 1;
                CGFloat width = [cell isKindOfClass:[NSTextField class]] ? columnWidth : columnWidth - 10;
                CGFloat xAdjusted = [cell isKindOfClass:[NSTextField class]] ? x : x + 5;
                cell.frame = NSMakeRect(xAdjusted, y, width, rowHeight);
                x += columnWidth;
            }
        }
        
        y += row.frame.size.height;
    }
    [super layout];
}

@end

@implementation GridLabel

+ (GridLabel *)labelWithTitle:(NSString *)title {
    NSTextField *label = [Label label];
    ((NSTextFieldCell *)label.cell).lineBreakMode = NSLineBreakByTruncatingTail;
    label.translatesAutoresizingMaskIntoConstraints = YES;
    //label.backgroundColor = [NSColor redColor];
    label.font = [NSFont boldSystemFontOfSize:12];
    label.textColor = [NSColor colorWithCalibratedWhite:.33 alpha:1];
    label.stringValue = title == nil ? @"" : title;
    return (GridLabel *)label;

}

@end
