
#define CONFIRM_DELETION_ALERT_CONTEXT @"ConfirmDeletion"

@interface NSAlert (Dialogs)

+ (NSAlert *)confirmDeleteTargetDialog;
+ (NSAlert *)confirmDeleteAppDialog;

@end
