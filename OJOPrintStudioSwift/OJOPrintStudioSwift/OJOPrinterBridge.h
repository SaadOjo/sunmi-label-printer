#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OJOPrinterBridge : NSObject

@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, copy, readonly, nullable) NSString *connectedIPAddress;

+ (NSString *)sdkVersion;

- (void)discoverPrintersWithCompletion:(void (^)(NSArray<NSDictionary<NSString *, NSString *> *> *printers,
                                                 NSString * _Nullable errorMessage))completion NS_SWIFT_NAME(discoverPrinters(completion:));

- (void)connectToIP:(NSString *)ipAddress
         completion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion NS_SWIFT_NAME(connect(toIP:completion:));

- (void)disconnect;

- (void)sendData:(NSData *)data
      completion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion NS_SWIFT_NAME(send(_:completion:));

@end

NS_ASSUME_NONNULL_END
