//
//  SMReceiptCommandBuilder.m
//  MacOSApp
//

#import "SMReceiptCommandBuilder.h"
#import <AppKit/AppKit.h>
#import <SunmiPrinterMacOS/SunmiPrinterMacOS.h>

@implementation SMReceiptCommandBuilder

+ (NSData *)dataForReceiptWithSettings:(SMReceiptPrintSettings *)settings
                               content:(SMReceiptContent *)content {
    SMReceiptPrintSettings *s = settings ?: [SMReceiptPrintSettings default80mmSettings];
    SMReceiptContent *c = content ?: [SMReceiptContent sampleReceipt];

    SunmiPrinterCommand *command = [[SunmiPrinterCommand alloc] init];
    [command restoreDefaultSettings];
    [command setPrintWidth:(int)s.paperWidthDots];
    [command setUtf8Mode:1];
    [command setPrintDensity:(int)s.density];
    [command setPrintSpeed:(int)s.speed];

    if (s.includeLogo) {
        [command setAlignment:SMAlignStyle_Center];
        // Build a 1x bitmap with an explicit pixel width. Using lockFocus on a
        // Retina Mac can silently create a 2x backing bitmap, which can make the
        // printer receive an image wider than the paper even when NSImage.size
        // looks safe. The helper below caps the real bitmap width.
        [command appendImage:[self logoImageWithTitle:c.storeName maxWidth:[self boundedLogoWidthForSettings:s]]
                        mode:SMImageAlgorithm_DITHERING];
        [command lineFeed:1];
    }

    [command setAlignment:SMAlignStyle_Center];
    [command setPrintModesBold:YES double_h:YES double_w:YES];
    [command appendText:[NSString stringWithFormat:@"%@\n", [self safeText:c.storeName fallback:@"Store"]]];
    [command setPrintModesBold:NO double_h:NO double_w:NO];

    if (c.storeAddress.length) {
        NSArray<NSString *> *lines = [c.storeAddress componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        for (NSString *line in lines) {
            if (line.length) {
                [command appendText:[NSString stringWithFormat:@"%@\n", line]];
            }
        }
    }
    if (c.storePhone.length) {
        [command appendText:[NSString stringWithFormat:@"%@\n", c.storePhone]];
    }

    [command setAlignment:SMAlignStyle_Left];
    [command appendText:[[self separatorForColumns:s.characterColumns] stringByAppendingString:@"\n"]];
    [command appendText:[NSString stringWithFormat:@"Order: %@\n", [self safeText:c.orderNumber fallback:@"-"]]];
    [command appendText:[NSString stringWithFormat:@"Cashier: %@\n", [self safeText:c.cashierName fallback:@"-"]]];
    [command appendText:[NSString stringWithFormat:@"Date: %@\n", [self receiptDateString]]];
    [command appendText:[[self separatorForColumns:s.characterColumns] stringByAppendingString:@"\n"]];

    for (SMReceiptLineItem *item in c.items) {
        [command appendText:[self formattedItemLine:item columns:s.characterColumns]];
    }

    [command appendText:[[self separatorForColumns:s.characterColumns] stringByAppendingString:@"\n"]];
    [command appendText:[self formattedAmountLineWithTitle:@"Subtotal" amount:c.subtotal columns:s.characterColumns]];
    [command appendText:[self formattedAmountLineWithTitle:@"Tax" amount:c.tax columns:s.characterColumns]];
    [command setPrintModesBold:YES double_h:NO double_w:NO];
    [command appendText:[self formattedAmountLineWithTitle:@"TOTAL" amount:c.total columns:s.characterColumns]];
    [command setPrintModesBold:NO double_h:NO double_w:NO];

    if (c.barcodeValue.length) {
        [command lineFeed:1];
        [command setAlignment:SMAlignStyle_Center];
        [command appendBarcode:SMBarcodeReadable_Below
                         height:60
                    module_size:2
                   barcode_type:SMBarcodeType_CODE128
                           text:c.barcodeValue];
        [command lineFeed:1];
    }

    if (c.qrValue.length) {
        [command setAlignment:SMAlignStyle_Center];
        [command appendQRcode:6 ec_level:SMErrorLevel_M text:c.qrValue];
        [command lineFeed:1];
    }

    if (c.footerText.length) {
        [command setAlignment:SMAlignStyle_Center];
        [command appendText:[NSString stringWithFormat:@"%@\n", c.footerText]];
    }

    [command lineFeed:3];
    if (s.openCashDrawer) {
        [command openCashBox];
    }
    if (s.cutPaper) {
        [command autoCutPaper:NO];
    }

    return [command getCommandData];
}

+ (NSString *)plainTextPreviewForReceiptWithSettings:(SMReceiptPrintSettings *)settings
                                             content:(SMReceiptContent *)content {
    SMReceiptPrintSettings *s = settings ?: [SMReceiptPrintSettings default80mmSettings];
    SMReceiptContent *c = content ?: [SMReceiptContent sampleReceipt];
    NSMutableString *preview = [NSMutableString string];
    NSInteger columns = MAX(32, s.characterColumns);

    [preview appendFormat:@"%@\n", [self centeredText:[self safeText:c.storeName fallback:@"Store"] columns:columns]];
    if (c.storeAddress.length) {
        NSArray<NSString *> *lines = [c.storeAddress componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        for (NSString *line in lines) {
            if (line.length) {
                [preview appendFormat:@"%@\n", [self centeredText:line columns:columns]];
            }
        }
    }
    if (c.storePhone.length) {
        [preview appendFormat:@"%@\n", [self centeredText:c.storePhone columns:columns]];
    }
    [preview appendFormat:@"%@\n", [self separatorForColumns:columns]];
    [preview appendFormat:@"Order: %@\n", [self safeText:c.orderNumber fallback:@"-"]];
    [preview appendFormat:@"Cashier: %@\n", [self safeText:c.cashierName fallback:@"-"]];
    [preview appendFormat:@"Date: %@\n", [self receiptDateString]];
    [preview appendFormat:@"%@\n", [self separatorForColumns:columns]];
    for (SMReceiptLineItem *item in c.items) {
        [preview appendString:[self formattedItemLine:item columns:columns]];
    }
    [preview appendFormat:@"%@\n", [self separatorForColumns:columns]];
    [preview appendString:[self formattedAmountLineWithTitle:@"Subtotal" amount:c.subtotal columns:columns]];
    [preview appendString:[self formattedAmountLineWithTitle:@"Tax" amount:c.tax columns:columns]];
    [preview appendString:[self formattedAmountLineWithTitle:@"TOTAL" amount:c.total columns:columns]];
    if (c.barcodeValue.length) {
        [preview appendFormat:@"\n[Barcode: %@]\n", c.barcodeValue];
    }
    if (c.qrValue.length) {
        [preview appendFormat:@"[QR: %@]\n", c.qrValue];
    }
    if (c.footerText.length) {
        [preview appendFormat:@"\n%@\n", [self centeredText:c.footerText columns:columns]];
    }
    return preview;
}

+ (NSImage *)previewImageForReceiptWithSettings:(SMReceiptPrintSettings *)settings
                                        content:(SMReceiptContent *)content {
    SMReceiptPrintSettings *s = settings ?: [SMReceiptPrintSettings default80mmSettings];
    SMReceiptContent *c = content ?: [SMReceiptContent sampleReceipt];
    NSInteger paperWidth = MAX(320, s.paperWidthDots);
    CGFloat margin = paperWidth >= 560 ? 28 : 22;
    NSInteger logoWidth = [self boundedLogoWidthForSettings:s];
    NSInteger logoHeight = [self boundedLogoHeightForWidth:logoWidth];
    NSArray<NSString *> *addressLines = c.storeAddress.length ? [c.storeAddress componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] : @[];

    CGFloat y = 20;
    if (s.includeLogo) {
        y += logoHeight + 16;
    }
    y += 36; // title
    for (NSString *line in addressLines) {
        if (line.length) { y += 20; }
    }
    if (c.storePhone.length) { y += 20; }
    y += 24; // separator
    y += 66; // order/cashier/date
    y += 24; // separator
    y += MAX(1, c.items.count) * 46;
    y += 24; // separator
    y += 74; // totals
    if (c.barcodeValue.length) { y += 104; }
    if (c.qrValue.length) { y += 120; }
    if (c.footerText.length) { y += 42; }
    y += s.cutPaper ? 58 : 38;
    NSInteger canvasHeight = (NSInteger)ceil(y);

    NSImage *image = [self blankBitmapImageWithWidth:paperWidth height:canvasHeight];
    [image lockFocus];
    [[NSColor whiteColor] setFill];
    NSRectFill(NSMakeRect(0, 0, paperWidth, canvasHeight));

    NSDictionary *titleAttrs = @{NSFontAttributeName: [NSFont boldSystemFontOfSize:24], NSForegroundColorAttributeName: [NSColor blackColor]};
    NSDictionary *bodyAttrs = @{NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:14] ?: [NSFont systemFontOfSize:14], NSForegroundColorAttributeName: [NSColor blackColor]};
    NSDictionary *boldAttrs = @{NSFontAttributeName: [NSFont fontWithName:@"Menlo-Bold" size:15] ?: [NSFont boldSystemFontOfSize:15], NSForegroundColorAttributeName: [NSColor blackColor]};
    NSDictionary *smallAttrs = @{NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:12] ?: [NSFont systemFontOfSize:12], NSForegroundColorAttributeName: [NSColor blackColor]};

    y = 20;
    if (s.includeLogo) {
        NSImage *logo = [self logoImageWithTitle:c.storeName maxWidth:logoWidth];
        CGFloat x = (paperWidth - logo.size.width) / 2.0;
        [logo drawInRect:[self rectWithTopY:y x:x width:logo.size.width height:logo.size.height canvasHeight:canvasHeight]
                fromRect:NSZeroRect
               operation:NSCompositingOperationSourceOver
                fraction:1.0];
        y += logo.size.height + 16;
    }

    [self drawText:[self safeText:c.storeName fallback:@"Store"] topY:y x:margin width:paperWidth - 2 * margin height:30 canvasHeight:canvasHeight attributes:titleAttrs alignment:NSTextAlignmentCenter];
    y += 36;
    for (NSString *line in addressLines) {
        if (line.length) {
            [self drawText:line topY:y x:margin width:paperWidth - 2 * margin height:18 canvasHeight:canvasHeight attributes:bodyAttrs alignment:NSTextAlignmentCenter];
            y += 20;
        }
    }
    if (c.storePhone.length) {
        [self drawText:c.storePhone topY:y x:margin width:paperWidth - 2 * margin height:18 canvasHeight:canvasHeight attributes:bodyAttrs alignment:NSTextAlignmentCenter];
        y += 20;
    }

    [self drawSeparatorAtTopY:y margin:margin paperWidth:paperWidth canvasHeight:canvasHeight];
    y += 24;
    [self drawText:[NSString stringWithFormat:@"Order: %@", [self safeText:c.orderNumber fallback:@"-"]] topY:y x:margin width:paperWidth - 2 * margin height:18 canvasHeight:canvasHeight attributes:bodyAttrs alignment:NSTextAlignmentLeft];
    y += 22;
    [self drawText:[NSString stringWithFormat:@"Cashier: %@", [self safeText:c.cashierName fallback:@"-"]] topY:y x:margin width:paperWidth - 2 * margin height:18 canvasHeight:canvasHeight attributes:bodyAttrs alignment:NSTextAlignmentLeft];
    y += 22;
    [self drawText:[NSString stringWithFormat:@"Date: %@", [self receiptDateString]] topY:y x:margin width:paperWidth - 2 * margin height:18 canvasHeight:canvasHeight attributes:bodyAttrs alignment:NSTextAlignmentLeft];
    y += 22;
    [self drawSeparatorAtTopY:y margin:margin paperWidth:paperWidth canvasHeight:canvasHeight];
    y += 24;

    for (SMReceiptLineItem *item in c.items) {
        NSString *amount = [self money:item.lineTotal];
        [self drawText:[self truncate:item.name length:32] topY:y x:margin width:paperWidth - 2 * margin - 95 height:18 canvasHeight:canvasHeight attributes:bodyAttrs alignment:NSTextAlignmentLeft];
        [self drawText:amount topY:y x:paperWidth - margin - 95 width:95 height:18 canvasHeight:canvasHeight attributes:bodyAttrs alignment:NSTextAlignmentRight];
        y += 22;
        NSString *detail = [NSString stringWithFormat:@"%ld × %@", (long)item.quantity, [self money:item.unitPrice]];
        [self drawText:detail topY:y x:margin + 16 width:paperWidth - 2 * margin - 16 height:16 canvasHeight:canvasHeight attributes:smallAttrs alignment:NSTextAlignmentLeft];
        y += 24;
    }

    [self drawSeparatorAtTopY:y margin:margin paperWidth:paperWidth canvasHeight:canvasHeight];
    y += 24;
    y = [self drawAmountTitle:@"Subtotal" amount:c.subtotal topY:y margin:margin paperWidth:paperWidth canvasHeight:canvasHeight attributes:bodyAttrs];
    y = [self drawAmountTitle:@"Tax" amount:c.tax topY:y margin:margin paperWidth:paperWidth canvasHeight:canvasHeight attributes:bodyAttrs];
    y = [self drawAmountTitle:@"TOTAL" amount:c.total topY:y margin:margin paperWidth:paperWidth canvasHeight:canvasHeight attributes:boldAttrs];

    if (c.barcodeValue.length) {
        y += 10;
        CGFloat barcodeWidth = MIN(paperWidth - 2 * margin, 320);
        CGFloat barcodeX = (paperWidth - barcodeWidth) / 2.0;
        NSRect barcodeRect = [self rectWithTopY:y x:barcodeX width:barcodeWidth height:58 canvasHeight:canvasHeight];
        [[NSColor whiteColor] setFill];
        NSRectFill(barcodeRect);
        [[NSColor blackColor] setFill];
        CGFloat x = barcodeX + 8;
        NSArray<NSNumber *> *bars = @[@2,@1,@3,@1,@1,@2,@4,@1,@2,@3,@1,@1,@3,@2,@1,@4,@2,@1,@2,@3,@1,@2,@4,@1,@1,@3,@2,@1,@3,@1,@2,@4,@1,@1,@2,@3];
        for (NSNumber *bar in bars) {
            CGFloat w = bar.doubleValue * 1.7;
            if (x + w > barcodeX + barcodeWidth - 8) { break; }
            NSRectFill([self rectWithTopY:y + 4 x:x width:w height:46 canvasHeight:canvasHeight]);
            x += w + 2.2;
        }
        [self drawText:c.barcodeValue topY:y + 62 x:margin width:paperWidth - 2 * margin height:16 canvasHeight:canvasHeight attributes:smallAttrs alignment:NSTextAlignmentCenter];
        y += 92;
    }

    if (c.qrValue.length) {
        CGFloat qrSize = 88;
        CGFloat qrX = (paperWidth - qrSize) / 2.0;
        NSRect qrRect = [self rectWithTopY:y x:qrX width:qrSize height:qrSize canvasHeight:canvasHeight];
        [[NSColor whiteColor] setFill];
        NSRectFill(qrRect);
        [[NSColor blackColor] setStroke];
        NSFrameRectWithWidth(qrRect, 2);
        [[NSColor blackColor] setFill];
        for (NSInteger row = 0; row < 7; row++) {
            for (NSInteger col = 0; col < 7; col++) {
                if ((row * 3 + col * 5 + c.qrValue.length) % 4 == 0) {
                    NSRectFill([self rectWithTopY:y + 8 + row * 10 x:qrX + 8 + col * 10 width:7 height:7 canvasHeight:canvasHeight]);
                }
            }
        }
        y += qrSize + 12;
    }

    if (c.footerText.length) {
        [self drawText:c.footerText topY:y x:margin width:paperWidth - 2 * margin height:18 canvasHeight:canvasHeight attributes:bodyAttrs alignment:NSTextAlignmentCenter];
        y += 42;
    }
    if (s.cutPaper) {
        [self drawText:@"⋯ cut ⋯" topY:y x:margin width:paperWidth - 2 * margin height:18 canvasHeight:canvasHeight attributes:smallAttrs alignment:NSTextAlignmentCenter];
    }

    [image unlockFocus];
    return image;
}

