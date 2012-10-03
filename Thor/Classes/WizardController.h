#import "ViewVisibilityAware.h"

@class WizardController;

@protocol WizardControllerAware <NSObject, ViewVisibilityAware>

@property (nonatomic, unsafe_unretained) WizardController *wizardController;
@property (nonatomic, copy) NSString *title;

@optional
- (void)commitWizardPanel;
- (void)rollbackWizardPanel;

@end

@interface WizardController : NSViewController <ViewVisibilityAware>

@property (nonatomic) NSString *commitButtonTitle;
@property (nonatomic) BOOL commitButtonEnabled;

- (id)initWithRootViewController:(NSViewController<WizardControllerAware> *)rootController;

- (void)pushViewController:(NSViewController<WizardControllerAware> *)controller animated:(BOOL)animated;
- (void)popViewControllerAnimated:(BOOL)animated;

@end
