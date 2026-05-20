//
//  CustomTableCellView.h
//  MacOSApp
//
//  Created by SM2368 on 2023/11/20.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomTableCellView : NSTableCellView

@property (nonatomic, copy) NSString *wifieName;
@property (nonatomic, assign) BOOL hasPassword;
@property (nonatomic, copy) NSString *rssiNum;

- (void)wifiName:(NSString *)name withPassword:(BOOL)hasPassword rssi:(NSString *)rssiNum;

@end

NS_ASSUME_NONNULL_END
