
@interface AppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSWindow *window;
    IBOutlet NSView *view;
}

- (IBAction)newTarget:(id)sender;
- (IBAction)newApp:(id)sender;

@end
