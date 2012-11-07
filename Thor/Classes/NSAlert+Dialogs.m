#import "NSAlert+Dialogs.h"

@implementation NSAlert (Dialogs)

+ (NSAlert *)confirmDeleteTargetDialog {
    return [NSAlert alertWithMessageText:@"Are you sure you wish to delete this cloud?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The cloud and its deployments will no longer appear in Thor. The cloud itself will not be changed."];
}

+ (NSAlert *)confirmDeleteAppDialog {
    return [NSAlert alertWithMessageText:@"Are you sure you wish to delete this application?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The application will no longer appear in Thor. It will not be removed from your hard drive or from any cloud."];
}

@end
