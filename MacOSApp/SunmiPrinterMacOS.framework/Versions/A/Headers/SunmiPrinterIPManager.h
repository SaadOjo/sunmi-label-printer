//
//  SunmiPrinterIPManager.h
//  SMPrintLibary
//
//  Created by SM2368 on 2022/10/8.
//

#import <Foundation/Foundation.h>
#import <SunmiPrinterMacOS/SunmiPrinterHeader.h>

#define PrintStateCode 101

/**
 * 连接打印机结果
 *
 * @param err 连接失败信息
 */
typedef void (^connectIPDeviceErrorBlock)(NSError *err);

/**
 * 发送数据成功
 */
typedef void (^sendIPDeviceDataSuccessBlock)(void);

/**
 * 发送数据失败
 *
 * @param err 错误信息
 */
typedef void (^sendIPDeviceDataFailBlock)(NSError *err);

/**
 * 接收数据
 *
 * @param deviceSN 设备 SN
 * @param printerStatus 打印机状态
 * @param taskNumber 任务编号
 */
typedef void (^receivedIPDeviceDataBlock)(NSString *deviceSN, SMPrinterStatus printerStatus, NSString *taskNumber);


@class SunmiIpPrinterModel;

@protocol IPPrinterManagerDelegate <NSObject>

/**
 * 搜索到的 IP 打印机设备
 *
 @param printerModel   打印机设备模型，详见 SunmiIpPrinterModel.h
*/
- (void)discoverIPPrinter:(SunmiIpPrinterModel *)printerModel;

/**
 * 搜索IP设备结束
 */
- (void)finshedSearchPrinter;

@end


@interface SunmiPrinterIPManager : NSObject

@property (nonatomic, weak) id<IPPrinterManagerDelegate>delegate;

+ (instancetype)sharedManager;

/**
 * 搜索设备
 * 默认搜索全部设备（传 nil）
 *
 * @param searchPrinter   指定 ip 地址
 */
- (void)startSearchPrinterWithIp:(NSString *)searchPrinter;

/**
 * 连接设备
 *
 * @param ip 当前设备 ip
 * @param completeBlock 回调结果
 */
- (void)connectSocketWithIP:(NSString *)ip completeBlock:(connectIPDeviceErrorBlock)completeBlock;

/**
 * 设备连接断开了
 *
 * @param block   回调结果
 */
- (void)deviceDisConnectWithBlock:(void(^)(NSError *error))block;

/**
 * 当前 IP 设备连接状态
 */
- (BOOL)isConnectedIPService;

/**
 * 断开已连接的 IP 设备
 */
- (void)disConnectIPService;

/**
 * 向设备发送数据
 */
- (void)controlDevicePrintingData:(NSData *)ipData;

/**
 * 发送数据成功
 */
- (void)sendSuccess:(sendIPDeviceDataSuccessBlock)block;

/**
 * 发送数据失败
 */
- (void)sendFail:(sendIPDeviceDataFailBlock)block;

/**
 * 接收打印机返回数据
 */
- (void)receivedDeviceData:(receivedIPDeviceDataBlock)block;


@end
