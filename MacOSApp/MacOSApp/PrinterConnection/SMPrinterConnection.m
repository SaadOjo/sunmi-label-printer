//
//  SMPrinterConnection.m
//  MacOSApp
//

#import "SMPrinterConnection.h"
#import "../SunmiUSBPrinterManager.h"

@implementation SMPrinterConnection

- (instancetype)init {
    self = [super init];
    if (self) {
        _type = PrintConnectUSB;
    }
    return self;
}

- (BOOL)isConnected {
    switch (self.type) {
        case PrintConnectBluetooth:
            return self.blePrinterModel != nil;
        case PrintConnectIP:
            return self.ipPrinterModel != nil || [[SunmiPrinterIPManager sharedManager] isConnectedIPService];
        case PrintConnectUSB:
            return self.isUSBConnected || [SunmiUSBPrinterManager sharedManager].isConnected;
        default:
            return NO;
    }
}

- (NSString *)displayName {
    switch (self.type) {
        case PrintConnectBluetooth:
            return self.blePrinterModel.deviceName ?: @"Bluetooth printer";
        case PrintConnectIP:
            return self.ipPrinterModel.deviceName ?: self.ipPrinterModel.deviceIP ?: self.manualIPAddress ?: @"IP printer";
        case PrintConnectUSB: {
            SunmiUSBPrinterManager *usb = [SunmiUSBPrinterManager sharedManager];
            if (usb.deviceName.length && usb.serialNumber.length) {
                return [NSString stringWithFormat:@"%@ (%@)", usb.deviceName, usb.serialNumber];
            }
            return usb.deviceName ?: @"SUNMI USB printer";
        }
        default:
            return @"No printer";
    }
}

- (void)setBluetoothPrinter:(SunmiBlePrinterModel *)model {
    self.type = PrintConnectBluetooth;
    self.blePrinterModel = model;
    self.ipPrinterModel = nil;
    self.manualIPAddress = nil;
    self.USBConnected = NO;
}

- (void)setIPPrinter:(SunmiIpPrinterModel *)model {
    self.type = PrintConnectIP;
    self.ipPrinterModel = model;
    self.manualIPAddress = model.deviceIP;
    self.blePrinterModel = nil;
    self.USBConnected = NO;
}

- (void)connectIPWithAddress:(NSString *)ipAddress completion:(void (^)(NSError * _Nullable))completion {
    NSString *trimmedIP = [ipAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedIP.length == 0) {
        NSError *error = [NSError errorWithDomain:@"SMPrinterConnection"
                                             code:3
                                         userInfo:@{NSLocalizedDescriptionKey: @"Enter the printer IP address."}];
        if (completion) {
            completion(error);
        }
        return;
    }

    [[SunmiPrinterIPManager sharedManager] connectSocketWithIP:trimmedIP completeBlock:^(NSError *err) {
        if (!err) {
            SunmiIpPrinterModel *model = [[SunmiIpPrinterModel alloc] init];
            model.deviceIP = trimmedIP;
            model.deviceName = [NSString stringWithFormat:@"LAN Printer %@", trimmedIP];
            self.type = PrintConnectIP;
            self.ipPrinterModel = model;
            self.manualIPAddress = trimmedIP;
            self.blePrinterModel = nil;
            self.USBConnected = NO;
        }
        if (completion) {
            completion(err);
        }
    }];
}

- (BOOL)connectUSB:(NSError **)error {
    SunmiUSBPrinterManager *usb = [SunmiUSBPrinterManager sharedManager];
    BOOL success = [usb findPrinter:error];
    if (success) {
        self.type = PrintConnectUSB;
        self.USBConnected = YES;
        self.blePrinterModel = nil;
        self.ipPrinterModel = nil;
        self.manualIPAddress = nil;
    }
    return success;
}

- (void)disconnect {
    if (self.type == PrintConnectBluetooth) {
        [[SunmiPrinterManager shareInstance] disConnectPeripheral];
    }
    if (self.type == PrintConnectIP) {
        [[SunmiPrinterIPManager sharedManager] disConnectIPService];
    }
    self.blePrinterModel = nil;
    self.ipPrinterModel = nil;
    self.manualIPAddress = nil;
    self.USBConnected = NO;
}

- (void)sendData:(NSData *)data completion:(void (^)(NSError * _Nullable))completion {
    if (data.length == 0) {
        NSError *error = [NSError errorWithDomain:@"SMPrinterConnection"
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey: @"No print data."}];
        if (completion) {
            completion(error);
        }
        return;
    }

    if (self.type == PrintConnectBluetooth && self.blePrinterModel) {
        [[SunmiPrinterManager shareInstance] sendPrintData:data];
        if (completion) {
            completion(nil);
        }
        return;
    }

    if (self.type == PrintConnectIP && self.isConnected) {
        [[SunmiPrinterIPManager sharedManager] controlDevicePrintingData:data];
        if (completion) {
            completion(nil);
        }
        return;
    }

    if (self.type == PrintConnectUSB && self.isConnected) {
        [[SunmiUSBPrinterManager sharedManager] sendPrintData:data completion:completion];
        return;
    }

    NSError *error = [NSError errorWithDomain:@"SMPrinterConnection"
                                         code:2
                                     userInfo:@{NSLocalizedDescriptionKey: @"No printer connected."}];
    if (completion) {
        completion(error);
    }
}

@end
