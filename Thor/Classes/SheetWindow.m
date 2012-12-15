#import "SheetWindow.h"

@implementation SheetWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

+ (SheetWindow *)sheetWindowWithView:(NSView *)view {
    NSSize windowSize = view.intrinsicContentSize;
    NSLog(@"windowSize = %@", NSStringFromSize(windowSize));
    SheetWindow *window = [[SheetWindow alloc] initWithContentRect:(NSRect){ .origin = NSZeroPoint, .size = windowSize } styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    window.preventsApplicationTerminationWhenModal = NO;
    window.contentView = view;
    return window;
}

@end