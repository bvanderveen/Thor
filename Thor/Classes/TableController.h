#import <ReactiveCocoa/ReactiveCocoa.h>
#import "WizardController.h"

@interface TableCell : NSView

@property (nonatomic, assign) BOOL highlighted;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, copy) NSTextField *label;

@end

@interface TableItem : NSObject;

@property (nonatomic, copy) NSView *(^view)(NSTableView *, NSTableColumn *, NSInteger);
@property (nonatomic, copy) void (^selected)();

@end

@interface TableSource : NSObject <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, copy) NSArray *items;

@end

@interface TableControllerView : NSView

@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) NSScrollView *scrollView;

@end

@interface TableController : NSViewController

@property (nonatomic, strong) TableSource *source;
@property (nonatomic, strong) RACSubscribable *subscribable;
@property (nonatomic, strong) IBOutlet TableControllerView *controllerView;

- (id)initWithSubscribable:(RACSubscribable *)subscribable;

@end

@interface WizardTableController : NSViewController <WizardControllerAware>

- (id)initWithTableController:(TableController *)tableController commitBlock:(void (^)())commit rollbackBlock:(void (^)())rollback;

@end
