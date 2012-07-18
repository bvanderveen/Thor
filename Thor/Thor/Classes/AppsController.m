#import "AppsController.h"
#import "AppsView.h"

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
    NSError *error = nil;
    NSArray *apps = [[ThorBackend shared] getConfiguredApps:&error];
    
    AppsView *appsView = [[AppsView alloc] initWithApps:apps];
    appsView.delegate = self;
    self.view = appsView;
}

- (void)clickedAppNamed:(NSString *)name {
    [self.breadcrumbController pushViewController:[[AppsController alloc] initWithTitle:name] animated:YES];
}

@end
