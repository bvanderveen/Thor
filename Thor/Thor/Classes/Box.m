#import "Box.h"

@implementation Box

- (void)drawRect:(NSRect)frameRect {
    
    // dark outline
    NSBezierPath *outerRect = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:5 yRadius:5];
    [outerRect setClip];
    [[NSColor colorWithCalibratedWhite:.85 alpha:1] set];
    NSRectFill(frameRect);
    
    // main area
    NSBezierPath *innerRect = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 1, 1) xRadius:4 yRadius:4];
    [innerRect setClip];
    [[NSColor colorWithCalibratedWhite:.95 alpha:1] set];
    NSRectFill(frameRect);
    
    NSFont *titleFont = [NSFont systemFontOfSize:10];
    CGFloat lineHeight = titleFont.ascender - titleFont.descender + titleFont.leading + 2;
    
    [self.title drawInRect:NSMakeRect(20, self.bounds.size.height - (lineHeight + 10), self.bounds.size.width - 20, lineHeight) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:titleFont, NSFontAttributeName, [NSColor colorWithCalibratedWhite:.15 alpha:1], NSForegroundColorAttributeName, nil]];
    
    [[NSColor colorWithCalibratedWhite:.85 alpha:1] set];
    NSRectFill(NSMakeRect(1, self.bounds.size.height - (lineHeight + 20), self.bounds.size.width - 2, .5));
}

@end
