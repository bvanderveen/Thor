#import "ThorBackend.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSWindow *window;
    IBOutlet NSView *view;
}

@property (nonatomic, strong) Target *selectedTarget;

- (IBAction)newTarget:(id)sender;
- (IBAction)newApp:(id)sender;
- (IBAction)editTarget:(id)sender;

@end
