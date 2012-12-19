#import "BreadcrumbController.h"
#import "TargetView.h"
#import "ListView.h"
#import "ThorCore.h"

@interface TargetSummary : NSObject

@property (nonatomic, assign) NSInteger appCount;
@property (nonatomic, assign) NSInteger totalMemoryMegabytes, totalDiskMegabytes;

@end

@interface TargetController : NSViewController <BreadcrumbControllerAware, BreadcrumbItem>

@property (nonatomic, strong) IBOutlet Target *target;
@property (nonatomic, strong) IBOutlet TargetSummary *targetSummary;
@property (nonatomic, strong) IBOutlet TargetView *targetView;
@property (nonatomic, strong) FoundryClient *client;

- (void)createNewService;
- (void)createNewDeployment;

- (void)updateApps;

@end
