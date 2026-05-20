//
//  SMInput.h
//  MacOSApp
//
//  Created by SM2368 on 2023/11/20.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMInput : NSAlert

typedef void(^inputHandle)(SMInput *item);

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                        style:(NSAlertStyle)style;

- (void)show:(NSWindow *)window handler:(inputHandle)handler;

@property (nonatomic, copy) NSString *textFieldString;

@end

NS_ASSUME_NONNULL_END


