//
//  SMAlert.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/17.
//

#import "SMAlert.h"

@implementation SMAlertItem

@end

@interface SMAlert ()
{
    NSMutableArray *_items;
}

@end

@implementation SMAlert

- (id)initWithTitle:(NSString *)title message:(NSString *)message style:(NSAlertStyle)style{
    self = [super init];
    if (self != nil)
    {
        _items = [NSMutableArray array];
        self.alertStyle = style;
        self.icon = nil;
        self.messageText = [title description];
        self.informativeText = [message description];
    }
    return self;
}

+ (id)alertWithTitle:(NSString *)title message:(NSString *)message style:(NSAlertStyle)style{
    return [[self alloc] initWithTitle:title message:message style:style];
}

#pragma mark -- add button and handle
- (NSInteger)addButtonWithTitle:(NSString *)title{
    NSAssert(title != nil, @"all title must be non-nil");
    SMAlertItem *item =  [self addCommonButtonWithTitle:title handler:^(SMAlertItem *item) {
        NSLog(@"no action");
    }];
    return [_items indexOfObject:item];
}

- (SMAlertItem *)addCommonButtonWithTitle:(NSString *)title handler:(SunmiAlertHandler)handler{
   return [self addButtonWithTitle:title handler:handler];
}

- (SMAlertItem *)addButtonWithTitle:(NSString *)title handler:(SunmiAlertHandler)handler{
    NSAssert(title != nil, @"all title must be non-nil");
    SMAlertItem *item = [[SMAlertItem alloc] init];
    item.title = [title description];
    item.action = handler;
    [super addButtonWithTitle:[title description]];
    [_items addObject:item];
    item.tag = [_items indexOfObject:item];
    return item;
}

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex{
    SMAlertItem *item = _items[buttonIndex];
    return item.title;
}

- (NSArray *)actions {
    return [_items copy];
}

#pragma --mark show
- (void)show:(NSWindow *)window {
    [self  beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
        SMAlertItem *item = self->_items[returnCode-1000];
        item.action(item);
    }];
//    [window becomeKeyWindow];
}

//-(void)show {
//    NSRect frame = NSMakeRect(0, 0, 200, 100);
//    NSUInteger styleMask =    NSWindowStyleMaskBorderless;
////    NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
//    NSWindow * window =  [[NSWindow alloc] initWithContentRect:frame styleMask:styleMask backing: NSBackingStoreBuffered defer:false];
//    [window setBackgroundColor:[NSColor clearColor]];
//    [window makeKeyAndOrderFront:window];
//    [window orderFrontRegardless];
//    [window center];
//    [self  beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
//        SMAlertItem *item = self->_items[returnCode-1000];
//        item.action(item);
//    }];
//    [window becomeKeyWindow];
//}

@end
