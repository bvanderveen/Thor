#import "TargetPropertiesController.h"

@implementation TargetPropertiesController

@synthesize editing, targetPropertiesView, target, objectController;

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
        [objectController commitEditing];
        NSError *error = nil;
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
            NSLog(@"There was an error! %@", error.userInfo[NSLocalizedDescriptionKey]);
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
