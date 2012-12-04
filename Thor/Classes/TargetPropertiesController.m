#import "TargetPropertiesController.h"
#import "NSObject+AssociateDisposable.h"
#import "NSAlert+Dialogs.h"
#import "RACSubscribable+Extensions.h"

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
    
    self.associatedDisposable = [[[[FoundryEndpoint endpointWithTarget:target] verifyCredentials] showLoadingViewInWizard:self.wizardController] subscribeNext:^(id x) {
        if ([x boolValue]) {
            if (!target.managedObjectContext)
                [[ThorBackend sharedContext] insertObject:target];
            
            NSError *error = nil;
            
            if (![[ThorBackend sharedContext] save:&error]) {
                [NSApp presentError:error];
                NSLog(@"There was an error! %@", error.userInfo[NSLocalizedDescriptionKey]);
            }
            else {
                [self.wizardController dismissWithReturnCode:NSOKButton];
            }
        }
        else {
            NSAlert *alert = [NSAlert invalidCredentialsDialog];
            [alert presentSheetModalForWindow:self.view.window didEndBlock:nil];
        }
    } error:^(NSError *error) {
        if ([error.domain isEqual:NSURLErrorDomain]) {
            NSAlert *alert = [NSAlert failedToConnectToHostDialog];
            [alert presentSheetModalForWindow:self.view.window didEndBlock:nil];
        }
        else
            [NSApp presentError:error];
    } completed:^{
    }];
}

- (void)rollbackWizardPanel {
    [[ThorBackend sharedContext] rollback];
}

@end
