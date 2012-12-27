#import "WizardController.h"
#import <QuartzCore/QuartzCore.h>
#import "Label.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "SheetWindow.h"
#import "LoadingView.h"
#import "Sequence.h"

@interface WizardControllerView : NSView {
    BOOL displaysLoadingView;
}

@property (nonatomic, strong) LoadingView *loadingView;
@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSButton *cancelButton, *nextButton, *prevButton;


- (void)setDisplaysLoadingView:(BOOL)value animated:(BOOL)animated;
- (BOOL)displaysLoadingView;
- (void)doLayout;

@end

@implementation WizardControllerView;

@synthesize loadingView, contentView, titleLabel, cancelButton, nextButton, prevButton;

- (void)setDisplaysLoadingView:(BOOL)value animated:(BOOL)animated {
    displaysLoadingView = value;
    loadingView.hidden = !value;
    if (value)
        [loadingView.progressIndicator startAnimation:self];
    else
        [loadingView.progressIndicator stopAnimation:self];
}

- (BOOL)displaysLoadingView {
    return displaysLoadingView;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.titleLabel = [Label label];
        titleLabel.font = [NSFont boldSystemFontOfSize:14];
        titleLabel.alignment = NSLeftTextAlignment;
        [self addSubview:titleLabel];
        
        self.cancelButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        cancelButton.bezelStyle = NSRoundedBezelStyle;
        cancelButton.title = @"Cancel";
        cancelButton.keyEquivalent = @"\E";
        [self addSubview:cancelButton];
        
        self.prevButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        prevButton.bezelStyle = NSRoundedBezelStyle;
        prevButton.title = @"Previous";
        [self addSubview:prevButton];
        
        self.nextButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        nextButton.bezelStyle = NSRoundedBezelStyle;
        nextButton.keyEquivalent = @"\r";
        nextButton.title = @"Next";
        [self addSubview:nextButton];
        
        self.contentView = [[NSView alloc] initWithFrame:NSZeroRect];
        [self addSubview:contentView];
        
        self.loadingView = [[LoadingView alloc] initWithFrame:NSZeroRect];
        self.loadingView.hidden = YES;
        [self addSubview:loadingView];
    }
    return self;
}

#define titleInsets (NSEdgeInsetsMake(20, 20, 20, 20))
#define buttonAreaInsets (NSEdgeInsetsMake(10, 10, 10, 10))

- (CGFloat)titleAreaHeight {
    return [titleLabel intrinsicContentSize].height + titleInsets.top + titleInsets.bottom;
}

- (CGFloat)buttonAreaHeight {
    return [((NSButtonCell *)self.prevButton.cell) cellSizeForBounds:self.prevButton.frame].height + buttonAreaInsets.top + buttonAreaInsets.bottom;
}

- (CGSize)intrinsicContentSize {
    CGSize contentSize = CGSizeMake(NSViewNoInstrinsicMetric, NSViewNoInstrinsicMetric);
    
    if (self.contentView.subviews.count) {
        contentSize = ((NSView*)self.contentView.subviews[0]).intrinsicContentSize;
    }
    
    if(contentSize.width == NSViewNoInstrinsicMetric)
        contentSize.width = 500;
    if (contentSize.height == NSViewNoInstrinsicMetric)
        contentSize.height = 200;
    
    CGSize result = NSMakeSize(contentSize.width, contentSize.height + [self titleAreaHeight] + [self buttonAreaHeight]);
    return result;
}