#pragma mark - Formatting

+ (NSString *)formattedItemLine:(SMReceiptLineItem *)item columns:(NSInteger)columns {
    NSString *name = [self safeText:item.name fallback:@"Item"];
    NSInteger amountWidth = 10;
    NSInteger leftWidth = MAX(12, columns - amountWidth);
    NSString *amount = [self money:item.lineTotal];
    NSString *line1 = [self left:name width:leftWidth];
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@%@\n", line1, [self right:amount width:amountWidth]];
    NSString *detail = [NSString stringWithFormat:@"  %ld x %@", (long)item.quantity, [self money:item.unitPrice]];
    [result appendFormat:@"%@\n", [self truncate:detail length:columns]];
    return result;
}

+ (NSString *)formattedAmountLineWithTitle:(NSString *)title amount:(double)amount columns:(NSInteger)columns {
    NSString *money = [self money:amount];
    NSInteger amountWidth = 12;
    NSInteger titleWidth = MAX(12, columns - amountWidth);
    return [NSString stringWithFormat:@"%@%@\n", [self left:title width:titleWidth], [self right:money width:amountWidth]];
}

+ (NSString *)separatorForColumns:(NSInteger)columns {
    NSUInteger count = MAX(24, (NSUInteger)columns);
    NSMutableString *separator = [NSMutableString stringWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        [separator appendString:@"-"];
    }
    return separator;
}

