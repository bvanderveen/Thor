#import "AddItemListViewSource.h"
#import "NSFont+LineHeight.h"

@interface AddItemCell : ListCell

@property (nonatomic, copy) NSString *title;

@end

@implementation AddItemCell

@synthesize title;

- (id)initWithTitle:(NSString *)leTitle {
    if (self = [super initWithFrame:NSZeroRect]) {
        self.title = leTitle;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSCenterTextAlignment;
    NSFont *font = [NSFont boldSystemFontOfSize:12];
    [title drawInRect:NSMakeRect(0, (self.bounds.size.height - font.lineHeight) / 2 + 2, self.bounds.size.width, font.lineHeight) withAttributes:@{
   NSForegroundColorAttributeName : [NSColor colorWithCalibratedWhite:.2 alpha:1],
              NSFontAttributeName : font,
    NSParagraphStyleAttributeName : style
     }];
}

@end

@interface AddItemListViewSource ()

@property (nonatomic, copy) NSString *title;

@end

@implementation AddItemListViewSource

@synthesize source, action, title;

- (id)initWithTitle:(NSString *)leTitle {
    if (self = [super init]) {
        self.title = leTitle;
    }
    return self;
}

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    return [source numberOfRowsForListView:listView] + 1;
}

- (BOOL)rowInListView:(ListView *)listView isWrappedCell:(NSUInteger)row {
    return row < [source numberOfRowsForListView:listView];
}

- (ListCell *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    return [self rowInListView:listView isWrappedCell:row] ?
    [source listView:listView cellForRow:row] :
    [[AddItemCell alloc] initWithTitle:title];
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    if ([self rowInListView:listView isWrappedCell:row])
        [source listView:listView didSelectRowAtIndex:row];
    else
        action();
}

@end