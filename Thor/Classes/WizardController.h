#import "ViewVisibilityAware.h"

@class WizardController;

@protocol WizardControllerAware <NSObject, ViewVisibilityAware>

@property (nonatomic, unsafe_unretained) WizardController *wizardController;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *commitButtonTitle;

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

- (void)presentModalForWindow:(NSWindow *)window didEndBlock:(void (^)(NSInteger))didEndBlock;
- (void)dismissWithReturnCode:(NSInteger)returnCode;

@end
