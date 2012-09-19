#import "ListView.h"

@interface ListCell ()

@property (nonatomic, unsafe_unretained) ListView *listView;
@property (nonatomic, strong) NSTrackingArea *trackingArea;

@end

@interface ListView ()

@property (nonatomic, copy) NSArray *cells;

@end

@implementation ListView

@synthesize dataSource, delegate, rowHeight, cells;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.rowHeight = 35;
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self; 
}

- (void)reloadData {
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSUInteger rows = [dataSource numberOfRowsForListView:self];
    
    NSMutableArray *newCells = [NSMutableArray array];
    for (int i = 0; i < rows; i++) {
        ListCell *cell = [dataSource listView:self cellForRow:i];
        cell.listView = self;
        [newCells addObject:cell];
        [self addSubview:cell];
    }
    self.cells = newCells;
    self.needsLayout = YES;
}

- (void)layout {
    for (int i = 0; i < cells.count; i++) {
        NSView *cell = [self.cells objectAtIndex:i];
        cell.frame = NSMakeRect(0, self.bounds.size.height - rowHeight * (i + 1), self.bounds.size.width, rowHeight);
    }
    [super layout];
}

- (CGSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoInstrinsicMetric, self.cells.count * rowHeight);
}

@end

@implementation ListCell

@synthesize selectable = _selectable, highlighted, listView, trackingArea;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.selectable = YES;
    }
    return self;
}

- (void)setSelectable:(BOOL)selectable {
    _selectable = selectable;
    
    if (selectable) {
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited | NSTrackingCursorUpdate | NSTrackingInVisibleRect | NSTrackingActiveInKeyWindow owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
    } else {
        [self removeTrackingArea:trackingArea];
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
    [listView.delegate listView:listView didSelectRowAtIndex:[listView.cells indexOfObject:self]];
}

- (void)cursorUpdate:(NSEvent *)event {
    if (_selectable)
        [[NSCursor pointingHandCursor] set];
    else
        [[NSCursor arrowCursor] set];
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
