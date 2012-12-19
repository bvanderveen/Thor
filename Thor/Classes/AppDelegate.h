#import "ThorBackend.h"
#import "ActivityController.h"
#import "DeploymentController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *activityWindow;
    IBOutlet NSView *view;
    IBOutlet NSMenu *windowMenu;
    IBOutlet NSMenuItem *editTargetMenuItem;
}

@property (nonatomic, strong) Target *selectedTarget;

// XXX this ain't ideal, it should be a model class.
@property (nonatomic, strong) DeploymentController *selectedDeployment;

@property (nonatomic, strong) ActivityController *activityController;

- (IBAction)newTarget:(id)sender;
- (IBAction)newApp:(id)sender;
- (IBAction)editTarget:(id)sender;

- (IBAction)editDeployment:(id)sender;
- (IBAction)startDeployment:(id)sender;
- (IBAction)stopDeployment:(id)sender;
- (IBAction)restartDeployment:(id)sender;

- (IBAction)newDeployment:(id)sender;
- (IBAction)newService:(id)sender;
- (IBAction)bindService:(id)sender;

@end
