#import "AppPropertiesController.h"

@implementation AppPropertiesController

@synthesize appPropertiesView, app;

- (id)init {
    if (self = [super initWithNibName:@"AppPropertiesView" bundle:[NSBundle mainBundle]]) {
    }
    return self;
}

- (void)buttonClicked:(NSButton *)button {
    if (button == appPropertiesView.confirmButton) {
        NSError *error = nil;
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
