//
//  SMReceiptContent.m
//  MacOSApp
//

#import "SMReceiptContent.h"

@implementation SMReceiptLineItem

+ (instancetype)itemWithName:(NSString *)name quantity:(NSInteger)quantity unitPrice:(double)unitPrice {
    SMReceiptLineItem *item = [[SMReceiptLineItem alloc] init];
    item.name = name ?: @"Item";
    item.quantity = MAX(1, quantity);
    item.unitPrice = unitPrice;
    return item;
}

- (double)lineTotal {
    return self.quantity * self.unitPrice;
}

@end

@implementation SMReceiptContent

+ (instancetype)sampleReceipt {
    SMReceiptContent *receipt = [[SMReceiptContent alloc] init];
    receipt.storeName = @"OJO Store";
    receipt.storeAddress = @"123 Market Street\nSan Francisco, CA";
    receipt.storePhone = @"+1 555 0100";
    receipt.orderNumber = @"R-10042";
    receipt.cashierName = @"Alex";
    receipt.footerText = @"Thank you for shopping with us";
    receipt.qrValue = @"https://ojo.example/receipt/R-10042";
    receipt.barcodeValue = @"100420001234";
    receipt.taxRate = 0.0825;
    receipt.items = @[
        [SMReceiptLineItem itemWithName:@"Thermal Label Roll" quantity:1 unitPrice:8.99],
        [SMReceiptLineItem itemWithName:@"Coffee" quantity:2 unitPrice:3.50],
        [SMReceiptLineItem itemWithName:@"Notebook" quantity:1 unitPrice:5.25],
    ];
    return receipt;
}

- (double)subtotal {
    double subtotal = 0;
    for (SMReceiptLineItem *item in self.items) {
        subtotal += item.lineTotal;
    }
    return subtotal;
}

- (double)tax {
    return self.subtotal * MAX(0, self.taxRate);
}

- (double)total {
    return self.subtotal + self.tax;
}

@end
