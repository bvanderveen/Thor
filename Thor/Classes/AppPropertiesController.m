#import "AppPropertiesController.h"

@implementation AppPropertiesController

@synthesize editing, appPropertiesView, app, objectController;

- (id)init {
    if (self = [super initWithNibName:@"AppPropertiesView" bundle:[NSBundle mainBundle]]) {
    }
    return self;
}

- (void)awakeFromNib {
    appPropertiesView.windowLabel.stringValue = editing ? @"Edit App" : @"Add App";
    appPropertiesView.confirmButton.title = editing ? @"Save" : @"OK";
}

- (void)buttonClicked:(NSButton *)button {
    if (button == appPropertiesView.confirmButton) {
        [objectController commitEditing];
        NSError *error = nil;
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
            NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
        }
        else {
            [NSApp endSheet:self.view.window];
        }
    }
    else if (button == appPropertiesView.browseButton) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        openPanel.canChooseDirectories = YES;
        openPanel.canChooseFiles = NO;
        openPanel.allowsMultipleSelection = NO;
        [openPanel beginSheetModalForWindow:self.view.window completionHandler:^ void (NSInteger result) {
            if (result == NSFileHandlingPanelOKButton) {
                app.localRoot = [[openPanel.URLs objectAtIndex:0] path];
            }
        }];
    }
    else {
        [[ThorBackend sharedContext] rollback];
        [NSApp endSheet:self.view.window];
    }
}

@end
