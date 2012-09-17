#import "ListView.h"

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
        NSView *cell = [dataSource listView:self viewForRow:i];
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
