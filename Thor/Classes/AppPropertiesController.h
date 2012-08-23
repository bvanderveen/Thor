#import "AppPropertiesView.h"

@interface AppPropertiesController : NSViewController

@property (nonatomic, assign) BOOL editing;
@property (nonatomic, strong) IBOutlet App *app;
@property (nonatomic, strong) IBOutlet AppPropertiesView *appPropertiesView;

- (IBAction)buttonClicked:(NSButton *)button;

@end
