#import <PXSourceList/PXSourceList.h>
#import "ViewVisibilityAware.h"

@interface SourceListController : NSViewController <PXSourceListDelegate, PXSourceListDataSource>

@property (nonatomic, copy) NSViewController<ViewVisibilityAware> *(^controllerForModel)(id);
@property (nonatomic, copy) NSAlert *(^deleteModelConfirmation)(id);

- (void)updateAppsAndTargets;

@end

@interface SourceListControllerView : NSView

@property (nonatomic, retain) IBOutlet PXSourceList *sourceList;
@property (nonatomic, strong) IBOutlet NSView *contentView;

@end