//
//  SMLabelRasterCommandBuilder.h
//  MacOSApp
//
//  WYSIWYG label printing by rendering the whole design to a monochrome TSPL
//  BITMAP. This enables arbitrary macOS fonts and imported images.
//

#import <Foundation/Foundation.h>
#import "SMDesignerElement.h"
#import "../LabelPrinting/SMLabelPrintSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMLabelRasterCommandBuilder : NSObject

+ (NSData *)dataForDesignedLabelWithSettings:(SMLabelPrintSettings *)settings
                                    elements:(NSArray<SMDesignerElement *> *)elements;

+ (NSString *)summaryForDesignedLabelWithSettings:(SMLabelPrintSettings *)settings
                                         elements:(NSArray<SMDesignerElement *> *)elements;

@end

NS_ASSUME_NONNULL_END
