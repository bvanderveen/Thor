#import "WizardController.h"
#import <QuartzCore/QuartzCore.h>
#import "Label.h"

@interface WizardControllerView : NSView

@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSTextField *titleLabel;

@end

@implementation WizardControllerView;

@synthesize contentView = _contentView, titleLabel;

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
        [self addSubview:titleLabel];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return NSMakeSize(500, 380);
}

- (void)layout {
    CGSize size = [self intrinsicContentSize];
    
    CGSize titleLabelSize = [titleLabel intrinsicContentSize];
    titleLabel.frame = NSMakeRect(0, size.height - titleLabelSize.height, titleLabelSize.width, titleLabelSize.height);
    
    self.contentView.frame = NSMakeRect(0, 0, size.width, size.height - titleLabelSize.height);
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
