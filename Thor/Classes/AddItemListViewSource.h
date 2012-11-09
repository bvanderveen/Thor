#import "ListView.h"

@interface AddItemListViewSource : NSObject <ListViewDataSource, ListViewDelegate>

@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> source;
@property (nonatomic, copy) void (^action)();

- (id)initWithTitle:(NSString *)title;

@end

