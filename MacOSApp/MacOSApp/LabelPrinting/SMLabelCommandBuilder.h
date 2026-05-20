//
//  SMLabelCommandBuilder.h
//  MacOSApp
//
//  TSPL command builder for SUNMI label mode printers.
//

#import <Foundation/Foundation.h>
#import "SMLabelContent.h"
#import "SMLabelPrintSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMLabelCommandBuilder : NSObject

+ (NSString *)TSPLForSampleLabelWithSettings:(SMLabelPrintSettings *)settings
                                     content:(SMLabelContent *)content;

+ (NSData *)dataForSampleLabelWithSettings:(SMLabelPrintSettings *)settings
                                   content:(SMLabelContent *)content;

+ (NSString *)TSPLForDesignedLabelWithSettings:(SMLabelPrintSettings *)settings
                                         title:(NSString *)title
                                      subtitle:(NSString *)subtitle
                                         price:(NSString *)price
                                       barcode:(NSString *)barcode
                                            qr:(NSString *)qr;

/// Runs the printer's gap sensor calibration/alignment command for labels.
+ (NSData *)dataForGapCalibrationWithSettings:(SMLabelPrintSettings *)settings;

@end

NS_ASSUME_NONNULL_END
