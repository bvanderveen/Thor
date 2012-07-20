#import "AddAppController.h"
#import "AddAppView.h"

@interface AddAppController ()

@property (nonatomic, strong) AddAppView *addAppView;

@end

@implementation AddAppController

@synthesize addAppView;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        
    }
    return self;
}

- (void)loadView {
    self.addAppView = [[AddAppView alloc] initWithFrame:NSZeroRect];
    
    self.view = addAppView;
}

@end
