#import "DeploymentPropertiesController.h"
#import "NSObject+AssociateDisposable.h"
#import "RACSubscribable+Extensions.h"

@implementation DeploymentProperties

@synthesize name, instances, memory;

+ (DeploymentProperties *)defaultDeploymentProperties {
    DeploymentProperties *result = [[DeploymentProperties alloc] init];
    result.name = @"";
    result.instances = 1;
    result.memory = FoundryAppMemoryAmount64;
    return result;
}

+ (DeploymentProperties *)deploymentPropertiesWithApp:(FoundryApp *)app {
    DeploymentProperties *result = [[DeploymentProperties alloc] init];
    result.name = app.name;
    result.instances = app.instances;
    result.memory = FoundryAppMemoryAmountAmountFromInteger(app.memory);
    return result;
}

@end

@interface DeploymentPropertiesController ()

@property (nonatomic, strong) FoundryClient *client;
@property (nonatomic, strong) Deployment *deployment;

@end

@implementation DeploymentPropertiesController

+ (DeploymentPropertiesController *)deploymentPropertiesControllerWithDeployment:(Deployment *)deployment {
    DeploymentPropertiesController *result = [[DeploymentPropertiesController alloc] init];
    result.client = [[FoundryClient alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:deployment.target]];
    result.deploymentProperties = [DeploymentProperties defaultDeploymentProperties];
    result.deploymentProperties.name = deployment.app.lastPathComponent;
    result.deployment = deployment;
    return result;
}

+ (DeploymentPropertiesController *)deploymentPropertiesControllerWithApp:(FoundryApp *)app client:(FoundryClient *)client {
    DeploymentPropertiesController *result = [[DeploymentPropertiesController alloc] init];
    result.client = client;
    result.deploymentProperties = [DeploymentProperties deploymentPropertiesWithApp:app];
    return result;
}

@synthesize objectController, deploymentPropertiesView, wizardController, title, commitButtonTitle, client, deploymentProperties, deployment;

- (id)init {
    if (self = [super initWithNibName:@"DeploymentPropertiesView" bundle:[NSBundle mainBundle]]) {
        self.commitButtonTitle = @"Done";
    }
    return self;
}

#define ThorDeploymentPropertiesControllerErrorDomain @"ThorDeploymentPropertiesControllerErrorDomain"
#define ThorAppAlreadyExistsErrorCode 0xabcdbeef

- (RACSubscribable *)ensureServiceDoesNotHaveAppWithName:(NSString *)name {
    return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
        return [[client getAppWithName:name]
                subscribeNext:^ (id i) {
                    [subscriber sendError:[NSError errorWithDomain:ThorDeploymentPropertiesControllerErrorDomain code:ThorAppAlreadyExistsErrorCode userInfo:@{
                            NSLocalizedDescriptionKey : [NSString stringWithFormat:@"An app named \"%@\" already exists on the host.", name]
                    }]];
                }
                error:^ (NSError *error) {
                    [subscriber sendNext:[NSNull null]];
                    [subscriber sendCompleted];
                }
                completed:^ { }];
    }];
}

- (void)updateApp:(FoundryApp *)app withProperties:(DeploymentProperties *)properties {
    app.memory = FoundryAppMemoryAmountIntegerFromAmount(properties.memory);
    app.instances = properties.instances;
}

- (RACSubscribable *)updateAppInstancesAndMemory {
    return [[client getAppWithName:deploymentProperties.name] continueAfter:^ RACSubscribable *(id x) {
        FoundryApp *latestApp = (FoundryApp *)x;
        [self updateApp:latestApp withProperties:deploymentProperties];
        return [client updateApp:latestApp];
    }];
}

- (void)commitWizardPanel {
    [objectController commitEditing];
    
    // TODO display spinner while waiting.
    self.wizardController.commitButtonEnabled = NO;
    
    FoundryApp *app = nil;
    RACSubscribable *subscribable;
    
    if (deployment) {
        deployment.name = deploymentProperties.name;
        
        app = [FoundryApp appWithDeployment:deployment];
        app.name = deploymentProperties.name;
        [self updateApp:app withProperties:deploymentProperties];
        
        subscribable = [[self ensureServiceDoesNotHaveAppWithName:app.name] continueWith:[client createApp:app]];
    }
    else {
        subscribable = [self updateAppInstancesAndMemory];
    }
        
    self.associatedDisposable = [subscribable subscribeNext:^ (id n) {
        NSLog(@"%@", n);
    } error:^ (NSError *error) {
        [NSApp presentError:error];
        self.wizardController.commitButtonEnabled = YES;
    } completed:^ {
        if (deployment) {
            NSError *error = nil;
            if (![[ThorBackend sharedContext] save:&error]) {
                [NSApp presentError:error];
                NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
            }
        }
        [self.wizardController dismissWithReturnCode:NSOKButton];
    }];
}

- (void)rollbackWizardPanel {
    [[ThorBackend sharedContext] rollback];
}

@end
