//
//  DeviceListViewController.h
//  MacOSApp
//
//  Created by SM2368 on 2023/11/15.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class SunmiBlePrinterModel;
@class SunmiIpPrinterModel;

@interface DeviceListViewController : NSViewController

@property (nonatomic, assign) PrintConnectType printType;
@property(nonatomic, copy)void (^connectedStatusBlock)(SunmiBlePrinterModel *model, PrintConnectType printConnectType);
@property(nonatomic, copy)void (^connectedIPStatusBlock)(SunmiIpPrinterModel *model, PrintConnectType printConnectType);

@end

NS_ASSUME_NONNULL_END
