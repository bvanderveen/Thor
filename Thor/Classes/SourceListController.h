#import <PXSourceList/PXSourceList.h>

@interface SourceListController : NSViewController <PXSourceListDelegate, PXSourceListDataSource>

@property (nonatomic, copy) NSViewController *(^controllerForModel)(id);

@end

@interface SourceListControllerView : NSView

@property (nonatomic, retain) IBOutlet PXSourceList *sourceList;
@property (nonatomic, strong) IBOutlet NSView *contentView;

@end