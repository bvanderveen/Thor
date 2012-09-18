
@class ListView, ListCell;

@protocol ListViewDataSource <NSObject>

- (NSUInteger)numberOfRowsForListView:(ListView *)listView;
- (ListCell *)listView:(ListView *)listView cellForRow:(NSUInteger)row;

@end

@protocol ListViewDelegate <NSObject>

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row;

@end


@interface ListView : NSView

@property (nonatomic, unsafe_unretained) IBOutlet id<ListViewDataSource> dataSource;
@property (nonatomic, unsafe_unretained) IBOutlet id<ListViewDelegate> delegate;
@property (nonatomic, assign) NSInteger rowHeight;

- (void)reloadData;

@end

@interface ListCell : NSView

@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, assign) BOOL selectable;

@end