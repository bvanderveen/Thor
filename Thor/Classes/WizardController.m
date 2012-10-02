#import "WizardController.h"
#import <QuartzCore/QuartzCore.h>
#import "Label.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface WizardControllerView : NSView

@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSButton *cancelButton, *nextButton, *prevButton;

@end

@implementation WizardControllerView;

@synthesize contentView = _contentView, titleLabel, cancelButton, nextButton, prevButton;

- (void)setContentView:(NSView *)value {
    if (_contentView)
        [self.animator replaceSubview:_contentView with:value];
    else
        [self addSubview:value];
    
    _contentView = value;
}

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.titleLabel = [Label label];
        self.titleLabel.font = [NSFont boldSystemFontOfSize:14];
        self.titleLabel.alignment = NSLeftTextAlignment;
        [self addSubview:titleLabel];
        
        self.cancelButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        cancelButton.bezelStyle = NSTexturedRoundedBezelStyle;
        cancelButton.title = @"Cancel";
        cancelButton.keyEquivalent = @"\E";
        [self addSubview:cancelButton];
        
        self.prevButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        prevButton.bezelStyle = NSTexturedRoundedBezelStyle;
        prevButton.title = @"Back";
        [self addSubview:prevButton];
        
        self.nextButton = [[NSButton alloc] initWithFrame:NSZeroRect];
        nextButton.bezelStyle = NSTexturedRoundedBezelStyle;
        nextButton.title = @"Next";
        [self addSubview:nextButton];
        nextButton.keyEquivalent = @"\r";
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
    titleLabel.frame = NSMakeRect(titleInsets.left, size.height - titleLabelSize.height - titleInsets.top, size.width - titleInsets.left - titleInsets.bottom, titleLabelSize.height);
    
    NSSize buttonSize = [self.cancelButton intrinsicContentSize];
    buttonSize.width = 60;
    
    NSEdgeInsets buttonAreaInsets = NSEdgeInsetsMake(20, 20, 20, 20);
    
    self.cancelButton.frame = NSMakeRect(buttonAreaInsets.left, buttonAreaInsets.bottom, buttonSize.width, buttonSize.height);
    
    self.nextButton.frame = NSMakeRect(size.width - buttonSize.width - buttonAreaInsets.right, buttonAreaInsets.bottom, buttonSize.width, buttonSize.height);
    
    self.prevButton.frame = NSMakeRect(size.width - buttonSize.width - buttonAreaInsets.right - buttonSize.width - 10, buttonAreaInsets.bottom, buttonSize.width, buttonSize.height);
    
    CGFloat titleAreaHeight = titleLabelSize.height + titleInsets.top + titleInsets.bottom;
    CGFloat buttonAreaHeight = buttonSize.height + buttonAreaInsets.top + buttonAreaInsets.bottom;
    
    self.contentView.frame = NSMakeRect(0, buttonAreaHeight, size.width, size.height - titleAreaHeight - buttonAreaHeight);
    
    [super layout];
}

@end

@interface WizardController ()

@property (nonatomic, strong) NSViewController<WizardControllerAware> *currentController;
@property (nonatomic, strong) NSArray *stack;
@property (nonatomic, readonly) WizardControllerView *wizardControllerView;

@end

@implementation WizardController

@synthesize currentController, stack, wizardControllerView;

- (WizardControllerView *)wizardControllerView {
    return (WizardControllerView *)self.view;
}

- (id)initWithRootViewController:(NSViewController<WizardControllerAware> *)rootController {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.currentController = rootController;
    }
    return self;
}

- (void)loadView {
    self.view = [[WizardControllerView alloc] initWithFrame:NSZeroRect];
    self.view.wantsLayer = YES;
    [self.wizardControllerView.cancelButton addCommand:[RACCommand commandWithCanExecute:nil execute:^(id value) {
        [NSApp endSheet:self.view.window returnCode:NSCancelButton];
    }]];
}

- (void)viewWillAppearForController:(NSViewController<WizardControllerAware> *)controller {
    if ([controller respondsToSelector:@selector(viewWillAppear)])
        [controller viewWillAppear];
}

- (void)viewWillAppear {
    [self viewWillAppearForController:currentController];
    self.wizardControllerView.contentView = currentController.view;
    self.wizardControllerView.titleLabel.stringValue = currentController.title;
    self.view.needsLayout = YES;
}

- (void)pushViewController:(NSViewController<WizardControllerAware> *)controller animated:(BOOL)animated {
    CATransition *transition = [CATransition animation];
    transition.type = kCATransition;
    transition.subtype = kCATransitionFromLeft;
    
    self.view.animations = @{ @"subviews" : transition };
    
    controller.wizardController = self;
    
    [self viewWillAppearForController:controller];
    wizardControllerView.contentView = controller.view;
    wizardControllerView.titleLabel.stringValue = controller.title;
    currentController = controller;
    
    self.stack = [stack arrayByAddingObject:controller];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    
    self.view.animations = @{ @"subviews" : transition };
    
    NSViewController<WizardControllerAware> *controller = stack[stack.count - 2];
    
    [self viewWillAppearForController:controller];
    wizardControllerView.contentView = controller.view;
    wizardControllerView.titleLabel.stringValue = controller.title;
    currentController = controller;
    
    NSMutableArray *newStack = [stack mutableCopy];
    [newStack removeObject:controller];
    self.stack = newStack;
}

@end
