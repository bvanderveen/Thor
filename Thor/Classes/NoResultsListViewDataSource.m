#import "NoResultsListViewDataSource.h"
#import "NoResultsCell.h"

@interface NoResultsListViewSource ()

@property (nonatomic, copy) NSString *text;

@end

@implementation NoResultsListViewSource

@synthesize source, text;

- (id)initWithText:(NSString *)leText {
    if (self = [super init]) {
        text = leText;
    }
    return self;
}

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    NSUInteger rows = [source numberOfRowsForListView:listView];
    return rows ? rows : 1;
}

- (ListCell *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    if ([source numberOfRowsForListView:listView])
        return [source listView:listView cellForRow:row];
    
    NoResultsCell *cell = [[NoResultsCell alloc] initWithFrame:NSZeroRect];
    
    if (text)
        cell.text = text;
    
    return cell;
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    if ([source numberOfRowsForListView:listView])
        [source listView:listView didSelectRowAtIndex:row];
}

@end
