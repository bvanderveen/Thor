#import "DeploymentController.h"
#import "NSObject+AssociateDisposable.h"
#import "RACSubscribable+ShowLoadingView.h"
#import "GridView.h"
#import "FileSizeInMBTransformer.h"

@interface DeploymentController ()

@property (nonatomic, strong) FoundryService *service;

@end

static NSArray *instanceColumns = nil;

@implementation DeploymentController

@synthesize service, deployment, app, title, deploymentView, breadcrumbController, instanceStats;

+ (void)initialize {
    instanceColumns = @[@"ID", @"Host name", @"CPU", @"Memory", @"Disk", @"Uptime"];
}

- (id)initWithDeployment:(Deployment *)leDeployment {
    if (self = [super initWithNibName:@"DeploymentView" bundle:[NSBundle mainBundle]]) {
        self.title = leDeployment.appName;
        self.deployment = leDeployment;
        self.service = [[FoundryService alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:deployment.target]];
    }
    return self;
}

- (void)awakeFromNib {
    NSError *error = nil;
    
    NSArray *subscribables = @[
        [service getStatsForAppWithName:deployment.appName],
        [service getAppWithName:deployment.appName]];
    
    RACSubscribable *call = [[RACSubscribable combineLatest:subscribables] showLoadingViewInView:self.view];
    
    self.associatedDisposable = [call subscribeNext:^ (id x) {
        RACTuple *tuple = (RACTuple *)x;
        self.instanceStats = tuple.first;
        self.app = tuple.second;
        [deploymentView.instancesGrid reloadData];
        deploymentView.needsLayout = YES;
    } error:^ (NSError *error) {
        if ([error.domain isEqual:@"SMWebRequest"] && error.code == 404) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"The deployment has disappeared from the cloud." defaultButton:@"Forget deployment" alternateButton:@"Recreate deployment" otherButton:nil informativeTextWithFormat:@"The deployment no longer exists on the cloud. Would you like to re-create it or forget about it?"];
            [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        }
        else {
            [NSApp presentError:error];
        }
    }];
}
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    switch (returnCode) {
        case NSAlertDefaultReturn:
        {
            [[ThorBackend sharedContext] deleteObject:deployment];

            NSError *error;
            if (![[ThorBackend sharedContext] save:&error]) {
                [NSApp presentError:error];
            }
            
            [self.breadcrumbController popViewControllerAnimated:YES];
            
            break;
        }
        case NSAlertAlternateReturn:
            break;
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

- (IBAction)deleteClicked:(id)sender {
    self.associatedDisposable = [[service deleteAppWithName:deployment.appName] subscribeError:^(NSError *error) {
        [NSApp presentError:error];
    } completed:^{
        deployment.target = nil;
        
        [[ThorBackend sharedContext] deleteObject:deployment];
        NSError *error;
        
        if (![[ThorBackend sharedContext] save:&error]) {
            [NSApp presentError:error];
            return;
        }
        
        [self.breadcrumbController popViewControllerAnimated:YES];
    }];
}

@end
