#import "WizardController.h"
#import <QuartzCore/QuartzCore.h>
#import "Label.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "SheetWindow.h"
#import "LoadingView.h"

@interface WizardControllerView : NSView {
    BOOL displaysLoadingView;
}

@property (nonatomic, strong) LoadingView *loadingView;
@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSButton *cancelButton, *nextButton, *prevButton;


- (void)setDisplaysLoadingView:(BOOL)value animated:(BOOL)animated;
- (BOOL)displaysLoadingView;

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

- (CGSize)intrinsicContentSize {
    return NSMakeSize(500, 380);
}

- (void)layout {
    NSSize size = [self intrinsicContentSize];
    
    NSEdgeInsets titleInsets = NSEdgeInsetsMake(20, 20, 20, 20);
    
    NSSize titleLabelSize = [titleLabel intrinsicContentSize];
    
    NSSize buttonSize = [self.prevButton intrinsicContentSize];
    NSSize nextButtonSize = [self.nextButton intrinsicContentSize];
    buttonSize.width = nextButtonSize.width = 100;
    buttonSize.height = [((NSButtonCell *)self.prevButton.cell) cellSizeForBounds:self.prevButton.frame].height;
    nextButtonSize.height = [((NSButtonCell *)self.nextButton.cell) cellSizeForBounds:self.nextButton.frame].height;
    
    NSEdgeInsets buttonAreaInsets = NSEdgeInsetsMake(10, 10, 10, 10);
    
    self.titleLabel.frame = NSMakeRect(titleInsets.left, size.height - titleLabelSize.height - titleInsets.top, size.width - titleInsets.left - titleInsets.bottom, titleLabelSize.height);
    
    self.nextButton.frame = NSMakeRect(size.width - buttonSize.width - buttonAreaInsets.right, buttonAreaInsets.bottom, nextButtonSize.width, nextButtonSize.height);
    
    
    NSRect adjacentToNextButtonRect = NSMakeRect(size.width - buttonSize.width - buttonAreaInsets.right - buttonSize.width, buttonAreaInsets.bottom, buttonSize.width, buttonSize.height);
    
    if (self.prevButton.isHidden) {
        self.cancelButton.frame = adjacentToNextButtonRect;
    }
    else {
        self.cancelButton.frame = NSMakeRect(buttonAreaInsets.left, buttonAreaInsets.bottom, buttonSize.width, buttonSize.height);
        self.prevButton.frame = adjacentToNextButtonRect;
    }
    
    CGFloat titleAreaHeight = titleLabelSize.height + titleInsets.top + titleInsets.bottom;
    CGFloat buttonAreaHeight = buttonSize.height + buttonAreaInsets.top + buttonAreaInsets.bottom;
    
    self.contentView.frame = NSMakeRect(0, buttonAreaHeight, size.width, size.height - titleAreaHeight - buttonAreaHeight);
    ((NSView *)self.contentView.subviews[0]).frame = self.contentView.bounds;
    
    self.loadingView.frame = self.contentView.frame;
    
    [super layout];
}

@end

@interface WizardController ()

@property (nonatomic, strong) NSViewController<WizardControllerAware> *currentController;
@property (nonatomic, strong) NSArray *stack;
@property (nonatomic, readonly) WizardControllerView *wizardControllerView;
@property (nonatomic, copy) void (^didEndBlock)();

@end

@implementation WizardController

@synthesize isSinglePage, currentController, stack, wizardControllerView, didEndBlock;

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

- (WizardControllerView *)wizardControllerView {
    return (WizardControllerView *)self.view;
}

- (id)initWithRootViewController:(NSViewController<WizardControllerAware> *)rootController {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.currentController = rootController;
        currentController.wizardController = self;
        self.stack = @[ rootController ];
    }
    return self;
}

- (void)loadView {
    self.view = [[WizardControllerView alloc] initWithFrame:NSZeroRect];
    self.wizardControllerView.contentView.wantsLayer = YES;
    
    [self.wizardControllerView.cancelButton addCommand:[RACCommand commandWithCanExecute:nil execute:^(id value) {
        
        for (NSInteger i = stack.count - 1; i >= 0; i--)
            [((NSViewController<WizardControllerAware> *)stack[i]) rollbackWizardPanel];
        
        [self dismissWithReturnCode:NSCancelButton];
    }]];
    [self.wizardControllerView.prevButton addCommand:[RACCommand commandWithCanExecute:nil execute:^(id value) {
        [self.currentController rollbackWizardPanel];
        
        [self popViewControllerAnimated:YES];
    }]];
    
    if (isSinglePage) {
        self.wizardControllerView.prevButton.hidden = YES;
    }
        
        
    [self.wizardControllerView.nextButton addCommand:[RACCommand commandWithCanExecute:nil execute:^(id value) {
        [self.currentController commitWizardPanel];
    }]];
}

- (void)viewWillAppearForController:(NSViewController<WizardControllerAware> *)controller {
    if ([controller respondsToSelector:@selector(viewWillAppear)])
        [controller viewWillAppear];
}

- (void)viewWillAppear {
    [self.wizardControllerView.contentView addSubview:currentController.view];
    [self viewWillAppearForController:currentController];
    assert(currentController.title != nil);
    self.wizardControllerView.titleLabel.stringValue = currentController.title;
    self.view.needsLayout = YES;
    
    [self updateButtonState];
}

- (void)updateButtonState {
    if (!isSinglePage)
        self.wizardControllerView.prevButton.enabled = self.stack.count > 1;
    self.commitButtonTitle = currentController.commitButtonTitle;
}

- (void)pushViewController:(NSViewController<WizardControllerAware> *)controller animated:(BOOL)animated {
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    
    self.wizardControllerView.contentView.animations = @{ @"subviews" : transition };
    
    controller.wizardController = self;
    
    [self.wizardControllerView.contentView.animator replaceSubview:currentController.view with:controller.view];
    [self viewWillAppearForController:controller];
    assert(controller.title != nil);
    self.wizardControllerView.titleLabel.stringValue = controller.title;
    currentController = controller;
    
    self.stack = [stack arrayByAddingObject:controller];
    
    [self updateButtonState];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    
    self.wizardControllerView.contentView.animations = @{ @"subviews" : transition };
    
    NSViewController<WizardControllerAware> *outgoingController = currentController;
    NSViewController<WizardControllerAware> *controller = stack[stack.count - 2];
    
    [self.wizardControllerView.contentView.animator replaceSubview:currentController.view with:controller.view];
    [self viewWillAppearForController:controller];
    assert(controller.title != nil);
    self.wizardControllerView.titleLabel.stringValue = controller.title;
    currentController = controller;
    
    NSMutableArray *newStack = [stack mutableCopy];
    [newStack removeObject:outgoingController];
    outgoingController.wizardController = nil;
    self.stack = newStack;
    
    [self updateButtonState];
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
