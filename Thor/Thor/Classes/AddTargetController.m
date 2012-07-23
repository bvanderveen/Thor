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
    self.addTargetView.cancelButton.target = self;
    self.addTargetView.cancelButton.action = @selector(cancel);
    self.addTargetView.confirmButton.target = self;
    self.addTargetView.confirmButton.action = @selector(confirm);
    
    self.view = addTargetView;
}

- (void)cancel {
    NSLog(@"Cancelled add target");
    [NSApp endSheet:self.view.window];
}

- (void)confirm {
    NSLog(@"Confirmed add target");
    [NSApp endSheet:self.view.window];
}

@end
