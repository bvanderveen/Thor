#import "DeploymentPropertiesController.h"
#import "NSObject+AssociateDisposable.h"
#import "RACSubscribable+ShowLoadingView.h"

@interface DeploymentPropertiesController ()

@property (nonatomic, strong) NSArray *apps; // of FoundryApp

@end

@implementation DeploymentPropertiesController

@synthesize objectController, deployment, deploymentPropertiesView, apps;

- (id)init {
    if (self = [super initWithNibName:@"DeploymentPropertiesView" bundle:[NSBundle mainBundle]]) {
    }
    return self;
}

- (void)awakeFromNib {
    FoundryService *service = [[FoundryService alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:deployment.target]];
    
    RACSubscribable *call = [[service getApps] showLoadingViewInView:self.deploymentPropertiesView.contentView];
    
    self.associatedDisposable = [call subscribeNext:^(id x) {
        self.apps = x;
    } error:^(NSError *error) {
        [NSApp presentError:error];
    }] ;
}

- (void)buttonClicked:(NSButton *)button {
    if (button == deploymentPropertiesView.confirmButton) {
        NSError *error = nil;
        [objectController commitEditing];
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
            NSLog(@"There was an error! %@", [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
        }
        else {
            [NSApp endSheet:self.view.window];
        }
    }
    else {
        [[ThorBackend sharedContext] rollback];
        [NSApp endSheet:self.view.window];
    }
}

@end
