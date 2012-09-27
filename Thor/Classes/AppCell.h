#import "ListView.h"
#import "ThorCore.h"

@interface AppCell : ListCell

@property (nonatomic, strong) FoundryApp *app;
@property (nonatomic, strong) NSButton *button;

@end
