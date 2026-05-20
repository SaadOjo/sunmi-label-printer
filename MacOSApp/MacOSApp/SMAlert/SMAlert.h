//
//  SMAlert.h
//  MacOSApp
//
//  Created by SM2368 on 2023/11/17.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SMAlertItem;
typedef void(^SunmiAlertHandler)(SMAlertItem *item);

@interface SMAlert : NSAlert

@property (nonatomic, readonly) NSArray *actions;

- (id)initWithTitle:(NSString *)title message:(NSString *)message style:(NSAlertStyle)style;
+ (id)alertWithTitle:(NSString *)title message:(NSString *)message  style:(NSAlertStyle)style;

- (NSInteger)addButtonWithTitle:(NSString *)title;
- (SMAlertItem *)addCommonButtonWithTitle:(NSString *)title handler:(SunmiAlertHandler)handler;
- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;

- (void)show:(NSWindow *)window;
//- (void)show;

@end

@interface SMAlertItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSUInteger tag;
@property (nonatomic, copy) SunmiAlertHandler action;

@end

NS_ASSUME_NONNULL_END
