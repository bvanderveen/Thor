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
    addTargetView.cancelButton.target = self;
    addTargetView.cancelButton.action = @selector(buttonClicked:);
    addTargetView.confirmButton.target = self;
    addTargetView.confirmButton.action = @selector(buttonClicked:);
    
    self.view = addTargetView;
}

- (void)buttonClicked:(NSButton *)button {
    if (button == addTargetView.confirmButton)
    {
        // TODO some validation
        
        NSError *error = nil;
        
        NSDictionary *target = [NSDictionary dictionaryWithObjectsAndKeys:
         addTargetView.displayNameField.stringValue, @"displayName", 
         addTargetView.hostnameField.stringValue, @"hostname",
         addTargetView.emailField.stringValue, @"email",
         addTargetView.passwordField.stringValue, @"password",
         nil];
        
        [[ThorBackend shared] createConfiguredTarget:target error:&error];
    }
    
    [NSApp endSheet:self.view.window];
}

@end
