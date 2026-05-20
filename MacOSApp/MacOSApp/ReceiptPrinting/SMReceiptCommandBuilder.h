//
//  SMReceiptCommandBuilder.h
//  MacOSApp
//
//  ESC/POS receipt command builder using the SUNMI macOS SDK command API.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "SMReceiptContent.h"
#import "SMReceiptPrintSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface SMReceiptCommandBuilder : NSObject

+ (NSData *)dataForReceiptWithSettings:(SMReceiptPrintSettings *)settings
                               content:(SMReceiptContent *)content;

+ (NSString *)plainTextPreviewForReceiptWithSettings:(SMReceiptPrintSettings *)settings
                                             content:(SMReceiptContent *)content;

/// Renders a visual preview using the same receipt model and the same bounded
/// logo/image dimensions used by the ESC/POS command builder.
+ (NSImage *)previewImageForReceiptWithSettings:(SMReceiptPrintSettings *)settings
                                        content:(SMReceiptContent *)content;

@end

NS_ASSUME_NONNULL_END
