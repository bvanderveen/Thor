#import "ActivityController.h"
#import "NSFont+LineHeight.h"
#import "NSObject+AssociateDisposable.h"
#import "ThorCore.h"
#import "Sequence.h"

@implementation PushActivity

@synthesize status, localPath, targetAppName, targetHostname, isActive;

- (id)initWithSubscribable:(RACSubscribable *)subscribable {
    if (self = [super init]) {
        self.isActive = YES;
        self.associatedDisposable = [subscribable subscribeNext:^(id x) {
            self.status = FoundryPushStageString([(NSNumber *)x intValue]);
        } error:^(NSError *error) {
            self.status = @"Error";
            [NSApp presentError:error];
            self.associatedDisposable = nil;
            self.isActive = NO;
        } completed:^{
            self.associatedDisposable = nil;
            self.isActive = NO;
        }];
    }
    return self;
}

@end

@interface ActivityCell : NSView

@property (nonatomic, strong) PushActivity *activity;
@property (nonatomic, assign) BOOL highlighted, isAnimating;
@property (nonatomic, strong) NSProgressIndicator *indicator;
@property (nonatomic, strong) NSString *status;

@end


@implementation ActivityCell

@synthesize activity = _activity, highlighted = _highlighted, indicator, status = _status, isAnimating = _isAnimating;

- (void)resetIndicator {
    [indicator stopAnimation:self];
    indicator.indeterminate = NO;
    indicator.doubleValue = 100.0;
}
- (void)setStatus:(NSString *)status {
    _status = status;
    self.needsDisplay = YES;
}

- (void)setIsAnimating:(BOOL)isAnimating {
    _isAnimating = isAnimating;
    
    if (isAnimating) {
        indicator.indeterminate = YES;
        [indicator startAnimation:self];
    }
    else {
        [self resetIndicator];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    self.needsDisplay = YES;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        indicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
        indicator.style = NSProgressIndicatorBarStyle;
        indicator.controlSize = NSSmallControlSize;
        [self resetIndicator];
        [self addSubview:indicator];
        
    }
    return self;
}

- (void)setActivity:(PushActivity *)activity {
    _activity = activity;
    [self bind:@"status" toObject:activity withKeyPath:@"status" options:nil];
    [self bind:@"isAnimating" toObject:activity withKeyPath:@"isActive" options:nil];
    self.needsDisplay = YES;
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    self.needsLayout = YES;
}

- (void)layout {
    [indicator sizeToFit];
    indicator.frame = NSMakeRect(10, 10, self.bounds.size.width - 20, indicator.frame.size.height);
    [super layout];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSFont *nameFont = [NSFont boldSystemFontOfSize:12];
    NSColor *textColor = self.highlighted ? [NSColor whiteColor] : [NSColor colorWithGenericGamma22White:.20 alpha:1];
    
    [[NSString stringWithFormat:@"%@ - %@", _activity.targetHostname, _activity.targetAppName] drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight, self.bounds.size.width, nameFont.lineHeight) withAttributes:@{
        NSForegroundColorAttributeName : textColor,
        NSFontAttributeName : nameFont
     }];
    
    NSFont *memoryFont = [NSFont systemFontOfSize:12];
    [[NSString stringWithFormat:@"%@ - %@", _activity.localPath, self.status] drawInRect:NSMakeRect(10, self.bounds.size.height - nameFont.lineHeight - memoryFont.lineHeight, self.bounds.size.width, memoryFont.lineHeight) withAttributes:@{NSForegroundColorAttributeName : textColor, NSFontAttributeName : memoryFont}];
}

@end

@interface ActivityController ()

@property (nonatomic, strong) TableController *controller;
@property (nonatomic, strong) NSArray *activities;

@end

@implementation ActivityController

@synthesize controller, activities;

- (id)init {
    if (self = [super initWithNibName:nil bundle:nil]) {
        controller = [[TableController alloc] initWithSubscribable:[RACSubscribable return:@[]]];
        activities = @[];
    }
    return self;
}

- (void)loadView {
    self.view = controller.view;
    controller.controllerView.tableView.rowHeight = 60;
}

- (void)updateTable {
    controller.source.items = [activities map:^id(id a)  {
        TableItem *item = [[TableItem alloc] init];
        item.view = ^ NSView * (NSTableView *tableView, NSTableColumn *column, NSInteger row) {
            ActivityCell *cell = [[ActivityCell alloc] initWithFrame:NSZeroRect];
            cell.activity = (PushActivity *)a;
            return cell;
        };
        return item;
    }];
    [controller.controllerView.tableView reloadData];
    [controller.controllerView.tableView sizeLastColumnToFit];
}

- (void)insert:(PushActivity *)activity {
    self.activities = [activities arrayByAddingObject:activity];
    [self updateTable];
}

- (void)clear {
    self.activities = [activities filter:^BOOL(id a) {
        return ((PushActivity *)a).isActive;
    }];
    [self updateTable];
}

@end
