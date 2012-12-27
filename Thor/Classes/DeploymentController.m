#import "DeploymentController.h"
#import "NSObject+AssociateDisposable.h"
#import "RACSignal+Extensions.h"
#import "GridView.h"
#import "FileSizeInMBTransformer.h"
#import "DeploymentPropertiesController.h"
#import "WizardController.h"
#import "SheetWindow.h"
#import "ServiceCell.h"
#import "Sequence.h"
#import "NoResultsListViewDataSource.h"
#import "AddItemListViewSource.h"
#import "NSAlert+Dialogs.h"
#import "TableController.h"
#import "AppDelegate.h"

@interface NSObject (BoundServicesListViewSourceDelegate)

- (void)selectedService:(FoundryService *)service;
- (void)accessoryButtonClickedForService:(FoundryService *)service;

@end

@interface BoundServicesListViewSource : NSObject <ListViewDataSource, ListViewDelegate>

@property (nonatomic, strong) NSArray *services;
@property (nonatomic, weak) id delegate;

@end

@implementation BoundServicesListViewSource

@synthesize services, delegate;

- (NSUInteger)numberOfRowsForListView:(ListView *)listView {
    return services.count;
}

- (NSView *)listView:(ListView *)listView cellForRow:(NSUInteger)row {
    ServiceCell *cell = [[ServiceCell alloc] initWithFrame:NSZeroRect];
    FoundryService *service = services[row];
    cell.service = service;
//    cell.button.hidden = ![delegate showsAccessoryButtonForApp:app];
    cell.button.rac_command =[RACCommand commandWithBlock:^(id value) {
        [delegate accessoryButtonClickedForService:service];
    }];
    return cell;
}

- (void)listView:(ListView *)listView didSelectRowAtIndex:(NSUInteger)row {
    FoundryService *app = services[row];
    [delegate selectedService:app];
}

@end

@interface DeploymentController ()

@property (nonatomic, strong) FoundryClient *client;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, strong) BoundServicesListViewSource *boundServicesSource;
@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> rootBoundServicesSource;
@property (nonatomic, strong) Deployment *deployment;
@property (nonatomic, copy) NSArray *instanceStats;

@end

static NSArray *instanceColumns = nil;

@implementation DeploymentController

@synthesize client, deployment, app, appName, title, deploymentView, breadcrumbController, instanceStats, boundServicesSource, rootBoundServicesSource;

+ (void)initialize {
    instanceColumns = @[@"ID", @"Host name", @"CPU", @"Memory", @"Disk", @"Uptime"];
}

- (id)initWithTarget:(Target *)leTarget appName:(NSString *)lAppName deployment:(Deployment *)leDeployment {
    if (self = [super initWithNibName:@"DeploymentView" bundle:[NSBundle mainBundle]]) {
        self.title = lAppName;
        self.appName = lAppName;
        self.deployment = leDeployment;
        self.client = [[FoundryClient alloc] initWithEndpoint:[FoundryEndpoint endpointWithTarget:leTarget]];
        
        // XXX horrible
        ((AppDelegate *)[NSApplication sharedApplication].delegate).selectedDeployment = self;
    }
    return self;
}

- (void)dealloc {
    // XXX horrible
    ((AppDelegate *)[NSApplication sharedApplication].delegate).selectedDeployment = nil;
}

+ (DeploymentController *)deploymentControllerWithDeployment:(Deployment *)deployment {
    return [[DeploymentController alloc] initWithTarget:deployment.target appName:deployment.name deployment:deployment];
}

+ (DeploymentController *)deploymentControllerWithAppName:(NSString *)name target:(Target *)target {
    return [[DeploymentController alloc] initWithTarget:target appName:name deployment:nil];
}

- (void)updateAppAndStatsAfterSignal:(RACSignal *)antecedent {
    NSError *error = nil;
    
    NSArray *signals = @[
    [[client getStatsForAppWithName:appName] doNext:^(id x) {
        self.instanceStats = x;
    }],
    [[client getAppWithName:appName] continueAfter:^RACSignal *(id x) {
        self.app = x;
        if (self.app.services.count) {
            NSArray *serviceSignals = [self.app.services map:^ id (id s) {
                return [client getServiceWithName:s];
            }];
            return [[RACSignal combineLatest:serviceSignals] doNext:^(id x) {
                boundServicesSource.services = [(RACTuple *)x allObjects];
            }];
        }
        else {
            boundServicesSource.services = @[];
            return [RACSignal return:[RACUnit defaultUnit]];
        }
    }]];
    
    
    RACSignal *call = [RACSignal combineLatest:signals];
    
    if (!app)
        call = [call showLoadingViewInView:self.view];
    
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
            [self updateAppAndStatsAfterSignal:nil];
        }
    } completed:^ {
        [deploymentView.instancesGrid reloadData];
        [deploymentView.servicesList reloadData];
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
    
    self.boundServicesSource = [[BoundServicesListViewSource alloc] init];
    boundServicesSource.delegate = self;

    NoResultsListViewSource *noResultsSource = [[NoResultsListViewSource alloc] init];
    noResultsSource.source = boundServicesSource;
    
    AddItemListViewSource *addBoundServiceSource = [[AddItemListViewSource alloc] initWithTitle:@"Bind service…"];
    addBoundServiceSource.source = noResultsSource;
    addBoundServiceSource.action = ^ { [self presentBindServiceDialog]; };
    
    self.rootBoundServicesSource = addBoundServiceSource;
    
    deploymentView.servicesList.delegate = rootBoundServicesSource;
    deploymentView.servicesList.dataSource = rootBoundServicesSource;
}

