//
//  SMReceiptContent.h
//  MacOSApp
//
//  Simple receipt domain model used by the app UI and command builder.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMReceiptLineItem : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger quantity;
@property (nonatomic, assign) double unitPrice;

+ (instancetype)itemWithName:(NSString *)name quantity:(NSInteger)quantity unitPrice:(double)unitPrice;
- (double)lineTotal;

@end

@interface SMReceiptContent : NSObject

@property (nonatomic, copy) NSString *storeName;
@property (nonatomic, copy) NSString *storeAddress;
@property (nonatomic, copy) NSString *storePhone;
@property (nonatomic, copy) NSString *orderNumber;
@property (nonatomic, copy) NSString *cashierName;
@property (nonatomic, copy) NSString *footerText;
@property (nonatomic, copy) NSString *qrValue;
@property (nonatomic, copy) NSString *barcodeValue;
@property (nonatomic, strong) NSArray<SMReceiptLineItem *> *items;
@property (nonatomic, assign) double taxRate;

+ (instancetype)sampleReceipt;
- (double)subtotal;
- (double)tax;
- (double)total;

@end

NS_ASSUME_NONNULL_END
