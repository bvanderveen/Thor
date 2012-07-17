
@interface AppsView : NSView

@property (nonatomic, strong) NSMutableArray *apps;
- (id)initWithApps:(NSArray *)lesApps;
@property (nonatomic, unsafe_unretained) id delegate;
@end
