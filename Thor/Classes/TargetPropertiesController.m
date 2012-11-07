#import "TargetPropertiesController.h"

@implementation TargetPropertiesController

@synthesize editing, targetPropertiesView, target, objectController, wizardController, title, commitButtonTitle;

- (id)init {
    if (self = [super initWithNibName:@"TargetPropertiesView" bundle:[NSBundle mainBundle]]) {
        self.commitButtonTitle = @"OK";
    }
    return self;
}

- (void)awakeFromNib {
    targetPropertiesView.windowLabel.stringValue = editing ? @"Edit Cloud" : @"Add Cloud";
    targetPropertiesView.confirmButton.title = editing ? @"Save" : @"OK";
}

- (void)commitWizardPanel {
    [objectController commitEditing];
    NSError *error = nil;
    
    if (!target.managedObjectContext)
        [[ThorBackend sharedContext] insertObject:target];
    
    if (![[ThorBackend sharedContext] save:&error]) {
        [NSApp presentError:error];
        NSLog(@"There was an error! %@", error.userInfo[NSLocalizedDescriptionKey]);
    }
    else {
        [self.wizardController dismissWithReturnCode:NSOKButton];
    }
    
}

- (void)rollbackWizardPanel {
    [[ThorBackend sharedContext] rollback];
}

@end
