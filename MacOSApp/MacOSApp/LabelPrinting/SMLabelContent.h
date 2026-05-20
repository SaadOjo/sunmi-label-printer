//
//  SMLabelContent.h
//  MacOSApp
//
//  Example business data for a label. A designer app can later replace this
//  with canvas elements while still using SMLabelCommandBuilder.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMLabelContent : NSObject

@property (nonatomic, copy) NSString *brand;
@property (nonatomic, copy) NSString *productName;
@property (nonatomic, copy) NSString *sku;
@property (nonatomic, copy) NSString *price;
@property (nonatomic, copy) NSString *qrValue;

+ (instancetype)sampleContent;

@end

NS_ASSUME_NONNULL_END
