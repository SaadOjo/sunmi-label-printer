//
//  SMLabelPrintSettings.h
//  MacOSApp
//
//  Label/printer setup model. Keep this small and UI-independent so a future
//  label designer can reuse it.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMLabelPrintSettings : NSObject

@property (nonatomic, assign) double widthMM;
@property (nonatomic, assign) double heightMM;
@property (nonatomic, assign) double gapMM;
@property (nonatomic, assign) NSInteger speed;
@property (nonatomic, assign) NSInteger density;
@property (nonatomic, assign) NSInteger direction;
@property (nonatomic, assign) NSInteger copies;
@property (nonatomic, assign) BOOL alignToGapBeforePrint;

+ (instancetype)default50x20Settings;

@end

NS_ASSUME_NONNULL_END
