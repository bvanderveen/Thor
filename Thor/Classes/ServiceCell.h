#import "ListView.h"
#import "ThorCore.h"

@interface ServiceCell : ListCell

@property (nonatomic, strong) FoundryService *service;
@property (nonatomic, strong) NSButton *button;

@end
