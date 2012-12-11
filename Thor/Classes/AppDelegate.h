#import "ThorCore.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    IBOutlet NSWindow *window;
    IBOutlet NSView *view;
}

@property (nonatomic, strong) Target *selectedTarget;
@property (nonatomic, strong) NSString *selectedAppName;

- (IBAction)newTarget:(id)sender;
- (IBAction)editTarget:(id)sender;

@end
