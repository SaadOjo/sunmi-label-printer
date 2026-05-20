#import "OJOPrinterBridge.h"
#import <SunmiPrinterMacOS/SunmiPrinterCommand.h>
#import <SunmiPrinterMacOS/SunmiPrinterIPManager.h>
#import <SunmiPrinterMacOS/SunmiIpPrinterModel.h>

@interface OJOPrinterBridge () <IPPrinterManagerDelegate>
@property (nonatomic, assign, readwrite) BOOL connected;
@property (nonatomic, copy, readwrite, nullable) NSString *connectedIPAddress;
@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSString *> *> *discoveredPrinters;
@property (nonatomic, copy, nullable) void (^discoveryCompletion)(NSArray<NSDictionary<NSString *, NSString *> *> *printers,
                                                              NSString * _Nullable errorMessage);
@property (nonatomic, assign) BOOL discoveryFinished;
@end

@implementation OJOPrinterBridge

+ (NSString *)sdkVersion {
    NSString *version = [SunmiPrinterCommand getSDKVersion];
    return version.length ? version : @"Unknown";
}

- (void)discoverPrintersWithCompletion:(void (^)(NSArray<NSDictionary<NSString *, NSString *> *> *printers,
                                                 NSString * _Nullable errorMessage))completion {
    self.discoveredPrinters = [NSMutableArray array];
    self.discoveryCompletion = completion;
    self.discoveryFinished = NO;

    SunmiPrinterIPManager *manager = [SunmiPrinterIPManager sharedManager];
    manager.delegate = self;
    [manager startSearchPrinterWithIp:nil];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || self.discoveryFinished) {
            return;
        }
        [self finishDiscoveryWithError:nil];
    });
}

- (void)connectToIP:(NSString *)ipAddress
         completion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion {
    NSString *trimmedIP = [ipAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedIP.length == 0) {
        if (completion) {
            completion(NO, @"Enter a printer IP address.");
        }
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[SunmiPrinterIPManager sharedManager] connectSocketWithIP:trimmedIP completeBlock:^(NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            if (err) {
                self.connected = NO;
                self.connectedIPAddress = nil;
                if (completion) {
                    completion(NO, err.localizedDescription ?: @"Failed to connect to printer.");
                }
                return;
            }

            // Match the original SDK sample behavior: nil error means the SDK accepted the IP connection.
            // Some SDK builds update isConnectedIPService slightly later than the callback.
            self.connected = YES;
            self.connectedIPAddress = trimmedIP;
            if (completion) {
                completion(YES, nil);
            }
        });
    }];
}

- (void)disconnect {
    [[SunmiPrinterIPManager sharedManager] disConnectIPService];
    self.connected = NO;
    self.connectedIPAddress = nil;
}

- (void)sendData:(NSData *)data
      completion:(void (^)(BOOL success, NSString * _Nullable errorMessage))completion {
    if (data.length == 0) {
        if (completion) {
            completion(NO, @"No print data was generated.");
        }
        return;
    }

    if (!self.connected) {
        if (completion) {
            completion(NO, @"Connect to the printer before printing.");
        }
        return;
    }

    [[SunmiPrinterIPManager sharedManager] controlDevicePrintingData:data];
    if (completion) {
        completion(YES, nil);
    }
}

#pragma mark - IPPrinterManagerDelegate

- (void)discoverIPPrinter:(SunmiIpPrinterModel *)printerModel {
    NSString *ip = printerModel.deviceIP ?: @"";
    if (ip.length == 0) {
        return;
    }

    for (NSDictionary<NSString *, NSString *> *printer in self.discoveredPrinters) {
        if ([printer[@"ip"] isEqualToString:ip]) {
            return;
        }
    }

    NSDictionary<NSString *, NSString *> *printer = @{
        @"ip": ip,
        @"name": printerModel.deviceName ?: @"SUNMI printer",
        @"model": printerModel.deviceMode ?: @"",
        @"sn": printerModel.deviceSN ?: @""
    };
    [self.discoveredPrinters addObject:printer];
}

- (void)finshedSearchPrinter {
    [self finishDiscoveryWithError:nil];
}

- (void)finishDiscoveryWithError:(NSString * _Nullable)errorMessage {
    if (self.discoveryFinished) {
        return;
    }
    self.discoveryFinished = YES;

    NSArray<NSDictionary<NSString *, NSString *> *> *printers = [self.discoveredPrinters copy] ?: @[];
    void (^completion)(NSArray<NSDictionary<NSString *, NSString *> *> *, NSString *) = self.discoveryCompletion;
    self.discoveryCompletion = nil;

    if (completion) {
        completion(printers, errorMessage);
    }
}

@end
