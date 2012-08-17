#import "Box.h"

@implementation Box

- (void)drawRect:(NSRect)dirtyRect {
    [NSGraphicsContext saveGraphicsState];
    
    // dark outline
    NSBezierPath *outerRect = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:5 yRadius:5];
    [outerRect addClip];
    [[NSColor colorWithCalibratedWhite:.85 alpha:1] set];
    NSRectFill(self.bounds);
    
    // main area
    NSBezierPath *innerRect = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 1, 1) xRadius:4 yRadius:4];
    [innerRect addClip];
    [[NSColor colorWithCalibratedWhite:.95 alpha:1] set];
    NSRectFill(self.bounds);
    
    NSFont *titleFont = [NSFont systemFontOfSize:10];
    CGFloat lineHeight = titleFont.ascender - titleFont.descender + titleFont.leading + 2;
    
    [self.title drawInRect:NSMakeRect(20, self.bounds.size.height - (lineHeight + 10), self.bounds.size.width - 20, lineHeight) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:titleFont, NSFontAttributeName, [NSColor colorWithCalibratedWhite:.45 alpha:1], NSForegroundColorAttributeName, nil]];
    
    [[NSColor colorWithCalibratedWhite:.85 alpha:1] set];
    NSRectFill(NSMakeRect(1, self.bounds.size.height - (lineHeight + 20), self.bounds.size.width - 2, .5));
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
