#import "BottomBar.h"

@interface TargetsView : NSView

@property (nonatomic, strong) BottomBar *bar;
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSMutableArray *targets;

- (id)initWithTargets:(NSArray *)lesTargets;

@end
