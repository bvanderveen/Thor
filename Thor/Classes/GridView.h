

@class GridView;

@protocol GridDataSource <NSObject>

- (NSUInteger)numberOfColumnsForGridView:(GridView *)gridView;
- (NSString *)gridView:(GridView *)gridView titleForColumn:(NSUInteger)columnIndex;

- (NSUInteger)numberOfRowsForGridView:(GridView *)gridView;
- (NSString *)gridView:(GridView *)gridView titleForRow:(NSUInteger)row column:(NSUInteger)columnIndex;

@end

@protocol GridDelegate <NSObject>

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row;

@end


@interface GridView : NSView

@property (nonatomic, unsafe_unretained) IBOutlet id<GridDataSource> dataSource;
@property (nonatomic, unsafe_unretained) IBOutlet id<GridDelegate> delegate;

- (void)reloadData;

@end
