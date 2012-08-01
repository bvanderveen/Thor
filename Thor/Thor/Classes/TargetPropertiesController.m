#import "TargetPropertiesController.h"
#import "TargetPropertiesView.h"

@interface TargetPropertiesController ()

@property (nonatomic, strong) TargetPropertiesView *targetPropertiesView;

@end

@implementation TargetPropertiesController

@synthesize targetPropertiesView;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        
    }
    return self;
}

- (void)loadView {
    self.targetPropertiesView = [[TargetPropertiesView alloc] initWithFrame:NSZeroRect];
    targetPropertiesView.cancelButton.target = self;
    targetPropertiesView.cancelButton.action = @selector(buttonClicked:);
    targetPropertiesView.confirmButton.target = self;
    targetPropertiesView.confirmButton.action = @selector(buttonClicked:);
    
    self.view = targetPropertiesView;
}

- (void)buttonClicked:(NSButton *)button {
    if (button == targetPropertiesView.confirmButton)
    {
        // TODO some validation
        
        NSError *error = nil;
        
        NSDictionary *target = [NSDictionary dictionaryWithObjectsAndKeys:
         targetPropertiesView.displayNameField.stringValue, @"displayName", 
         targetPropertiesView.hostnameField.stringValue, @"hostname",
         targetPropertiesView.emailField.stringValue, @"email",
         targetPropertiesView.passwordField.stringValue, @"password",
         nil];
        
        [[ThorBackend shared] createConfiguredTarget:target error:&error];
    }
    
    [NSApp endSheet:self.view.window];
}

@end
