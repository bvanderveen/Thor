#import "BreadcrumbController.h"

@interface AppController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem>

@property (nonatomic, strong) IBOutlet App *app;
//@property (nonatomic, strong) IBOutlet AppView *appView;

- (IBAction)editClicked:(id)sender;

@end
