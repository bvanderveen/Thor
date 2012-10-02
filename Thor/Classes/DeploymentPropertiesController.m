#import "DeploymentPropertiesController.h"
#import "NSObject+AssociateDisposable.h"
#import "RACSubscribable+ShowLoadingView.h"

@interface RACSubscribable (ContinueAfter)

- (RACSubscribable *)continueWith:(RACSubscribable *)subscribable;

@end

@implementation RACSubscribable (ContinueAfter)

- (RACSubscribable *)continueWith:(RACSubscribable *)subscribable {
    return [[self select:^id(id x) {
        return subscribable;
    }] selectMany:^id<RACSubscribable>(id x) {
        return x;
    }];
}

@end

@interface DeploymentPropertiesController ()

@property (nonatomic, strong) NSArray *apps; // of FoundryApp

@end

@implementation DeploymentPropertiesController

@synthesize title;

+ (DeploymentPropertiesController *)newDeploymentControllerWithTarget:(Target *)target app:(App *)app {
    DeploymentPropertiesController *result = [[DeploymentPropertiesController alloc] init];
    result.deployment = [Deployment deploymentInsertedIntoManagedObjectContext:[ThorBackend sharedContext]];
    result.deployment.app = app;
    result.deployment.appName = [((NSURL *)[NSURL fileURLWithPath:app.localRoot]).pathComponents lastObject];
    result.deployment.target = target;
    return result;
}

@synthesize objectController, deployment, deploymentPropertiesView, apps, wizardController;

- (id)init {
    if (self = [super initWithNibName:@"DeploymentPropertiesView" bundle:[NSBundle mainBundle]]) {
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

- (void)buttonClicked:(NSButton *)button {
    if (button == deploymentPropertiesView.confirmButton) {
        NSError *error = nil;
        [objectController commitEditing];
        
        // TODO revert this if the remote creation fails.
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
            NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
        }
        else {
            FoundryService *service = [[FoundryService alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:deployment.target]];
            
            FoundryApp *app = [FoundryApp new];
            app.name = deployment.appName;
            app.uris = @[];
            app.stagingFramework = @"node";
            app.instances = deployment.instances;
            app.memory = deployment.memory;
            
            // TODO display spinner while waiting.
            deploymentPropertiesView.confirmButton.enabled = NO;
            
            RACSubscribable *subscribable = [[self ensureService:service doesNotHaveAppWithName:deployment.appName] continueWith:[service createApp:app]];
            
            self.associatedDisposable = [subscribable subscribeNext: ^ (id n) {
                NSLog(@"%@", n);
            } error:^(NSError *error) {
                [NSApp presentError:error];
                deploymentPropertiesView.confirmButton.enabled = YES;
            } completed:^{
                [NSApp endSheet:self.view.window];
            }];
        }
    }
    else {
        [[ThorBackend sharedContext] rollback];
        [NSApp endSheet:self.view.window];
    }
}

@end
