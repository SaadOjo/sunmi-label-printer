//
//  SMReceiptPrintSettings.h
//  MacOSApp
//
//  Receipt/ESC-POS print settings.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMReceiptPrintSettings : NSObject

/// Printable width in printer dots. Common values: 384 (58mm), 576 (80mm).
@property (nonatomic, assign) NSInteger paperWidthDots;
/// Monospaced character columns used for text preview/receipt formatting.
@property (nonatomic, assign) NSInteger characterColumns;
/// SUNMI receipt density range is typically 70~130.
@property (nonatomic, assign) NSInteger density;
/// SUNMI receipt speed range is typically 0~250.
@property (nonatomic, assign) NSInteger speed;
@property (nonatomic, assign) BOOL includeLogo;
@property (nonatomic, assign) BOOL cutPaper;
@property (nonatomic, assign) BOOL openCashDrawer;

+ (instancetype)default80mmSettings;
+ (instancetype)default58mmSettings;

@end

NS_ASSUME_NONNULL_END
