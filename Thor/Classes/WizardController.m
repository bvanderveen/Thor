#import "WizardController.h"
#import <QuartzCore/QuartzCore.h>

@interface WizardControllerView : NSView

@end

@implementation WizardControllerView

- (CGSize)intrinsicContentSize {
    return NSMakeSize(500, 380);
}

- (void)layout {
    ((NSView *)self.subviews[0]).frame = self.bounds;
    [super layout];
}

@end

@interface WizardController ()

@property (nonatomic, strong) NSViewController<WizardControllerAware> *currentController;
@property (nonatomic, strong) NSArray *stack;

@end

@implementation WizardController

@synthesize currentController, stack;

- (id)initWithRootViewController:(NSViewController<WizardControllerAware> *)rootController {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.currentController = rootController;
    }
    return self;
}

- (void)loadView {
    self.view = [[WizardControllerView alloc] initWithFrame:NSZeroRect];
    self.view.wantsLayer = YES;
    [self.view addSubview:currentController.view];
}

- (void)viewWillAppearForController:(NSViewController<WizardControllerAware> *)controller {
    if ([controller respondsToSelector:@selector(viewWillAppear)])
        [controller viewWillAppear];
}

- (void)viewWillAppear {
    [self viewWillAppearForController:currentController];
}

- (void)pushViewController:(NSViewController<WizardControllerAware> *)controller animated:(BOOL)animated {
    CATransition *transition = [CATransition animation];
    transition.type = kCATransition;
    transition.subtype = kCATransitionFromLeft;
    
    self.view.animations = @{ @"subviews" : transition };
    
    controller.wizardController = self;
    [self viewWillAppearForController:controller];
    [self.view.animator replaceSubview:currentController.view with:controller.view];
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
    [self.view.animator replaceSubview:currentController.view with:controller.view];
    
    NSMutableArray *newStack = [stack mutableCopy];
    [newStack removeObject:controller];
    self.stack = newStack;
}

@end
