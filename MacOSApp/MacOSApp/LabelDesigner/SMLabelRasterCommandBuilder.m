//
//  SMLabelRasterCommandBuilder.m
//  MacOSApp
//

#import "SMLabelRasterCommandBuilder.h"
#import <AppKit/AppKit.h>

static const CGFloat SMRasterDotsPerMM = 8.0;

@implementation SMLabelRasterCommandBuilder

+ (NSData *)dataForDesignedLabelWithSettings:(SMLabelPrintSettings *)settings
                                    elements:(NSArray<SMDesignerElement *> *)elements {
    SMLabelPrintSettings *s = settings ?: [SMLabelPrintSettings default50x20Settings];
    NSInteger widthDots = MAX(80, (NSInteger)round(s.widthMM * SMRasterDotsPerMM));
    NSInteger heightDots = MAX(40, (NSInteger)round(s.heightMM * SMRasterDotsPerMM));
    NSInteger rowBytes = (widthDots + 7) / 8;

    NSBitmapImageRep *rep = [self renderBitmapWithWidth:widthDots height:heightDots elements:elements];
    NSMutableData *bitmap = [NSMutableData dataWithLength:rowBytes * heightDots];
    UInt8 *out = bitmap.mutableBytes;

    for (NSInteger y = 0; y < heightDots; y++) {
        for (NSInteger x = 0; x < widthDots; x++) {
            NSColor *color = [rep colorAtX:x y:y];
            CGFloat r = 1, g = 1, b = 1, a = 1;
            [[color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
            CGFloat luminance = (0.299 * r + 0.587 * g + 0.114 * b);
            if (a > 0.05 && luminance < 0.62) {
                out[y * rowBytes + (x / 8)] |= (0x80 >> (x % 8));
            }
        }
    }

    NSMutableData *data = [NSMutableData data];
    [self appendString:[NSString stringWithFormat:@"SIZE %@ mm,%@ mm\r\n", [self numberString:s.widthMM], [self numberString:s.heightMM]] toData:data];
    [self appendString:[NSString stringWithFormat:@"GAP %@ mm,0\r\n", [self numberString:s.gapMM]] toData:data];
    [self appendString:[NSString stringWithFormat:@"SPEED %ld\r\n", (long)s.speed] toData:data];
    [self appendString:[NSString stringWithFormat:@"DENSITY %ld\r\n", (long)s.density] toData:data];
    [self appendString:[NSString stringWithFormat:@"DIRECTION %ld\r\n", (long)s.direction] toData:data];
    [self appendString:@"REFERENCE 0,0\r\n" toData:data];
    [self appendString:@"OFFSET 0 mm\r\n" toData:data];
    [self appendString:@"CLS\r\n" toData:data];
    [self appendString:[NSString stringWithFormat:@"BITMAP 0,0,%ld,%ld,0,", (long)rowBytes, (long)heightDots] toData:data];
    [data appendData:bitmap];
    [self appendString:@"\r\n" toData:data];
    [self appendString:[NSString stringWithFormat:@"PRINT %ld,1\r\n", (long)MAX(1, s.copies)] toData:data];
    return data;
}

+ (NSString *)summaryForDesignedLabelWithSettings:(SMLabelPrintSettings *)settings
                                         elements:(NSArray<SMDesignerElement *> *)elements {
    SMLabelPrintSettings *s = settings ?: [SMLabelPrintSettings default50x20Settings];
    NSInteger widthDots = MAX(80, (NSInteger)round(s.widthMM * SMRasterDotsPerMM));
    NSInteger heightDots = MAX(40, (NSInteger)round(s.heightMM * SMRasterDotsPerMM));
    NSInteger rowBytes = (widthDots + 7) / 8;
    return [NSString stringWithFormat:@"WYSIWYG raster TSPL\nSIZE %@ mm,%@ mm\nGAP %@ mm,0\nCanvas: %ld × %ld dots\nBitmap: %ld bytes/row × %ld rows = %ld bytes\nElements: %lu\n\nPrint uses TSPL BITMAP so arbitrary fonts and images match the preview.",
            [self numberString:s.widthMM],
            [self numberString:s.heightMM],
            [self numberString:s.gapMM],
            (long)widthDots,
            (long)heightDots,
            (long)rowBytes,
            (long)heightDots,
            (long)(rowBytes * heightDots),
            (unsigned long)elements.count];
}

+ (NSBitmapImageRep *)renderBitmapWithWidth:(NSInteger)width height:(NSInteger)height elements:(NSArray<SMDesignerElement *> *)elements {
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
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    context.imageInterpolation = NSImageInterpolationHigh;

    [[NSColor whiteColor] setFill];
    NSRectFill(NSMakeRect(0, 0, width, height));

    for (SMDesignerElement *element in elements) {
        NSRect rect = [self bottomLeftRectForTopLeftRect:element.frameDots canvasHeight:height];
        if (element.type == SMDesignerElementTypeImage) {
            if (element.image) {
                [element.image drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
            }
            continue;
        }

        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.alignment = element.alignment;
        style.lineBreakMode = NSLineBreakByTruncatingTail;
        NSFont *baseFont = [NSFont fontWithName:element.fontName size:MAX(4, element.fontSizeDots)] ?: [NSFont systemFontOfSize:MAX(4, element.fontSizeDots)];
        NSFont *font = element.bold ? [[NSFontManager sharedFontManager] convertFont:baseFont toHaveTrait:NSBoldFontMask] : baseFont;
        NSDictionary *attrs = @{NSFontAttributeName: font ?: baseFont,
                                NSForegroundColorAttributeName: [NSColor blackColor],
                                NSParagraphStyleAttributeName: style};
        [element.text drawInRect:rect withAttributes:attrs];
    }

    [NSGraphicsContext restoreGraphicsState];
    return rep;
}

+ (NSRect)bottomLeftRectForTopLeftRect:(CGRect)rect canvasHeight:(NSInteger)height {
    return NSMakeRect(rect.origin.x,
                      height - rect.origin.y - rect.size.height,
                      rect.size.width,
                      rect.size.height);
}

+ (void)appendString:(NSString *)string toData:(NSMutableData *)data {
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (stringData) {
        [data appendData:stringData];
    }
}

+ (NSString *)numberString:(double)value {
    if (fabs(value - round(value)) < 0.001) {
        return [NSString stringWithFormat:@"%.0f", value];
    }
    return [NSString stringWithFormat:@"%.1f", value];
}

@end
