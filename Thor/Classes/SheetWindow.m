#import "SheetWindow.h"

@implementation SheetWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

+ (SheetWindow *)sheetWindowWithView:(NSView *)view {
    SheetWindow *window = [[SheetWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = view.intrinsicContentSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.preventsApplicationTerminationWhenModal = NO;
    window.contentView = view;
    return window;
}

@end