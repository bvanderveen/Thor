#import "NoResultsListViewDataSource.h"
#import "NoResultsCell.h"

@implementation NoResultsListViewSource

@synthesize source;

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    NSUInteger rows = [source numberOfRowsForListView:listView];
    return rows ? rows : 1;
}

- (ListCell *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    return [source numberOfRowsForListView:listView] ?
        [source listView:listView cellForRow:row] :
        [[NoResultsCell alloc] initWithFrame:NSZeroRect];
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    return [source listView:listView didSelectRowAtIndex:row];
}

@end
