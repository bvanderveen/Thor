#import "NSString+ShadowedTextDrawing.h"

@implementation NSString (ShadowedTextDrawing)

- (void)drawShadowedInRect:(NSRect)rect withAttributes:(NSDictionary *)attributes {
    NSDictionary *shadowAttributes = [attributes mutableCopy];
    
    [shadowAttributes setValue:[NSColor colorWithGenericGamma22White:.15 alpha:1] forKey:NSForegroundColorAttributeName];
    [self drawInRect:rect withAttributes:shadowAttributes];
    
    rect.origin.y -= 2;
    [self drawInRect:rect withAttributes:attributes];
}

@end
