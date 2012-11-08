#import "DeploymentController.h"
#import "NSObject+AssociateDisposable.h"
#import "RACSubscribable+Extensions.h"
#import "GridView.h"
#import "FileSizeInMBTransformer.h"
#import "DeploymentPropertiesController.h"
#import "WizardController.h"
#import "SheetWindow.h"

#define MISSING_DEPLOYMENT_ALERT_CONTEXT @"Missing"
#define NOT_FOUND_ALERT_CONTEXT @"NotFound"
#define CONFIRM_DELETION_ALERT_CONTEXT @"ConfirmDeletion"

@interface DeploymentController ()

@property (nonatomic, strong) FoundryClient *client;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, strong) DeploymentPropertiesController *deploymentPropertiesController;

@end

static NSArray *instanceColumns = nil;

@implementation DeploymentController

@synthesize client, deployment, app, appName, title, deploymentView, breadcrumbController, instanceStats, deploymentPropertiesController;

+ (void)initialize {
    instanceColumns = @[@"ID", @"Host name", @"CPU", @"Memory", @"Disk", @"Uptime"];
}

- (id)initWithTarget:(Target *)leTarget appName:(NSString *)lAppName deployment:(Deployment *)leDeployment {
    if (self = [super initWithNibName:@"DeploymentView" bundle:[NSBundle mainBundle]]) {
        self.title = lAppName;
        self.appName = lAppName;
        self.deployment = leDeployment;
        self.client = [[FoundryClient alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:leTarget]];
    }
    return self;
}

+ (DeploymentController *)deploymentControllerWithDeployment:(Deployment *)deployment {
    return [[DeploymentController alloc] initWithTarget:deployment.target appName:deployment.name deployment:deployment];
}

+ (DeploymentController *)deploymentControllerWithAppName:(NSString *)name target:(Target *)target {
    return [[DeploymentController alloc] initWithTarget:target appName:name deployment:nil];
}

- (void)updateAppAndStatsAfterSubscribable:(RACSubscribable *)antecedent {
    NSError *error = nil;
    
    NSArray *subscribables = @[
    [[client getStatsForAppWithName:appName] doNext:^(id x) {
        self.instanceStats = x;
    }],
    [[client getAppWithName:appName] doNext:^(id x) {
        self.app = x;
    }]];
    
    RACSubscribable *call = [[RACSubscribable combineLatest:subscribables] showLoadingViewInView:self.view];
    
    if (antecedent)
        call = [antecedent continueWith:call];
    
    self.associatedDisposable = [call subscribeError:^ (NSError *error) {
        if ([error.domain isEqual:@"SMWebRequest"] && error.code == 404) {
            if (deployment)
                [self presentMissingDeploymentDialog];
            else
                [self presentDeploymentNotFoundDialog];
        }
        else {
            [NSApp presentError:error];
        }
    } completed:^ {
        [deploymentView.instancesGrid reloadData];
        deploymentView.needsLayout = YES;
    }];
}

- (void)awakeFromNib {
    deploymentView.toolbarView.startButton.target = self;
    deploymentView.toolbarView.startButton.action = @selector(startClicked:);
    deploymentView.toolbarView.stopButton.target = self;
    deploymentView.toolbarView.stopButton.action = @selector(stopClicked:);
    deploymentView.toolbarView.restartButton.target = self;
    deploymentView.toolbarView.restartButton.action = @selector(restartClicked:);
    
    [self updateAppAndStatsAfterSubscribable:nil];
}

- (void)presentDeploymentNotFoundDialog {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Deployment not found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The deployment no longer exists on the cloud."];
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NOT_FOUND_ALERT_CONTEXT];
}

- (void)presentMissingDeploymentDialog {
    NSAlert *alert = [NSAlert alertWithMessageText:@"The deployment has disappeared from the cloud." defaultButton:@"Forget deployment" alternateButton:@"Recreate deployment" otherButton:nil informativeTextWithFormat:@"The deployment no longer exists on the cloud. Would you like to recreate it or forget about it?"];
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MISSING_DEPLOYMENT_ALERT_CONTEXT];
}

- (void)presentConfirmDeletionDialog {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you wish to delete this deployment?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"The deployment will be removed from the cloud. This action cannot be undone."];
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:CONFIRM_DELETION_ALERT_CONTEXT];
}

- (void)deleteDeployment {
    [[ThorBackend sharedContext] deleteObject:deployment];
    
    NSError *error;
    if (![[ThorBackend sharedContext] save:&error]) {
        [NSApp presentError:error];
    }
}

