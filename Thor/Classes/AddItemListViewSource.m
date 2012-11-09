#import "AddDeploymentListViewSource.h"
#import "NSFont+LineHeight.h"

@interface AddDeploymentCell : ListCell

@end

@implementation AddDeploymentCell

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSCenterTextAlignment;
    NSFont *font = [NSFont boldSystemFontOfSize:12];
    [@"New deployment…" drawInRect:NSMakeRect(0, (self.bounds.size.height - font.lineHeight) / 2 + 2, self.bounds.size.width, font.lineHeight) withAttributes:@{
   NSForegroundColorAttributeName : [NSColor colorWithCalibratedWhite:.2 alpha:1],
              NSFontAttributeName : font,
    NSParagraphStyleAttributeName : style
     }];
}

@end

@implementation AddDeploymentListViewSource

@synthesize source, action;

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    return [source numberOfRowsForListView:listView] + 1;
}

- (BOOL)rowInListView:(ListView *)listView isWrappedCell:(NSUInteger)row {
    return row < [source numberOfRowsForListView:listView];
}

- (ListCell *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    return [self rowInListView:listView isWrappedCell:row] ?
    [source listView:listView cellForRow:row] :
    [[AddDeploymentCell alloc] initWithFrame:NSZeroRect];
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    if ([self rowInListView:listView isWrappedCell:row])
        [source listView:listView didSelectRowAtIndex:row];
    else
        action();
}

@end