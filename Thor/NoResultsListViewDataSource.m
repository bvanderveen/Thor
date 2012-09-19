#import "NoResultsListViewDataSource.h"
#import "NoResultsCell.h"

@implementation NoResultsListViewDataSource

@synthesize dataSource;

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    NSUInteger rows = [dataSource numberOfRowsForListView:listView];
    return rows ? rows : 1;
}
- (ListCell *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    return [dataSource numberOfRowsForListView:listView] ?
        [dataSource listView:listView cellForRow:row] :
        [[NoResultsCell alloc] initWithFrame:NSZeroRect];
}

@end
