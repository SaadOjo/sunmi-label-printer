//
//  SMReceiptPrintSettings.m
//  MacOSApp
//

#import "SMReceiptPrintSettings.h"

@implementation SMReceiptPrintSettings

+ (instancetype)default80mmSettings {
    SMReceiptPrintSettings *settings = [[SMReceiptPrintSettings alloc] init];
    settings.paperWidthDots = 576;
    settings.characterColumns = 48;
    settings.density = 110;
    settings.speed = 120;
    settings.includeLogo = YES;
    settings.cutPaper = YES;
    settings.openCashDrawer = NO;
    return settings;
}

+ (instancetype)default58mmSettings {
    SMReceiptPrintSettings *settings = [[SMReceiptPrintSettings alloc] init];
    settings.paperWidthDots = 384;
    settings.characterColumns = 32;
    settings.density = 110;
    settings.speed = 100;
    settings.includeLogo = YES;
    settings.cutPaper = YES;
    settings.openCashDrawer = NO;
    return settings;
}

@end
