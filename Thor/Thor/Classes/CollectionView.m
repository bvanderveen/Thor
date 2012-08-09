#import "CollectionView.h"
#import "JRSwizzle.h"

@interface NSClipView (CustomDrawing)

@end

@implementation NSClipView (CustomDrawing)

- (void)customDrawRect:(NSRect)dirtyRect { 
    [NSGraphicsContext saveGraphicsState];
    
    CGFloat above = MAX(-self.documentVisibleRect.origin.y, 0);
    CGFloat below = MAX(MIN((self.documentVisibleRect.size.height + self.documentVisibleRect.origin.y) - self.documentRect.size.height, self.documentVisibleRect.size.height),0);
    
    [NSGraphicsContext currentContext].patternPhase = NSMakePoint(0, 0);
    NSRect clipRect = NSMakeRect(0, self.documentVisibleRect.origin.y , self.documentVisibleRect.size.width, self.documentVisibleRect.size.height);
    
    NSBezierPath *newClipPath = [NSBezierPath bezierPathWithRect:clipRect];
    [newClipPath setClip];
    
    NSImage *background = [NSImage imageNamed:@"CollectionViewBackground"];
    [[NSColor colorWithPatternImage:background] set];
    NSRectFill(clipRect);
    
    [NSGraphicsContext restoreGraphicsState];
}

@end

@implementation CollectionScrollView

+ (void)initialize {
    NSError *error = nil;
    
    [NSClipView jr_swizzleMethod:@selector(drawRect:) withMethod:@selector(customDrawRect:) error:&error];
}

@end


@implementation TransparentCollectionView

@synthesize itemPrototypeFactory;

- (void)drawRect:(NSRect)dirtyRect {
    
}
- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object {
    return itemPrototypeFactory(self);
}

@end

@implementation Label

+ (NSTextField *)label {
    NSTextField *result = [[NSTextField alloc] initWithFrame:NSZeroRect];
    result.editable = NO;
    result.bordered = NO;
    result.translatesAutoresizingMaskIntoConstraints = NO;
    result.drawsBackground = NO;
    result.alignment = NSRightTextAlignment;
    return  result;
}

@end