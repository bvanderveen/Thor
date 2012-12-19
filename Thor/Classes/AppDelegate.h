#import "ThorBackend.h"
#import "ActivityController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *activityWindow;
    IBOutlet NSView *view;
    IBOutlet NSMenu *windowMenu;
    IBOutlet NSMenuItem *editTargetMenuItem;
}

@property (nonatomic, strong) Target *selectedTarget;
@property (nonatomic, strong) ActivityController *activityController;

- (IBAction)newTarget:(id)sender;
- (IBAction)newApp:(id)sender;
- (IBAction)editTarget:(id)sender;

@end
