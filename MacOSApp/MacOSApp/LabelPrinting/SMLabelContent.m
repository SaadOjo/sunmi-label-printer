//
//  SMLabelContent.m
//  MacOSApp
//

#import "SMLabelContent.h"

@implementation SMLabelContent

+ (instancetype)sampleContent {
    SMLabelContent *content = [[SMLabelContent alloc] init];
    content.brand = @"OJO";
    content.productName = @"Sample Item";
    content.sku = @"SKU001234";
    content.price = @"$9.99";
    content.qrValue = @"SKU001234";
    return content;
}

@end
