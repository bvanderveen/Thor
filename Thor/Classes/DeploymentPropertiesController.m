#import "DeploymentPropertiesController.h"
#import "NSObject+AssociateDisposable.h"
#import "RACSubscribable+Extensions.h"

@interface DeploymentPropertiesController ()

@property (nonatomic, assign) BOOL isNewDeployment;

@end

@implementation DeploymentPropertiesController

@synthesize title, commitButtonTitle;

+ (DeploymentPropertiesController *)newDeploymentControllerWithTarget:(Target *)target app:(App *)app {
    DeploymentPropertiesController *result = [[DeploymentPropertiesController alloc] init];
    result.deployment = [Deployment deploymentInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    result.deployment.app = app;
    result.deployment.appName = [((NSURL *)[NSURL fileURLWithPath:app.localRoot]).pathComponents lastObject];
    result.deployment.target = target;
    result.title = @"Create deployment";
    result.isNewDeployment = YES;
    return result;
}

+ (DeploymentPropertiesController *)deploymentControllerWithDeployment:(Deployment *)deployment {
    DeploymentPropertiesController *result = [[DeploymentPropertiesController alloc] init];
    result.deployment = deployment;
    result.title = @"Update deployment";
    return result;
}

@synthesize objectController, deployment, deploymentPropertiesView, wizardController, isNewDeployment;

- (id)init {
    if (self = [super initWithNibName:@"DeploymentPropertiesView" bundle:[NSBundle mainBundle]]) {
        self.commitButtonTitle = @"Done";
    }
    return self;
}

#define ThorDeploymentPropertiesControllerErrorDomain @"ThorDeploymentPropertiesControllerErrorDomain"
#define ThorAppAlreadyExistsErrorCode 0xabcdbeef

- (RACSubscribable *)ensureService:(FoundryService *)service doesNotHaveAppWithName:(NSString *)name {
    return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        return [[service getAppWithName:name]
                subscribeNext:^ (id i) {
                    [subscriber sendError:[NSError errorWithDomain:ThorDeploymentPropertiesControllerErrorDomain code:ThorAppAlreadyExistsErrorCode userInfo:@{
                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"An app named %@ already exists on the host.", name]
                    }]];
                }
                error:^ (NSError *error) {
                    [subscriber sendNext:[NSNull null]];
                    [subscriber sendCompleted];
                }
                completed:^ {
                }];
    }];
}

- (void)commitWizardPanel {
    [objectController commitEditing];
    
    FoundryService *service = [[FoundryService alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:deployment.target]];
    
    FoundryApp *app = [FoundryApp appWithDeployment:deployment];
    
    // TODO display spinner while waiting.
    self.wizardController.commitButtonEnabled = NO;
    
    RACSubscribable *subscribable;
    
    if (isNewDeployment) {
        subscribable = [[self ensureService:service doesNotHaveAppWithName:deployment.appName] continueWith:[service createApp:app]];
    }
    else {
        subscribable = [service updateApp:app];
    }
    
    self.associatedDisposable = [subscribable subscribeNext:^ (id n) {
        NSLog(@"%@", n);
    } error:^ (NSError *error) {
        [NSApp presentError:error];
        self.wizardController.commitButtonEnabled = YES;
    } completed:^ {
        NSError *error = nil;
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
            NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
        }
        [self.wizardController dismissWithReturnCode:NSOKButton];
    }];
}

- (void)rollbackWizardPanel {
    [[ThorBackend sharedContext] rollback];
}

@end
