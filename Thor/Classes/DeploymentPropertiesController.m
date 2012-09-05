#import "DeploymentPropertiesController.h"

@implementation DeploymentPropertiesController

@synthesize objectController, deployment, deploymentPropertiesView;

- (id)init {
    if (self = [super initWithNibName:@"DeploymentPropertiesView" bundle:[NSBundle mainBundle]]) {
    }
    return self;
}

- (void)buttonClicked:(NSButton *)button {
    if (button == deploymentPropertiesView.confirmButton) {
        NSError *error = nil;
        [objectController commitEditing];
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
            NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
        }
        else {
            [NSApp endSheet:self.view.window];
        }
    }
    else {
        [[ThorBackend sharedContext] rollback];
        [NSApp endSheet:self.view.window];
    }
}

@end
