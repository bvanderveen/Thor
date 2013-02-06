#import "ListView.h"

@interface NoResultsListViewSource : NSObject <ListViewDataSource, ListViewDelegate>

@property (nonatomic, unsafe_unretained) id<ListViewDataSource, ListViewDelegate> source;

- (id)initWithText:(NSString *)text;

@end