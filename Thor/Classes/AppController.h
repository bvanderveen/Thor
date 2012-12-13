#import "BreadcrumbController.h"
#import "AppView.h"
#import "ThorCore.h"

@interface AppController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem, ListViewDataSource, ListViewDelegate>

@property (nonatomic, copy) NSArray *deployments;
@property (nonatomic, strong) IBOutlet App *app;
@property (nonatomic, strong) IBOutlet AppView *appView;

@end
