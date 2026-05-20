//
//  SunmiUSBPrinterManager.m
//  MacOSApp
//

#import "SunmiUSBPrinterManager.h"

#import <IOKit/IOCFPlugIn.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/usb/USB.h>

NSString * const SunmiUSBPrinterErrorDomain = @"SunmiUSBPrinterErrorDomain";

static const NSInteger SunmiVendorID = 0x324f;
static const NSInteger USBPrinterInterfaceClass = 7;
static const NSInteger USBPrinterInterfaceSubClass = 1;
static const NSUInteger USBWriteChunkSize = 16 * 1024;

@interface SunmiUSBPrinterManager ()
@property (nonatomic, assign, getter=isConnected) BOOL connected;
@property (nonatomic, copy, nullable) NSString *deviceName;
@property (nonatomic, copy, nullable) NSString *serialNumber;
@property (nonatomic, assign) NSInteger vendorID;
@property (nonatomic, assign) NSInteger productID;
@end

@implementation SunmiUSBPrinterManager

+ (instancetype)sharedManager {
    static SunmiUSBPrinterManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SunmiUSBPrinterManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _vendorID = SunmiVendorID;
    }
    return self;
}

#pragma mark - Public

- (BOOL)findPrinter:(NSError **)error {
    NSString *name = nil;
    NSString *serial = nil;
    NSInteger productID = 0;
    io_service_t service = [self copyPrinterInterfaceServiceWithName:&name serial:&serial productID:&productID error:error];
    if (!service) {
        self.connected = NO;
        self.deviceName = nil;
        self.serialNumber = nil;
        self.productID = 0;
        return NO;
    }

    IOObjectRelease(service);
    self.connected = YES;
    self.deviceName = name;
    self.serialNumber = serial;
    self.vendorID = SunmiVendorID;
    self.productID = productID;
    return YES;
}

- (void)sendPrintData:(NSData *)data completion:(void (^)(NSError * _Nullable))completion {
    NSData *payload = [data copy];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        [self sendPrintDataSynchronously:payload error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(error);
            }
        });
    });
}

#pragma mark - USB write

- (BOOL)sendPrintDataSynchronously:(NSData *)data error:(NSError **)error {
    if (data.length == 0) {
        [self populateError:error code:100 message:@"No print data to send."];
        return NO;
    }

    NSString *name = nil;
    NSString *serial = nil;
    NSInteger productID = 0;
    io_service_t service = [self copyPrinterInterfaceServiceWithName:&name serial:&serial productID:&productID error:error];
    if (!service) {
        self.connected = NO;
        return NO;
    }

    self.connected = YES;
    self.deviceName = name;
    self.serialNumber = serial;
    self.vendorID = SunmiVendorID;
    self.productID = productID;

    IOUSBInterfaceInterface **interface = NULL;
    UInt8 outPipe = 0;
    BOOL opened = [self openUSBInterfaceForService:service interface:&interface outPipe:&outPipe error:error];
    IOObjectRelease(service);
    if (!opened || !interface || outPipe == 0) {
        return NO;
    }

    IOReturn result = kIOReturnSuccess;
    const UInt8 *bytes = data.bytes;
    NSUInteger offset = 0;
    while (offset < data.length) {
        UInt32 chunkLength = (UInt32)MIN(USBWriteChunkSize, data.length - offset);
        result = (*interface)->WritePipe(interface, outPipe, (void *)(bytes + offset), chunkLength);
        if (result != kIOReturnSuccess) {
            break;
        }
        offset += chunkLength;
    }

    (*interface)->USBInterfaceClose(interface);
    (*interface)->Release(interface);

    if (result != kIOReturnSuccess) {
        [self populateError:error code:result message:[NSString stringWithFormat:@"USB WritePipe failed: 0x%08x", result]];
        return NO;
    }

    return YES;
}

