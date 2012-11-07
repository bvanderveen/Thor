#import <PXSourceList/PXSourceList.h>

@interface SourceListController : NSViewController <PXSourceListDelegate, PXSourceListDataSource>

@property (nonatomic, copy) NSViewController *(^controllerForModel)(id);
@property (nonatomic, copy) NSAlert *(^deleteModelConfirmation)(id);

- (void)updateAppsAndTargets;

@end

@interface SourceListControllerView : NSView

@property (nonatomic, retain) IBOutlet PXSourceList *sourceList;
@property (nonatomic, strong) IBOutlet NSView *contentView;

@end