//
//  SMLabelCommandBuilder.m
//  MacOSApp
//

#import "SMLabelCommandBuilder.h"

@implementation SMLabelCommandBuilder

+ (NSData *)dataForSampleLabelWithSettings:(SMLabelPrintSettings *)settings
                                   content:(SMLabelContent *)content {
    NSString *tspl = [self TSPLForSampleLabelWithSettings:settings content:content];
    return [tspl dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)TSPLForSampleLabelWithSettings:(SMLabelPrintSettings *)settings
                                     content:(SMLabelContent *)content {
    SMLabelPrintSettings *s = settings ?: [SMLabelPrintSettings default50x20Settings];
    SMLabelContent *c = content ?: [SMLabelContent sampleContent];

    // SUNMI/TSC TSPL at 203 DPI: 1 mm ~= 8 dots.
    // A 50x20mm label is about 400x160 dots. Keep this sample simple and
    // high-contrast so a transport/sensor issue is easy to distinguish from a
    // layout issue. The border bars should be visible even if text/barcode
    // rendering is model-specific.
    NSString *brand = [self escapedTSPLString:c.brand maxLength:16];
    NSString *product = [self escapedTSPLString:c.productName maxLength:22];
    NSString *sku = [self escapedTSPLString:c.sku maxLength:20];
    NSString *price = [self escapedTSPLString:c.price maxLength:10];

    NSMutableString *tspl = [NSMutableString string];
    [tspl appendFormat:@"SIZE %@ mm,%@ mm\r\n", [self numberString:s.widthMM], [self numberString:s.heightMM]];
    [tspl appendFormat:@"GAP %@ mm,0\r\n", [self numberString:s.gapMM]];
    [tspl appendFormat:@"SPEED %ld\r\n", (long)s.speed];
    [tspl appendFormat:@"DENSITY %ld\r\n", (long)s.density];
    [tspl appendFormat:@"DIRECTION %ld\r\n", (long)s.direction];
    [tspl appendString:@"REFERENCE 0,0\r\n"];
    [tspl appendString:@"OFFSET 0 mm\r\n"];
    if (s.alignToGapBeforePrint) {
        // Disabled by default. HOME intentionally feeds to the next label and
        // is best used from the separate Calibrate / Align action.
        [tspl appendString:@"HOME\r\n"];
    }
    [tspl appendString:@"CLS\r\n"];

    // Visible border/test bars for 50x20mm media.
    [tspl appendString:@"BAR 8,8,384,4\r\n"];
    [tspl appendString:@"BAR 8,148,384,4\r\n"];
    [tspl appendString:@"BAR 8,8,4,144\r\n"];
    [tspl appendString:@"BAR 388,8,4,144\r\n"];

    [tspl appendFormat:@"TEXT 18,18,\"3\",0,1,1,\"%@\"\r\n", brand];
    [tspl appendFormat:@"TEXT 18,52,\"1\",0,1,1,\"%@\"\r\n", product];
    [tspl appendFormat:@"BARCODE 18,78,\"128\",42,0,0,2,2,\"%@\"\r\n", sku];
    [tspl appendFormat:@"TEXT 18,126,\"1\",0,1,1,\"%@\"\r\n", sku];
    [tspl appendFormat:@"TEXT 294,24,\"3\",0,1,1,\"%@\"\r\n", price];
    [tspl appendFormat:@"PRINT %ld,1\r\n", (long)MAX(1, s.copies)];
    return tspl;
}

+ (NSString *)TSPLForDesignedLabelWithSettings:(SMLabelPrintSettings *)settings
                                         title:(NSString *)title
                                      subtitle:(NSString *)subtitle
                                         price:(NSString *)price
                                       barcode:(NSString *)barcode
                                            qr:(NSString *)qr {
    SMLabelPrintSettings *s = settings ?: [SMLabelPrintSettings default50x20Settings];
    NSInteger widthDots = MAX(160, (NSInteger)round(s.widthMM * 8.0));
    NSInteger heightDots = MAX(80, (NSInteger)round(s.heightMM * 8.0));

    NSString *safeTitle = [self escapedTSPLString:title.length ? title : @"Product" maxLength:24];
    NSString *safeSubtitle = [self escapedTSPLString:subtitle.length ? subtitle : @"Description" maxLength:32];
    NSString *safePrice = [self escapedTSPLString:price.length ? price : @"$0.00" maxLength:12];
    NSString *safeBarcode = [self escapedTSPLString:barcode.length ? barcode : @"SKU001234" maxLength:24];
    NSString *safeQR = [self escapedTSPLString:qr.length ? qr : safeBarcode maxLength:64];

    NSInteger rightColumnX = MAX(220, widthDots - 104);
    NSInteger bottomY = MAX(70, heightDots - 34);
    NSInteger barcodeY = MAX(70, heightDots - 82);
    NSInteger barcodeHeight = MIN(46, MAX(28, heightDots - barcodeY - 34));

    NSMutableString *tspl = [NSMutableString string];
    [tspl appendFormat:@"SIZE %@ mm,%@ mm\r\n", [self numberString:s.widthMM], [self numberString:s.heightMM]];
    [tspl appendFormat:@"GAP %@ mm,0\r\n", [self numberString:s.gapMM]];
    [tspl appendFormat:@"SPEED %ld\r\n", (long)s.speed];
    [tspl appendFormat:@"DENSITY %ld\r\n", (long)s.density];
    [tspl appendFormat:@"DIRECTION %ld\r\n", (long)s.direction];
    [tspl appendString:@"REFERENCE 0,0\r\n"];
    [tspl appendString:@"OFFSET 0 mm\r\n"];
    [tspl appendString:@"CLS\r\n"];
    [tspl appendFormat:@"BAR 8,8,%ld,3\r\n", (long)MAX(10, widthDots - 16)];
    [tspl appendFormat:@"BAR 8,%ld,%ld,3\r\n", (long)MAX(12, heightDots - 10), (long)MAX(10, widthDots - 16)];
    [tspl appendFormat:@"TEXT 18,18,\"3\",0,1,1,\"%@\"\r\n", safeTitle];
    [tspl appendFormat:@"TEXT 18,52,\"1\",0,1,1,\"%@\"\r\n", safeSubtitle];
    [tspl appendFormat:@"BARCODE 18,%ld,\"128\",%ld,0,0,2,2,\"%@\"\r\n", (long)barcodeY, (long)barcodeHeight, safeBarcode];
    [tspl appendFormat:@"TEXT 18,%ld,\"1\",0,1,1,\"%@\"\r\n", (long)bottomY, safeBarcode];
    [tspl appendFormat:@"TEXT %ld,22,\"3\",0,1,1,\"%@\"\r\n", (long)rightColumnX, safePrice];
    if (widthDots >= 360 && heightDots >= 150) {
        [tspl appendFormat:@"QRCODE %ld,%ld,L,3,A,0,\"%@\"\r\n", (long)rightColumnX, (long)MAX(66, heightDots - 88), safeQR];
    }
    [tspl appendFormat:@"PRINT %ld,1\r\n", (long)MAX(1, s.copies)];
    return tspl;
}

+ (NSData *)dataForGapCalibrationWithSettings:(SMLabelPrintSettings *)settings {
    SMLabelPrintSettings *s = settings ?: [SMLabelPrintSettings default50x20Settings];
    NSMutableString *tspl = [NSMutableString string];
    [tspl appendFormat:@"SIZE %@ mm,%@ mm\r\n", [self numberString:s.widthMM], [self numberString:s.heightMM]];
    [tspl appendFormat:@"GAP %@ mm,0\r\n", [self numberString:s.gapMM]];
    // SUNMI TSPL documentation names this command GAPDECTECT.
    // Omitting x,y asks the printer to auto-calibrate label length and gap.
    [tspl appendString:@"GAPDECTECT\r\n"];
    [tspl appendString:@"HOME\r\n"];
    return [tspl dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)escapedTSPLString:(NSString *)string maxLength:(NSUInteger)maxLength {
    NSString *safe = string ?: @"";
    safe = [safe stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    safe = [safe stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
    safe = [safe stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    safe = [safe stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    if (maxLength > 0 && safe.length > maxLength) {
        safe = [safe substringToIndex:maxLength];
    }
    return safe;
}

+ (NSString *)numberString:(double)value {
    if (fabs(value - round(value)) < 0.001) {
        return [NSString stringWithFormat:@"%.0f", value];
    }
    return [NSString stringWithFormat:@"%.1f", value];
}

@end
