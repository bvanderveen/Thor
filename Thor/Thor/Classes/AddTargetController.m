#import "AddTargetController.h"
#import "AddTargetView.h"

@interface AddTargetController ()

@property (nonatomic, strong) AddTargetView *addTargetView;

@end

@implementation AddTargetController

@synthesize addTargetView;

- (NSDictionary *)target {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            addTargetView.displayNameField.stringValue, @"displayName", 
            addTargetView.hostnameField.stringValue, @"hostname",
            addTargetView.emailField.stringValue, @"email",
            addTargetView.passwordField.stringValue, @"password",
            nil];
}

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
    [NSApp endSheet:self.view.window returnCode:
        button == self.addTargetView.confirmButton ? NSOKButton : NSCancelButton];
}

@end
