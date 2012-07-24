#import "BottomBar.h"

@interface AppsView : NSView

@property (nonatomic, strong) BottomBar *bar;
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSMutableArray *apps;

- (id)initWithApps:(NSArray *)lesApps;

@end