- (void)viewWillAppear {
    [self updateAppAndStatsAfterSignal:nil];
}

- (void)presentDeploymentNotFoundDialog {
    NSAlert *alert = [NSAlert deploymentNotFoundDialog];
    [alert presentSheetModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        [self.breadcrumbController popViewControllerAnimated:YES];
    }];
}

- (void)presentMissingDeploymentDialog {
    NSAlert *alert = [NSAlert missingDeploymentDialog];
    [alert presentSheetModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
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
    }];
}

- (void)presentConfirmDeletionDialog {
    NSAlert *alert = [NSAlert confirmDeleteDeploymentDialog];
    
    [alert presentSheetModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSAlertDefaultReturn) {
            self.associatedDisposable = [[client deleteAppWithName:self.appName] subscribeError:^(NSError *error) {
                [NSApp presentError:error];
            } completed:^{
                if (deployment)
                    [self deleteDeployment];
                [self.breadcrumbController popViewControllerAnimated:YES];
            }];
        }
    }];
}

- (void)deleteDeployment {
    [[ThorBackend sharedContext] deleteObject:deployment];
    
    NSError *error;
    if (![[ThorBackend sharedContext] save:&error]) {
        [NSApp presentError:error];
    }
}

- (void)recreateDeployment {
    RACSignal *createApp = [client createApp:[FoundryApp appWithDeployment:deployment]];
    [self updateAppAndStatsAfterSignal:createApp];
}

- (id<BreadcrumbItem>)breadcrumbItem {
    return self;
}

- (NSUInteger)numberOfColumnsForGridView:(GridView *)gridView {
    return instanceColumns.count;
}

- (CGFloat)gridView:(GridView *)gridView widthOfColumn:(NSUInteger)columnIndex {
    switch (columnIndex) {
        case 0:
            return 35;
        case 1:
            return 130;
        case 2:
            return 40;
        case 3:
            return 60;
        case 4:
            return 70;
        case 5:
            return 80;
    }
    return 0;
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
    DeploymentPropertiesController *deploymentPropertiesController = [DeploymentPropertiesController deploymentPropertiesControllerWithApp:app client:client];
    
    deploymentPropertiesController.title = @"Update deployment";
    
    WizardController *wizard = [[WizardController alloc] initWithRootViewController:deploymentPropertiesController];
    wizard.isSinglePage = YES;
    [wizard presentModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        [self updateAppAndStatsAfterSignal:nil];
    }];
}

- (IBAction)deleteClicked:(id)sender {
    [self presentConfirmDeletionDialog];
}

- (RACSignal *)updateWithState:(FoundryAppState)state {
    return [[client getAppWithName:app.name] continueAfter:^RACSignal *(id x) {
        FoundryApp *latestApp = (FoundryApp *)x;
        latestApp.state = state;
        return [client updateApp:latestApp];
    }];
}

- (RACSignal *)updateByAddingServiceNamed:(NSString *)name {
    return [[client getAppWithName:app.name] continueAfter:^RACSignal *(id x) {
        FoundryApp *latestApp = (FoundryApp *)x;
        if (![latestApp.services containsObject:name])
            latestApp.services = [latestApp.services arrayByAddingObject:name];
        return [client updateApp:latestApp];
    }];
}

- (RACSignal *)updateByRemovingServiceNamed:(NSString *)name {
    return [[client getAppWithName:app.name] continueAfter:^RACSignal *(id x) {
        FoundryApp *latestApp = (FoundryApp *)x;
        latestApp.services = [latestApp.services filter:^BOOL(id n) {
            return ![n isEqual:name];
        }];
        return [client updateApp:latestApp];
    }];
}

- (void)startClicked:(id)sender {
    [self updateAppAndStatsAfterSignal:[[self updateWithState:FoundryAppStateStarted]  animateProgressIndicator:self.deploymentView.stateProgressIndicator]];
}

- (void)stopClicked:(id)sender {
    [self updateAppAndStatsAfterSignal:[[self updateWithState:FoundryAppStateStopped] animateProgressIndicator:self.deploymentView.stateProgressIndicator]];
}

- (void)restartClicked:(id)sender {
    [self updateAppAndStatsAfterSignal:[[[self updateWithState:FoundryAppStateStopped] continueWith:[self updateWithState:FoundryAppStateStarted]] animateProgressIndicator:self.deploymentView.stateProgressIndicator]];
}

- (void)presentBindServiceDialog {
    [((AppDelegate *)[NSApplication sharedApplication].delegate) bindService:nil];
}

- (void)selectedService:(FoundryService *)service {
    NSLog(@"clicked bound service %@", service);
}

- (void)accessoryButtonClickedForService:(FoundryService *)service {
    NSAlert *alert = [NSAlert confirmUnbindServiceDialog];
    [alert presentSheetModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSAlertDefaultReturn) {
            [self updateAppAndStatsAfterSignal:[self updateByRemovingServiceNamed:service.name]];
        }
    }];
}

@end
