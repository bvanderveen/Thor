#import "WizardController.h"
#import <QuartzCore/QuartzCore.h>

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

- (void)awakeFromNib {
    self.view.wantsLayer = YES;
    [self.view addSubview:currentController.view];
}

- (void)pushViewController:(NSViewController<WizardControllerAware> *)controller animated:(BOOL)animated {
    CATransition *transition = [CATransition animation];
    transition.type = kCATransition;
    transition.subtype = kCATransitionFromLeft;
    
    self.view.animations = @{ @"subviews" : transition };
    
    controller.wizardController = self;
    [self.view.animator replaceSubview:currentController.view with:controller.view];
    currentController = controller;
    
    self.stack = [stack arrayByAddingObject:controller];
}

- (void)popViewControllerAnimated:(BOOL)animated {
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    
    self.view.animations = @{ @"subviews" : transition };
    
    NSViewController *controller = stack[stack.count - 2];
    [self.view.animator replaceSubview:currentController.view with:controller.view];
    
    NSMutableArray *newStack = [stack mutableCopy];
    [newStack removeObject:controller];
    self.stack = newStack;
}

@end
