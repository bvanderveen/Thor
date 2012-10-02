#import "CollectionView.h"
#import "JRSwizzle.h"
#import "Label.h"

#define ATTEMPT_CUTE_BACKGROUND_DRAWING (NO)

@interface NSClipView (CustomDrawing)

@end

@implementation NSClipView (CustomDrawing)

- (void)customDrawRect:(NSRect)dirtyRect {
    
    BOOL attemptClip = ATTEMPT_CUTE_BACKGROUND_DRAWING;
    NSRect fillRect;
    
    if (attemptClip) {
        [NSGraphicsContext saveGraphicsState];
        
        NSRect documentVisibleRect = self.documentVisibleRect;
        
        [NSGraphicsContext currentContext].patternPhase = NSMakePoint(0, 0);
        fillRect = NSMakeRect(0, documentVisibleRect.origin.y, documentVisibleRect.size.width, documentVisibleRect.size.height);
    //    
    //    NSLog(@"document rect %@", NSStringFromRect(self.documentRect));
    //    NSLog(@"document visible rect %@", NSStringFromRect(documentVisibleRect));
    //    NSLog(@"Clip rect %@", NSStringFromRect(clipRect));
    //    NSLog(@"---");
        
        NSBezierPath *newClipPath = [NSBezierPath bezierPathWithRect:fillRect];
        [newClipPath addClip];
    }
    else {
        fillRect = dirtyRect;
        [self customDrawRect:dirtyRect];
        return;
    }
    
    NSImage *background = [NSImage imageNamed:@"CollectionViewBackground"];
    [[NSColor colorWithPatternImage:background] set];
    NSRectFill(fillRect);
    
    if (attemptClip) {
        [NSGraphicsContext restoreGraphicsState];
    }
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

- (void)awakeFromNib {
    [super awakeFromNib];
    if (ATTEMPT_CUTE_BACKGROUND_DRAWING) {
        
    } else {
        self.backgroundColors = @[[NSColor colorWithPatternImage:[NSImage imageNamed:@"CollectionViewBackground"]]];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    if (ATTEMPT_CUTE_BACKGROUND_DRAWING) {
        // do nothing. background is drawn by swizzled -[NSClipView drawRect:] above.
    }
    else {
        [super drawRect:dirtyRect];
    }
}

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object {
    return [dataSource collectionView:self newItemForRepresentedObject:object];
}

@end
