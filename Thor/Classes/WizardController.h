#import "ViewVisibilityAware.h"

@class WizardController;

@protocol WizardControllerAware <NSObject, ViewVisibilityAware>

@property (nonatomic, unsafe_unretained) WizardController *wizardController;

@end

@interface WizardController : NSViewController <ViewVisibilityAware>

- (id)initWithRootViewController:(NSViewController<WizardControllerAware> *)rootController;

- (void)pushViewController:(NSViewController<WizardControllerAware> *)controller animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

@end
