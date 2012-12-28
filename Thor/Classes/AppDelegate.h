#import "ThorBackend.h"
#import "ActivityController.h"
#import "DeploymentController.h"
#import "TableController.h"
#import "TargetController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSWindow *window;
    IBOutlet NSView *view;
    IBOutlet NSMenu *windowMenu;
    IBOutlet NSMenuItem *editTargetMenuItem;
}

@property (nonatomic, strong) IBOutlet NSWindow *activityWindow;
@property (nonatomic, unsafe_unretained) Target *selectedTarget;

// XXX this ain't ideal, it should be a model class.
@property (nonatomic, unsafe_unretained) DeploymentController *selectedDeployment;
@property (nonatomic, unsafe_unretained) TargetController *targetController;

@property (nonatomic, strong) ActivityController *activityController;
@property (nonatomic, unsafe_unretained) App *tableSelectedApp;

- (TableController *)createAppTableController;

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

- (IBAction)clearActivity:(id)sender;

@end
