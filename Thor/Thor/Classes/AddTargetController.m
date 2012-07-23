#import "AddTargetController.h"
#import "AddTargetView.h"

@interface AddTargetController ()

@property (nonatomic, strong) AddTargetView *addTargetView;

@end

@implementation AddTargetController

@synthesize addTargetView;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        
    }
    return self;
}

- (void)loadView {
    self.addTargetView = [[AddTargetView alloc] initWithFrame:NSZeroRect];
    
    self.view = addTargetView;
}

@end
