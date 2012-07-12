#import "AppsController.h"
#import "AppsView.h"
#import "App.h"

@implementation AppsController

@synthesize title, breadcrumbController;

- (id)init {
    return [self initWithTitle:@"Apps"];
}

- (id)initWithTitle:(NSString *)leTitle {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.title = leTitle;
    }
    return self;
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (void)loadView {
    AppsView *appsView = [[AppsView alloc] initWithApps:[App fakeApps]];
    appsView.delegate = self;
    self.view = appsView;
}

- (void)clickedAppNamed:(NSString *)name {
    [self.breadcrumbController pushViewController:[[AppsController alloc] initWithTitle:name] animated:YES];
}

@end
