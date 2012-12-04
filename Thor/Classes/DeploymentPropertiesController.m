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
@property (nonatomic, strong) App *app;
@property (nonatomic, strong) Target *target;

@end

@implementation DeploymentPropertiesController

+ (DeploymentPropertiesController *)newDeploymentPropertiesControllerWithApp:(App *)app target:(Target *)target {
    assert(app && target);
    DeploymentPropertiesController *result = [[DeploymentPropertiesController alloc] init];
    result.client = [[FoundryClient alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:target]];
    result.deploymentProperties = [DeploymentProperties defaultDeploymentProperties];
    result.deploymentProperties.name = app.lastPathComponent;
    result.app = app;
    result.target = target;
    return result;
}

+ (DeploymentPropertiesController *)deploymentPropertiesControllerWithApp:(FoundryApp *)app client:(FoundryClient *)client {
    DeploymentPropertiesController *result = [[DeploymentPropertiesController alloc] init];
    result.client = client;
    result.deploymentProperties = [DeploymentProperties deploymentPropertiesWithApp:app];
    return result;
}

@synthesize objectController, deploymentPropertiesView, wizardController, title, commitButtonTitle, client, deploymentProperties, app, target;

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

- (void)updateApp:(FoundryApp *)foundryApp withProperties:(DeploymentProperties *)properties {
    foundryApp.memory = FoundryAppMemoryAmountIntegerFromAmount(properties.memory);
    foundryApp.instances = properties.instances;
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
    
    self.wizardController.commitButtonEnabled = NO;
    
    RACSubscribable *subscribable;
    
    if (app && target) {
        subscribable = [[self ensureServiceDoesNotHaveAppWithName:deploymentProperties.name] continueAfter:^RACSubscribable *(id x) {
            FoundryApp *foundryApp = [[FoundryApp alloc] init];
            foundryApp.uris = @[];
            foundryApp.services = @[];
            foundryApp.stagingFramework = DetectFrameworkFromPath([NSURL fileURLWithPath:app.localRoot]);
            foundryApp.stagingRuntime = nil;
            
            foundryApp.name = deploymentProperties.name;
            [self updateApp:foundryApp withProperties:deploymentProperties];
            return [client createApp:foundryApp];
        }];
    }
    else {
        subscribable = [self updateAppInstancesAndMemory];
    }
    
    self.associatedDisposable = [[subscribable showLoadingViewInWizard:self.wizardController] subscribeNext:^ (id n) {
        NSLog(@"%@", n);
    } error:^ (NSError *error) {
        [NSApp presentError:error];
        self.wizardController.commitButtonEnabled = YES;
    } completed:^ {
        if (app && target) {
            Deployment *deployment = [Deployment deploymentWithApp:app target:target];
            deployment.name = deploymentProperties.name;
            
            NSError *error = nil;
            if (![[ThorBackend sharedContext] save:&error]) {
                [NSApp presentError:error];
                NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
            }
            else {
                [self.wizardController dismissWithReturnCode:NSOKButton];
            }
        }
        else {
            [self.wizardController dismissWithReturnCode:NSOKButton];
        }
    }];
}

- (void)rollbackWizardPanel {
    [[ThorBackend sharedContext] rollback];
}

@end
