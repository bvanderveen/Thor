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

+ (AppDelegate *)shared;

@property (nonatomic, strong) IBOutlet NSWindow *activityWindow;

@property (nonatomic, strong) Target *selectedTarget;
@property (nonatomic, strong) FoundryApp *selectedApp;

@property (nonatomic, strong) ActivityController *activityController;
@property (nonatomic, unsafe_unretained) App *tableSelectedApp;

@property (nonatomic, strong) RACSubject *selectedTargetRefreshing;
@property (nonatomic, strong) RACSubject *selectedAppRefreshing;

- (TableController *)createAppTableController;

- (IBAction)newApp:(id)sender;

- (IBAction)newTarget:(id)sender;
- (IBAction)editTarget:(id)sender;
- (IBAction)newService:(id)sender;

- (IBAction)newDeployment:(id)sender;
- (IBAction)editDeployment:(id)sender;
- (IBAction)startDeployment:(id)sender;
- (IBAction)stopDeployment:(id)sender;
- (IBAction)restartDeployment:(id)sender;
- (IBAction)bindService:(id)sender;

- (IBAction)clearActivity:(id)sender;

@end