- (void)recreateDeployment {
    RACSubscribable *createApp = [client createApp:[FoundryApp appWithDeployment:deployment]];
    [self updateAppAndStatsAfterSubscribable:createApp];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSString *contextString = (__bridge NSString *)contextInfo;
    if ([contextString isEqual:MISSING_DEPLOYMENT_ALERT_CONTEXT]) {
        assert(deployment != nil);    
        switch (returnCode) {
            case NSAlertDefaultReturn:
                [self deleteDeployment];
                [self.breadcrumbController popViewControllerAnimated:YES];
                break;
            case NSAlertAlternateReturn:
                [self recreateDeployment];
                break;
        }
    }
    else if ([contextString isEqual:NOT_FOUND_ALERT_CONTEXT]) {
        [self.breadcrumbController popViewControllerAnimated:YES];
    }
    else if ([contextString isEqual:CONFIRM_DELETION_ALERT_CONTEXT]) {
        if (returnCode == NSAlertDefaultReturn) {
            self.associatedDisposable = [[client deleteAppWithName:self.appName] subscribeError:^(NSError *error) {
                [NSApp presentError:error];
            } completed:^{
                if (deployment)
                    [self deleteDeployment];
                [self.breadcrumbController popViewControllerAnimated:YES];
            }];
        }
    }
    
    [NSApp endSheet:alert.window];
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (NSUInteger)numberOfColumnsForGridView:(GridView *)gridView {
    return instanceColumns.count;
}

- (NSString *)gridView:(GridView *)gridView titleForColumn:(NSUInteger)columnIndex {
    return [instanceColumns objectAtIndex:columnIndex];
}

- (NSUInteger)numberOfRowsForGridView:(GridView *)gridView {
    return instanceStats.count;
}

- (NSView *)gridView:(GridView *)gridView viewForRow:(NSUInteger)row column:(NSUInteger)columnIndex {
    FoundryAppInstanceStats *stats = [instanceStats objectAtIndex:row];
    
    NSString *labelTitle;
    
    NSValueTransformer *transformer = [FileSizeInMBTransformer new];
    
    switch (columnIndex) {
        case 0:
            labelTitle = stats.ID;
            break;
        case 1:
            labelTitle = stats.host;
            break;
        case 2:
            labelTitle = [NSString stringWithFormat:@"%2.0f%%", stats.cpu];
            break;
        case 3:
            labelTitle = [transformer transformedValue:[NSNumber numberWithFloat:stats.memory]];
            break;
        case 4:
            labelTitle = [transformer transformedValue:[NSNumber numberWithFloat:stats.disk]];
            break;
        case 5:;
            NSInteger ti = (NSInteger)roundf(stats.uptime + 23483.0);
            NSInteger seconds = ti % 60;
            NSInteger minutes = (ti / 60) % 60;
            NSInteger hours = (ti / 3600);
            
            labelTitle = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", hours, minutes, seconds];
            break;
    }
    
    return [GridLabel labelWithTitle:labelTitle];
}

- (void)gridView:(GridView *)gridView didSelectRowAtIndex:(NSUInteger)row {
    NSLog(@"Clicked at index %lu", row);
}

- (IBAction)editClicked:(id)sender {
    if (deployment)
        self.deploymentPropertiesController = [DeploymentPropertiesController deploymentPropertiesControllerWithDeployment:deployment create:NO];
    else
        self.deploymentPropertiesController = [DeploymentPropertiesController deploymentPropertiesControllerWithApp:app client:client];
    
    deploymentPropertiesController.title = @"Update deployment";
    
    WizardController *wizard = [[WizardController alloc] initWithRootViewController:deploymentPropertiesController];
    NSWindow *window = [SheetWindow sheetWindowWithView:wizard.view];
    [wizard viewWillAppear];
    [NSApp beginSheet:window modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.deploymentPropertiesController = nil;
    [sheet orderOut:self];
    [self updateAppAndStatsAfterSubscribable:nil];
}

- (IBAction)deleteClicked:(id)sender {
    [self presentConfirmDeletionDialog];
}

- (RACSubscribable *)updateWithState:(FoundryAppState)state {
    return [[client getAppWithName:app.name] continueAfter:^RACSubscribable *(id x) {
        FoundryApp *latestApp = (FoundryApp *)x;
        latestApp.state = state;
        return [client updateApp:latestApp];
    }];
}

- (void)startClicked:(id)sender {
    [self updateAppAndStatsAfterSubscribable:[self updateWithState:FoundryAppStateStarted]];
}

- (void)stopClicked:(id)sender {
    [self updateAppAndStatsAfterSubscribable:[self updateWithState:FoundryAppStateStopped]];
}

- (void)restartClicked:(id)sender {
    [self updateAppAndStatsAfterSubscribable:[[self updateWithState:FoundryAppStateStopped] continueWith:[self updateWithState:FoundryAppStateStarted]]];
}

@end
