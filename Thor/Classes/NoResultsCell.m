#import "NoResultsCell.h"
#import "NSFont+LineHeight.h"

@implementation NoResultsCell

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.selectable = NO;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSCenterTextAlignment;
    NSFont *font = [NSFont boldSystemFontOfSize:12];
    [@"No results" drawInRect:NSMakeRect(0, (self.bounds.size.height - font.lineHeight) / 2 + 2, self.bounds.size.width, font.lineHeight) withAttributes:@{
NSForegroundColorAttributeName : [NSColor colorWithCalibratedWhite:.8 alpha:1],
         NSFontAttributeName : font,
NSParagraphStyleAttributeName : style
     }];
}

@end

