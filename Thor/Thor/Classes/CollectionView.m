#import "CollectionView.h"
#import "JRSwizzle.h"

@interface NSClipView (CustomDrawing)

@end

@implementation NSClipView (CustomDrawing)

- (void)customDrawRect:(NSRect)dirtyRect { 
    [NSGraphicsContext saveGraphicsState];
    
    NSRect documentVisibleRect = self.documentVisibleRect;
    
    [NSGraphicsContext currentContext].patternPhase = NSMakePoint(0, 0);
    NSRect clipRect = NSMakeRect(0, documentVisibleRect.origin.y, documentVisibleRect.size.width, documentVisibleRect.size.height);
//    
//    NSLog(@"document rect %@", NSStringFromRect(self.documentRect));
//    NSLog(@"document visible rect %@", NSStringFromRect(documentVisibleRect));
//    NSLog(@"Clip rect %@", NSStringFromRect(clipRect));
//    NSLog(@"---");
    
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


@implementation CollectionView

@synthesize dataSource;

- (void)drawRect:(NSRect)dirtyRect {
    // do nothing. background is drawn by swizzled -[NSClipView drawRect:] above.
}

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object {
    return [dataSource collectionView:self newItemForRepresentedObject:object];
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