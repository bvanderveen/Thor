#import "NoResultsCell.h"
#import "NSFont+LineHeight.h"

@implementation NoResultsCell

@synthesize text;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.selectable = NO;
        self.text = @"No results";
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = NSCenterTextAlignment;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    NSFont *font = [NSFont boldSystemFontOfSize:11];
    
    id attributes = @{
                      NSForegroundColorAttributeName : [NSColor colorWithCalibratedWhite:.7 alpha:1],
                      NSFontAttributeName : font,
                      NSParagraphStyleAttributeName : style
                      };
    
    CGSize availableSize = CGSizeMake(self.bounds.size.width - 20, self.bounds.size.height);
    
    CGRect boundingRect = [text boundingRectWithSize:availableSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
    
    [text drawInRect:CGRectMake(10, (self.bounds.size.height - boundingRect.size.height) / 2, availableSize.width, boundingRect.size.height) withAttributes:attributes];
}

@end

