#import "CollectionItemView.h"

@implementation CollectionItemViewButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont boldSystemFontOfSize:12], NSFontAttributeName,
                                [NSColor darkGrayColor], NSForegroundColorAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName,
                                nil];
                                
    
    [@"Hey this is a string and it's goddamn long" drawInRect:self.bounds withAttributes:attributes];
    
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont boldSystemFontOfSize:12], NSFontAttributeName,
                                [NSColor whiteColor], NSForegroundColorAttributeName,
                                paragraphStyle, NSParagraphStyleAttributeName,
                                nil];
    [@"Hey this is a string and it's goddamn long" drawInRect:self.bounds withAttributes:attributes];
}

@end

@implementation CollectionItemView

@synthesize button;

@end
