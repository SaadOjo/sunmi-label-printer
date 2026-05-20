//
//  SMInput.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/20.
//

#import "SMInput.h"

@interface SMInput ()

@property (nonatomic, strong) NSSecureTextField *input;

@end

@implementation SMInput

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                        style:(NSAlertStyle)style {
    self = [super init];
    if (self != nil) {
        self.alertStyle = style;
        self.icon = nil;
        self.messageText = [title description];
        self.informativeText = [message description];
        
        self.input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
        self.input.placeholderString = @"Please input wifi password";
        [self.input setStringValue:@""];
        [self setAccessoryView:self.input];
        
        [super addButtonWithTitle:@"OK"];
    }
    return self;
}

#pragma mark -- add button and handle

#pragma --mark show
- (void)show:(NSWindow *)window handler:(inputHandle)handler {
    [self beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
        handler(self);
    }];
}

- (NSString *)textFieldString {
    return self.input.stringValue;
}

@end
