#import "NSAlert+Dialogs.h"
#import <objc/runtime.h>

@interface NSAlert ()

@property (nonatomic, copy) void (^didEndBlock)(NSInteger);

@end


NSInteger kDidEndBlockKey;

@implementation NSAlert (Dialogs)

- (void (^)(NSInteger))didEndBlock {
    return objc_getAssociatedObject(self, &kDidEndBlockKey);
}

- (void)setDidEndBlock:(void (^)(NSInteger))didEndBlock {
    objc_setAssociatedObject(self, &kDidEndBlockKey, didEndBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (NSAlert *)confirmDeleteTargetDialog {
    return [NSAlert alertWithMessageText:@"Are you sure you wish to delete this cloud?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The cloud and its deployments will no longer appear in Thor. The cloud itself will not be changed."];
}

+ (NSAlert *)confirmDeleteAppDialog {
    return [NSAlert alertWithMessageText:@"Are you sure you wish to delete this application?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The application will no longer appear in Thor. It will not be removed from your hard drive or from any cloud."];
}

+ (NSAlert *)confirmDeleteDeploymentDialog {
    return [NSAlert alertWithMessageText:@"Are you sure you wish to delete this deployment?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The deployment will be removed from the cloud. This action cannot be undone."];
}

+ (NSAlert *)confirmUnbindServiceDialog {
    return [NSAlert alertWithMessageText:@"Are you sure you wish to unbind this service?" defaultButton:@"Unbind" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The service will be unbound from the deployment. This action cannot be undone."];
}

+ (NSAlert *)confirmDeleteServiceDialog {
    return [NSAlert alertWithMessageText:@"Are you sure you wish to delete this service?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The service will be unbound from any apps to which it is currently bound."];
}

+ (NSAlert *)deploymentNotFoundDialog {
    return [NSAlert alertWithMessageText:@"Deployment not found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The deployment no longer exists on the cloud."];
}

+ (NSAlert *)missingDeploymentDialog {
    return [NSAlert alertWithMessageText:@"The deployment has disappeared from the cloud." defaultButton:@"Forget deployment" alternateButton:@"Recreate deployment" otherButton:nil informativeTextWithFormat:@"The deployment no longer exists on the cloud. Would you like to recreate it or forget about it?"];
}

+ (NSAlert *)noConfiguredAppsDialog {
    return [NSAlert alertWithMessageText:@"You have not created any apps." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"To create a new deployment, you must first create an app."];
}

+ (NSAlert *)noConfiguredTargetsDialog {
    return [NSAlert alertWithMessageText:@"You have not created any clouds." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"To create a new deployment, you must first create a cloud."];
}

+ (NSAlert *)noProvisionedServicesDialog {
    return [NSAlert alertWithMessageText:@"The cloud does not have any provisioned services." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"To bind a service to this application, you must provision a service."];
}

+ (NSAlert *)invalidCredentialsDialog {
    return [NSAlert alertWithMessageText:@"Your credentials appear to be invalid." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please double check your email and password."];
}

+ (NSAlert *)failedToConnectToHostDialog {
    return [NSAlert alertWithMessageText:@"There was an error connecting to the host." defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please double check the hostname."];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (self.didEndBlock)
        self.didEndBlock(returnCode);
    [NSApp endSheet:self.window];
}

- (void)presentSheetModalForWindow:(NSWindow *)window didEndBlock:(void (^)(NSInteger))didEnd {
    self.didEndBlock = didEnd;
    [self beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

@end
