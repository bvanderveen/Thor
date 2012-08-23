#import "TargetPropertiesController.h"

@implementation TargetPropertiesController

@synthesize editing, targetPropertiesView, target;

- (id)init {
    if (self = [super initWithNibName:@"TargetPropertiesView" bundle:[NSBundle mainBundle]]) {
    }
    return self;
}

- (void)awakeFromNib {
    targetPropertiesView.windowLabel.stringValue = editing ? @"Edit Cloud" : @"Add Cloud";
    targetPropertiesView.confirmButton.title = editing ? @"Save" : @"OK";
}

- (void)buttonClicked:(NSButton *)button {
    if (button == targetPropertiesView.confirmButton) {
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