+ (NSString *)centeredText:(NSString *)text columns:(NSInteger)columns {
    NSString *safe = [self truncate:text length:columns];
    NSInteger padding = MAX(0, (columns - (NSInteger)safe.length) / 2);
    NSMutableString *result = [NSMutableString string];
    for (NSInteger i = 0; i < padding; i++) {
        [result appendString:@" "];
    }
    [result appendString:safe];
    return result;
}

+ (NSString *)left:(NSString *)text width:(NSInteger)width {
    NSString *safe = [self truncate:text length:width];
    NSMutableString *result = [safe mutableCopy];
    while (result.length < width) {
        [result appendString:@" "];
    }
    return result;
}

+ (NSString *)right:(NSString *)text width:(NSInteger)width {
    NSString *safe = [self truncate:text length:width];
    NSMutableString *result = [NSMutableString string];
    while (result.length + safe.length < width) {
        [result appendString:@" "];
    }
    [result appendString:safe];
    return result;
}

+ (NSString *)truncate:(NSString *)text length:(NSInteger)length {
    NSString *safe = text ?: @"";
    safe = [safe stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
    safe = [safe stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    if (length > 0 && safe.length > length) {
        return [safe substringToIndex:length];
    }
    return safe;
}

+ (NSString *)safeText:(NSString *)text fallback:(NSString *)fallback {
    return text.length ? text : fallback;
}

+ (NSString *)money:(double)value {
    return [NSString stringWithFormat:@"$%.2f", value];
}

+ (NSString *)receiptDateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    return [formatter stringFromDate:[NSDate date]];
}

#pragma mark - Logo

+ (NSInteger)boundedLogoWidthForSettings:(SMReceiptPrintSettings *)settings {
    NSInteger paperWidth = MAX(320, settings.paperWidthDots);
    // Conservative cap: even if the printer/SDK treats the image as raw dots,
    // it remains comfortably inside 58mm paper. Larger receipts still get a
    // readable logo but never a full-width bitmap.
    NSInteger transportSafeCap = paperWidth >= 560 ? 260 : 190;
    NSInteger paperSafeCap = paperWidth - 96;
    return MAX(120, MIN(transportSafeCap, paperSafeCap));
}

+ (NSInteger)boundedLogoHeightForWidth:(NSInteger)width {
    return MAX(44, MIN(76, (NSInteger)round(width * 0.27)));
}

+ (NSImage *)logoImageWithTitle:(NSString *)title maxWidth:(NSInteger)maxWidth {
    NSInteger width = MAX(120, maxWidth);
    NSInteger height = [self boundedLogoHeightForWidth:width];
    NSImage *image = [self blankBitmapImageWithWidth:width height:height];
    [image lockFocus];

    [[NSColor whiteColor] setFill];
    NSRectFill(NSMakeRect(0, 0, width, height));

    NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(3, 6, width - 6, height - 12) xRadius:8 yRadius:8];
    [[NSColor blackColor] setStroke];
    border.lineWidth = 2;
    [border stroke];

    NSString *logoText = [self truncate:[self safeText:title fallback:@"OJO"] length:18];
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:MIN(20, MAX(15, width / 12))],
        NSForegroundColorAttributeName: [NSColor blackColor]
    };
    NSSize textSize = [logoText sizeWithAttributes:attrs];
    NSRect textRect = NSMakeRect((width - textSize.width) / 2.0,
                                 (height - textSize.height) / 2.0,
                                 textSize.width,
                                 textSize.height);
    [logoText drawInRect:textRect withAttributes:attrs];

    [image unlockFocus];
    return image;
}

