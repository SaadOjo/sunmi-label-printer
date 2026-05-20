//
//  SMLabelPrintSettings.m
//  MacOSApp
//

#import "SMLabelPrintSettings.h"

@implementation SMLabelPrintSettings

+ (instancetype)default50x20Settings {
    SMLabelPrintSettings *settings = [[SMLabelPrintSettings alloc] init];
    settings.widthMM = 50.0;
    settings.heightMM = 20.0;
    settings.gapMM = 3.0;
    settings.speed = 3;
    settings.density = 12;
    settings.direction = 1;
    settings.copies = 1;
    // Do not HOME before every print: HOME advances to the next label, so
    // HOME + PRINT looks like two labels feeding. Use calibration separately.
    settings.alignToGapBeforePrint = NO;
    return settings;
}

@end
