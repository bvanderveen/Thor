

@class GridView;

@protocol GridDataSource <NSObject>

- (NSUInteger)numberOfColumnsForGridView:(GridView *)gridView;
- (CGFloat)gridView:(GridView *)gridView widthOfColumn:(NSUInteger)columnIndex;
- (NSString *)gridView:(GridView *)gridView titleForColumn:(NSUInteger)columnIndex;

- (NSUInteger)numberOfRowsForGridView:(GridView *)gridView;
- (NSView *)gridView:(GridView *)gridView viewForRow:(NSUInteger)row column:(NSUInteger)columnIndex;

@end

@protocol GridDelegate <NSObject>

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row;

@end


@interface GridView : NSView

@property (nonatomic, unsafe_unretained) IBOutlet id<GridDataSource> dataSource;
@property (nonatomic, unsafe_unretained) IBOutlet id<GridDelegate> delegate;

- (void)reloadData;

@end

@interface GridLabel : NSTextView

+ (GridLabel *)labelWithTitle:(NSString *)title;

@end