- (NSDictionary *)getLayoutRects {
    NSMutableDictionary *result = [@{} mutableCopy];
    
    NSSize size = [self intrinsicContentSize];
    
    NSSize titleLabelSize = [titleLabel intrinsicContentSize];
    
    NSSize buttonSize = [self.prevButton intrinsicContentSize];
    NSSize nextButtonSize = [self.nextButton intrinsicContentSize];
    buttonSize.width = nextButtonSize.width = 100;
    buttonSize.height = [((NSButtonCell *)self.prevButton.cell) cellSizeForBounds:self.prevButton.frame].height;
    nextButtonSize.height = [((NSButtonCell *)self.nextButton.cell) cellSizeForBounds:self.nextButton.frame].height;
    
    result[@"titleLabel"] = [NSValue valueWithRect:NSMakeRect(titleInsets.left, size.height - titleLabelSize.height - titleInsets.top, size.width - titleInsets.left - titleInsets.bottom, titleLabelSize.height)];
    result[@"nextButton"] = [NSValue valueWithRect:NSMakeRect(size.width - buttonSize.width - buttonAreaInsets.right, buttonAreaInsets.bottom, nextButtonSize.width, nextButtonSize.height)];
    
    
    NSRect adjacentToNextButtonRect = NSMakeRect(size.width - buttonSize.width - buttonAreaInsets.right - buttonSize.width, buttonAreaInsets.bottom, buttonSize.width, buttonSize.height);
    
    if (self.prevButton.isHidden) {
        result[@"cancelButton"] = [NSValue valueWithRect:adjacentToNextButtonRect];
    }
    else {
        result[@"cancelButton"] = [NSValue valueWithRect:NSMakeRect(buttonAreaInsets.left, buttonAreaInsets.bottom, buttonSize.width, buttonSize.height)];
        result[@"prevButton"] = [NSValue valueWithRect:adjacentToNextButtonRect];
    }
    
    CGFloat titleAreaHeight = [self titleAreaHeight];
    CGFloat buttonAreaHeight = [self buttonAreaHeight];
    
    result[@"contentView"] = [NSValue valueWithRect:NSMakeRect(0, buttonAreaHeight, size.width, size.height - titleAreaHeight - buttonAreaHeight)];
    
    result[@"loadingView"] = result[@"contentView"];
    return result;
}

- (void)resizeWindow:(void (^)(void))completion {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = .1;
        NSRect frame = self.window.frame;
        NSSize newSize = self.intrinsicContentSize;
        frame.origin.x += (frame.size.width - newSize.width) / 2;
        frame.origin.y += frame.size.height - newSize.height;
        frame.size = newSize;
        [self.window.animator setFrame:frame display:YES];
        
        NSDictionary *rects = [self getLayoutRects];
        [[rects allKeys] each:^(id f) {
            NSView *view = (NSView *)[self valueForKey:f];
            NSRect rect = [rects[f] rectValue];
            NSLog(@"got view %@ for key %@ frame is\n%@", view, f, NSStringFromRect(rect));
            ((NSView *)view.animator).frame = rect;
            [view setNeedsDisplay:YES];
        }];
    } completionHandler:completion];
}

- (void)fadeOutContent:(void (^)(void))completion {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = .1;
        [self.contentView.animator setAlphaValue:0];
    } completionHandler:completion];
}

- (void)fadeInContent:(void (^)(void))completion {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = .1;
        [self.contentView.animator setAlphaValue:1];
    } completionHandler:completion];
}

- (void)pushToView:(NSView *)newView fromView:(NSView *)oldView {
    self.contentView.wantsLayer = YES;
    self.wantsLayer = YES;
    self.titleLabel.wantsLayer = YES;
    
    [self performSelector:@selector(reallyPush:) withObject:@[newView, oldView] afterDelay:0];
}

- (void)reallyPush:(NSArray *)views {
    NSView *newView = views[0];
    NSView *oldView = views[1];
    NSLog(@"no really");
    
    [self fadeOutContent:^ {
        [self.contentView replaceSubview:oldView with:newView];
        [self resizeWindow:^ {
            [self doLayout];
            [self fadeInContent:^ {
                self.contentView.wantsLayer = NO;
                self.wantsLayer = NO;
                self.titleLabel.wantsLayer = NO;
            }];
        }];
    }];
}

- (void)popToView:(NSView *)newView fromView:(NSView *)oldView {
    [self fadeOutContent:^ {
        [self.contentView replaceSubview:oldView with:newView];
        [self resizeWindow:^ {
            [self doLayout];
            [self fadeInContent:nil];
        }];
    }];
}

- (void)doLayout {
    NSDictionary *rects = [self getLayoutRects];
    [[rects allKeys] each:^ (id f) {
        ((NSView *)[self valueForKeyPath:f]).frame = [rects[f] rectValue];
    }];
    ((NSView *)self.contentView.subviews[0]).frame = self.contentView.bounds;
}

- (void)layout {
    [super layout];
}

@end

@interface WizardController ()

@property (nonatomic, strong) NSViewController<WizardControllerAware> *currentController;
@property (nonatomic, strong) NSArray *stack;
@property (nonatomic, strong) WizardControllerView *wizardControllerView;
@property (nonatomic, copy) void (^didEndBlock)();

@end

@implementation WizardController

@synthesize isSinglePage, currentController = _currentController, stack, wizardControllerView, didEndBlock;

- (void)updatePrevButtonState {
    if (!isSinglePage)
        self.wizardControllerView.prevButton.enabled = self.stack.count > 1;
}