+ (NSImage *)blankBitmapImageWithWidth:(NSInteger)width height:(NSInteger)height {
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                    pixelsWide:width
                                                                    pixelsHigh:height
                                                                 bitsPerSample:8
                                                               samplesPerPixel:4
                                                                      hasAlpha:YES
                                                                      isPlanar:NO
                                                                colorSpaceName:NSCalibratedRGBColorSpace
                                                                   bytesPerRow:0
                                                                  bitsPerPixel:0];
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:rep];
    return image;
}

+ (NSRect)rectWithTopY:(CGFloat)topY x:(CGFloat)x width:(CGFloat)width height:(CGFloat)height canvasHeight:(CGFloat)canvasHeight {
    return NSMakeRect(x, canvasHeight - topY - height, width, height);
}

+ (void)drawText:(NSString *)text
           topY:(CGFloat)topY
              x:(CGFloat)x
          width:(CGFloat)width
         height:(CGFloat)height
   canvasHeight:(CGFloat)canvasHeight
      attributes:(NSDictionary *)attributes
       alignment:(NSTextAlignment)alignment {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = alignment;
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    NSMutableDictionary *attrs = [attributes mutableCopy];
    attrs[NSParagraphStyleAttributeName] = style;
    [text drawInRect:[self rectWithTopY:topY x:x width:width height:height canvasHeight:canvasHeight]
      withAttributes:attrs];
}

+ (void)drawSeparatorAtTopY:(CGFloat)topY margin:(CGFloat)margin paperWidth:(CGFloat)paperWidth canvasHeight:(CGFloat)canvasHeight {
    [[NSColor blackColor] setFill];
    NSRectFill([self rectWithTopY:topY + 8 x:margin width:paperWidth - 2 * margin height:1 canvasHeight:canvasHeight]);
}

+ (CGFloat)drawAmountTitle:(NSString *)title
                    amount:(double)amount
                      topY:(CGFloat)topY
                    margin:(CGFloat)margin
                paperWidth:(CGFloat)paperWidth
              canvasHeight:(CGFloat)canvasHeight
                attributes:(NSDictionary *)attributes {
    [self drawText:title topY:topY x:margin width:paperWidth - 2 * margin - 120 height:18 canvasHeight:canvasHeight attributes:attributes alignment:NSTextAlignmentLeft];
    [self drawText:[self money:amount] topY:topY x:paperWidth - margin - 120 width:120 height:18 canvasHeight:canvasHeight attributes:attributes alignment:NSTextAlignmentRight];
    return topY + 24;
}

@end
