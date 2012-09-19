#import "ListView.h"

@interface NoResultsListViewDataSource : NSObject <ListViewDataSource>

@property (nonatomic, unsafe_unretained) id<ListViewDataSource> dataSource;

@end