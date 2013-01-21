#import "DeploymentController.h"
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
#import <ReactiveCocoa/EXTScope.h>

@interface NSObject (BoundServicesListViewSourceDelegate)

- (void)selectedService:(FoundryService *)service;
- (void)accessoryButtonClickedForService:(FoundryService *)service;

@end

@interface BoundServicesListViewSource : NSObject <ListViewDataSource, ListViewDelegate>

@property (nonatomic, copy) NSArray *services;
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
    cell.button.rac_command = [RACCommand commandWithBlock:^(id value) {
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
@property (nonatomic, strong) BoundServicesListViewSource *boundServicesSource;
@property (nonatomic, strong) id<ListViewDataSource, ListViewDelegate> rootBoundServicesSource;
@property (nonatomic, copy) NSArray *instanceStats;

@end

static NSArray *instanceColumns = nil;

@implementation DeploymentController

@synthesize client, app, title, deploymentView, breadcrumbController, instanceStats, boundServicesSource, rootBoundServicesSource;

+ (void)initialize {
    instanceColumns = @[@"ID", @"Host name", @"CPU", @"Memory", @"Disk", @"Uptime"];
}

- (id)initWithApp:(FoundryApp *)lApp client:(id<FoundryClient>)leClient {
    if (self = [super initWithNibName:@"DeploymentView" bundle:[NSBundle mainBundle]]) {
        self.title = lApp.name;
        self.app = lApp;
        self.client = leClient;
        [[AppDelegate shared].selectedAppRefreshing subscribeNext:^(id x) {
            [self updateAppAndStatsAfterSignal:nil];
        }];
    }
    return self;
}

+ (DeploymentController *)deploymentControllerWithDeployment:(Deployment *)deployment {
    return [DeploymentController deploymentControllerWithAppName:deployment.name target:deployment.target];
}

+ (DeploymentController *)deploymentControllerWithAppName:(NSString *)name target:(Target *)target {
    FoundryApp *app = [[FoundryApp alloc] init];
    app.name = name;
    return [[DeploymentController alloc] initWithApp:app client:[FoundryClient clientWithEndpoint:[FoundryEndpoint endpointWithTarget:target]]];
}

- (RACSignal *)appAndStatsSignal {
    @weakify(self)
    return [RACSignal combineLatest:@[
        [[client getStatsForAppWithName:app.name] doNext:^(id x) {
            @strongify(self);
            self.instanceStats = x;
        }],
        [[client getAppWithName:app.name] continueAfter:^RACSignal *(id x) {
            @strongify(self);
            self.app = x;
            [AppDelegate shared].selectedApp = app;
            if (self.app.services.count) {
                NSArray *serviceSignals = [self.app.services map:^ id (id s) {
                    return [self.client getServiceWithName:s];
                }];
                return [[RACSignal combineLatest:serviceSignals] doNext:^(id x) {
                    self.boundServicesSource.services = [(RACTuple *)x allObjects];
                }];
            }
            else {
                self.boundServicesSource.services = @[];
                return [RACSignal return:[RACUnit defaultUnit]];
            }
        }]
    ]];
}

- (void)updateAppAndStatsAfterSignal:(RACSignal *)antecedent {
    NSError *error = nil;
    
    RACSignal *call = [self appAndStatsSignal];
    
    if (!instanceStats)
        call = [call showLoadingViewInView:self.view];
    
    if (antecedent)
        call = [antecedent continueWith:call];
    
    @weakify(self);
    [call subscribeError:^ (NSError *error) {
        @strongify(self);
        if ([error.domain isEqual:@"SMWebRequest"] && error.code == 404) {
            [self presentDeploymentNotFoundDialog];
        }
        else {
            [NSApp presentError:error];
            [self updateAppAndStatsAfterSignal:nil];
        }
    } completed:^ {
        @strongify(self);
        [self.deploymentView.instancesGrid reloadData];
        [self.deploymentView.servicesList reloadData];
        self.deploymentView.needsLayout = YES;
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
    @weakify(self);
    addBoundServiceSource.action = ^ {
        @strongify(self);
        [self presentBindServiceDialog];
    };
    
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

- (void)presentConfirmDeletionDialog {
    NSAlert *alert = [NSAlert confirmDeleteDeploymentDialog];
    
    [alert presentSheetModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSAlertDefaultReturn) {
            [[client deleteAppWithName:app.name] subscribeError:^(NSError *error) {
                [NSApp presentError:error];
            } completed:^{
                [self.breadcrumbController popViewControllerAnimated:YES];
            }];
        }
    }];
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
    [[AppDelegate shared] editDeployment:nil];
}

- (IBAction)deleteClicked:(id)sender {
    [self presentConfirmDeletionDialog];
}

- (RACSignal *)updateWithState:(FoundryAppState)state {
    [Log logFormat:@"updateWithState: %@ app = %@", FoundryAppStateStringFromState(state), app];
    return [client updateApp:app withState:state];
}

- (void)startClicked:(id)sender {
    [[AppDelegate shared] startDeployment:nil];
}

- (void)stopClicked:(id)sender {
    [[AppDelegate shared] stopDeployment:nil];
}

- (void)restartClicked:(id)sender {
    [[AppDelegate shared] restartDeployment:nil];
}

- (void)presentBindServiceDialog {
    [[AppDelegate shared] bindService:nil];
}

- (void)selectedService:(FoundryService *)service {
    NSLog(@"clicked bound service %@", service);
}

- (void)accessoryButtonClickedForService:(FoundryService *)service {
    NSAlert *alert = [NSAlert confirmUnbindServiceDialog];
    [alert presentSheetModalForWindow:self.view.window didEndBlock:^(NSInteger returnCode) {
        if (returnCode == NSAlertDefaultReturn) {
            [self updateAppAndStatsAfterSignal:[client updateApp:app byRemovingServiceNamed:service.name]];
        }
    }];
}

@end
