//
//  SMPrinterConnection.h
//  MacOSApp
//
//  Small transport facade used by the UI and future designer/printer screens.
//

#import <Foundation/Foundation.h>
#import <SunmiPrinterMacOS/SunmiPrinterMacOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMPrinterConnection : NSObject

@property (nonatomic, assign) PrintConnectType type;
@property (nonatomic, strong, nullable) SunmiBlePrinterModel *blePrinterModel;
@property (nonatomic, strong, nullable) SunmiIpPrinterModel *ipPrinterModel;
@property (nonatomic, copy, nullable) NSString *manualIPAddress;
@property (nonatomic, assign, getter=isUSBConnected) BOOL USBConnected;

@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, copy, readonly) NSString *displayName;

- (void)setBluetoothPrinter:(SunmiBlePrinterModel *)model;
- (void)setIPPrinter:(SunmiIpPrinterModel *)model;
- (void)connectIPWithAddress:(NSString *)ipAddress completion:(void(^)(NSError * _Nullable error))completion;
- (BOOL)connectUSB:(NSError * _Nullable * _Nullable)error;
- (void)disconnect;

- (void)sendData:(NSData *)data completion:(void(^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
