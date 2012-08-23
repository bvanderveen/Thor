#import "ServicesController.h"

@implementation ServicesController

@synthesize title, breadcrumbController;

- (id)init {
    if (self = [super initWithNibName:@"ServicesView" bundle:[NSBundle mainBundle]]) {
        self.title = @"Services";
    }
    return self;
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

@end