- (void)setCurrentController:(NSViewController<WizardControllerAware> *)currentController {
    assert(currentController.title != nil);
    _currentController = currentController;
    [self viewWillAppearForController:currentController];
    self.wizardControllerView.titleLabel.stringValue = currentController.title;
    [self updatePrevButtonState];
    self.commitButtonTitle = currentController.commitButtonTitle;
}

- (void)setCommitButtonTitle:(NSString *)commitButtonTitle {
    self.wizardControllerView.nextButton.title = commitButtonTitle;
}

- (NSString *)commitButtonTitle {
    return self.wizardControllerView.nextButton.title;
}

- (void)setCommitButtonEnabled:(BOOL)commitButtonEnabled {
    self.wizardControllerView.nextButton.enabled = commitButtonEnabled;
}

- (BOOL)commitButtonEnabled {
    return self.wizardControllerView.nextButton.isEnabled;
}

- (void)setDismissButtonEnabled:(BOOL)dismissButtonEnabled {
    self.wizardControllerView.cancelButton.enabled = dismissButtonEnabled;
}

- (BOOL)dismissButtonEnabled {
    return self.wizardControllerView.cancelButton.isEnabled;
}

- (id)initWithRootViewController:(NSViewController<WizardControllerAware> *)rootController {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.currentController = rootController;
        self.currentController.wizardController = self;
        self.stack = @[ rootController ];
    }
    return self;
}

- (void)loadView {
    self.wizardControllerView = [[WizardControllerView alloc] initWithFrame:NSZeroRect];
    self.wizardControllerView.contentView.wantsLayer = YES;
    
    self.wizardControllerView.cancelButton.rac_command = [RACCommand commandWithBlock:^(id value) {
        for (NSInteger i = stack.count - 1; i >= 0; i--)
            [((NSViewController<WizardControllerAware> *)stack[i]) rollbackWizardPanel];
        
        [self dismissWithReturnCode:NSCancelButton];
    }];
    self.wizardControllerView.prevButton.rac_command = [RACCommand commandWithBlock:^(id value) {
        [self.currentController rollbackWizardPanel];
        
        [self popViewControllerAnimated:YES];
    }];
    
    if (isSinglePage) {
        self.wizardControllerView.prevButton.hidden = YES;
    }
    
    [self updatePrevButtonState];
    
    self.wizardControllerView.nextButton.rac_command = [RACCommand commandWithBlock:^(id value) {
        [self.currentController commitWizardPanel];
    }];
    
    [wizardControllerView.contentView addSubview:self.currentController.view];
    self.view = wizardControllerView;
}

- (void)viewWillAppearForController:(NSViewController<WizardControllerAware> *)controller {
    if ([controller respondsToSelector:@selector(viewWillAppear)])
        [controller viewWillAppear];
}

- (void)viewWillAppear {
    [self.wizardControllerView.contentView addSubview:self.currentController.view];
    [self viewWillAppearForController:self.currentController];
    assert(self.currentController.title != nil);
    self.wizardControllerView.titleLabel.stringValue = self.currentController.title;
    [(WizardControllerView *)self.view doLayout];
}

- (void)pushViewController:(NSViewController<WizardControllerAware> *)controller animated:(BOOL)animated {
    NSViewController<WizardControllerAware> *outgoingController = self.currentController;
    controller.wizardController = self;
    
    self.stack = [stack arrayByAddingObject:controller];
    
    self.currentController = controller;
    
    [self.wizardControllerView pushToView:controller.view fromView:outgoingController.view];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    NSViewController<WizardControllerAware> *outgoingController = self.currentController;
    NSViewController<WizardControllerAware> *controller = stack[stack.count - 2];
    
    NSMutableArray *newStack = [stack mutableCopy];
    [newStack removeObject:outgoingController];
    outgoingController.wizardController = nil;
    self.stack = newStack;
    
    self.currentController = controller;
    
    [self.wizardControllerView popToView:controller.view fromView:outgoingController.view];
}

- (void)presentModalForWindow:(NSWindow *)window didEndBlock:(void(^)(NSInteger))block {
    self.didEndBlock = block;
    NSWindow *wizardWindow = [SheetWindow sheetWindowWithView:self.view];
    [self viewWillAppear];
    [NSApp beginSheet:wizardWindow modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
    didEndBlock(returnCode);
    self.didEndBlock = nil;
}

- (void)dismissWithReturnCode:(NSInteger)returnCode {
    [NSApp endSheet:self.view.window returnCode:returnCode];
}

- (void)displayLoadingView {
    [self.wizardControllerView setDisplaysLoadingView:YES animated:YES];
}

- (void)hideLoadingView {
    [self.wizardControllerView setDisplaysLoadingView:NO animated:YES];
}

@end
