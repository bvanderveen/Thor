
@interface NSAlert (Dialogs)

+ (NSAlert *)confirmDeleteTargetDialog;
+ (NSAlert *)confirmDeleteAppDialog;
+ (NSAlert *)confirmDeleteDeploymentDialog;
+ (NSAlert *)confirmDeleteServiceDialog;
+ (NSAlert *)confirmUnbindServiceDialog;
+ (NSAlert *)deploymentNotFoundDialog;
+ (NSAlert *)missingDeploymentDialog;

- (void)presentSheetModalForWindow:(NSWindow *)window didEndBlock:(void (^)(NSInteger))didEnd;

@end
