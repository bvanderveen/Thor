#import "ListView.h"

@interface AddDeploymentListViewSource : NSObject <ListViewDataSource, ListViewDelegate>

@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> source;
@property (nonatomic, copy) void (^action)();

@end