- (BOOL)openUSBInterfaceForService:(io_service_t)service
                         interface:(IOUSBInterfaceInterface ***)interfaceOut
                           outPipe:(UInt8 *)outPipe
                             error:(NSError **)error {
    IOCFPlugInInterface **plugin = NULL;
    SInt32 score = 0;
    kern_return_t kr = IOCreatePlugInInterfaceForService(service,
                                                         kIOUSBInterfaceUserClientTypeID,
                                                         kIOCFPlugInInterfaceID,
                                                         &plugin,
                                                         &score);
    if (kr != KERN_SUCCESS || !plugin) {
        [self populateError:error code:kr message:[NSString stringWithFormat:@"Could not create USB plugin: 0x%08x", kr]];
        return NO;
    }

    IOUSBInterfaceInterface **interface = NULL;
    HRESULT queryResult = (*plugin)->QueryInterface(plugin,
                                                    CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
                                                    (LPVOID *)&interface);
    (*plugin)->Release(plugin);
    if (queryResult || !interface) {
        [self populateError:error code:(NSInteger)queryResult message:[NSString stringWithFormat:@"Could not query USB interface: 0x%08x", (unsigned int)queryResult]];
        return NO;
    }

    IOReturn result = (*interface)->USBInterfaceOpen(interface);
    if (result != kIOReturnSuccess) {
        (*interface)->Release(interface);
        [self populateError:error code:result message:[NSString stringWithFormat:@"Could not open USB printer interface: 0x%08x", result]];
        return NO;
    }

    UInt8 endpointCount = 0;
    result = (*interface)->GetNumEndpoints(interface, &endpointCount);
    if (result != kIOReturnSuccess) {
        (*interface)->USBInterfaceClose(interface);
        (*interface)->Release(interface);
        [self populateError:error code:result message:[NSString stringWithFormat:@"Could not read USB endpoint count: 0x%08x", result]];
        return NO;
    }

    UInt8 bulkOutPipe = 0;
    for (UInt8 pipe = 1; pipe <= endpointCount; pipe++) {
        UInt8 direction = 0;
        UInt8 number = 0;
        UInt8 transferType = 0;
        UInt16 maxPacketSize = 0;
        UInt8 interval = 0;
        result = (*interface)->GetPipeProperties(interface,
                                                 pipe,
                                                 &direction,
                                                 &number,
                                                 &transferType,
                                                 &maxPacketSize,
                                                 &interval);
        if (result == kIOReturnSuccess && direction == kUSBOut && transferType == kUSBBulk) {
            bulkOutPipe = pipe;
            break;
        }
    }

    if (bulkOutPipe == 0) {
        (*interface)->USBInterfaceClose(interface);
        (*interface)->Release(interface);
        [self populateError:error code:101 message:@"Could not find USB bulk OUT endpoint on printer interface."];
        return NO;
    }

    *interfaceOut = interface;
    *outPipe = bulkOutPipe;
    return YES;
}

#pragma mark - Discovery

- (io_service_t)copyPrinterInterfaceServiceWithName:(NSString **)name
                                             serial:(NSString **)serial
                                          productID:(NSInteger *)productID
                                              error:(NSError **)error {
    CFMutableDictionaryRef matching = IOServiceMatching("IOUSBHostInterface");
    if (!matching) {
        [self populateError:error code:102 message:@"Could not create USB matching dictionary."];
        return IO_OBJECT_NULL;
    }

    io_iterator_t iterator = IO_OBJECT_NULL;
    kern_return_t kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iterator);
    if (kr != KERN_SUCCESS) {
        [self populateError:error code:kr message:[NSString stringWithFormat:@"USB matching failed: 0x%08x", kr]];
        return IO_OBJECT_NULL;
    }

    io_service_t candidate = IO_OBJECT_NULL;
    while ((candidate = IOIteratorNext(iterator))) {
        NSInteger vendor = [self integerProperty:CFSTR("idVendor") forService:candidate];
        NSInteger interfaceClass = [self integerProperty:CFSTR("bInterfaceClass") forService:candidate];
        NSInteger interfaceSubClass = [self integerProperty:CFSTR("bInterfaceSubClass") forService:candidate];

        if (vendor == SunmiVendorID &&
            interfaceClass == USBPrinterInterfaceClass &&
            interfaceSubClass == USBPrinterInterfaceSubClass) {
            if (name) {
                *name = [self stringProperty:CFSTR("USB Product Name") forService:candidate] ?: @"SUNMI USB Printer";
            }
            if (serial) {
                *serial = [self stringProperty:CFSTR("USB Serial Number") forService:candidate];
            }
            if (productID) {
                *productID = [self integerProperty:CFSTR("idProduct") forService:candidate];
            }
            IOObjectRelease(iterator);
            return candidate;
        }

        IOObjectRelease(candidate);
    }

    IOObjectRelease(iterator);
    [self populateError:error code:103 message:@"No SUNMI USB printer-class device found. Make sure the printer is connected by USB and powered on."];
    return IO_OBJECT_NULL;
}

- (NSInteger)integerProperty:(CFStringRef)key forService:(io_service_t)service {
    NSInteger value = 0;
    CFTypeRef property = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0);
    if (property && CFGetTypeID(property) == CFNumberGetTypeID()) {
        CFNumberGetValue((CFNumberRef)property, kCFNumberNSIntegerType, &value);
    }
    if (property) {
        CFRelease(property);
    }
    return value;
}

- (NSString *)stringProperty:(CFStringRef)key forService:(io_service_t)service {
    NSString *value = nil;
    CFTypeRef property = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0);
    if (property && CFGetTypeID(property) == CFStringGetTypeID()) {
        value = [(__bridge NSString *)property copy];
    }
    if (property) {
        CFRelease(property);
    }
    return value;
}

#pragma mark - Errors

- (void)populateError:(NSError **)error code:(NSInteger)code message:(NSString *)message {
    if (!error) {
        return;
    }
    *error = [NSError errorWithDomain:SunmiUSBPrinterErrorDomain
                                 code:code
                             userInfo:@{NSLocalizedDescriptionKey: message ?: @"USB printer error"}];
}

@end
