#import "URICharactersOnlyTextFieldDelegate.h"

@interface URICharactersOnlyTextFieldDelegate ()

@property (nonatomic, copy) NSString *previousStringValue;

@end

@implementation URICharactersOnlyTextFieldDelegate

@synthesize previousStringValue;

- (void)controlTextDidBeginEditing:(NSNotification *)notification {
    NSTextField *textField = notification.object;
    self.previousStringValue = textField.stringValue;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = notification.object;
    // from rfc 3986 section 2.2
    NSCharacterSet *illegalChars = [NSCharacterSet characterSetWithCharactersInString:@":/?#[]@!$&'()*+,;="];
    
    if ([textField.stringValue rangeOfCharacterFromSet:illegalChars].location != NSNotFound) {
        textField.stringValue = self.previousStringValue;
        NSBeep();
    }
    else
        self.previousStringValue = textField.stringValue;
}

@end
