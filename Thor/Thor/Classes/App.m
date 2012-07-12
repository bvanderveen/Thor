#import "App.h"

@implementation App

@synthesize name;

+ (NSArray *)fakeApps {
    App *app0 = [App new];
    app0.name = @"Corn";
    App *app1 = [App new];
    app1.name = @"Pants";
    App *app2 = [App new];
    app2.name = @"Gordon";
    
    return [NSArray arrayWithObjects:app0, app1, app2, nil];
}

@end
