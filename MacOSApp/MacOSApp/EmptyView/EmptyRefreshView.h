//
//  EmptyRefreshView.h
//  MacOSApp
//
//  Created by SM2368 on 2023/11/16.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmptyRefreshView : NSView

@property (nonatomic, copy) void(^refreshBlock)(void);

- (void)setLogo:(NSString *)logoString;
- (void)setTip_up:(NSString *)tip_1_string;
- (void)setTip_down:(NSString *)tip_2_string;

@end

NS_ASSUME_NONNULL_END
