
@class WizardController;

@protocol WizardControllerAware <NSObject>

@property (nonatomic, unsafe_unretained) WizardController *wizardController;

@end

@interface WizardController : NSViewController

- (id)initWithRootViewController:(NSViewController<WizardControllerAware> *)rootController;

- (void)pushViewController:(NSViewController<WizardControllerAware> *)controller animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

@end
