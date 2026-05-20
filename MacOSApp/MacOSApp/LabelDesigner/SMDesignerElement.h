//
//  SMDesignerElement.h
//  MacOSApp
//
//  Lightweight WYSIWYG label-designer element model. Coordinates are printer
//  dots at 203 DPI (1 mm ~= 8 dots), top-left origin.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SMDesignerElementType) {
    SMDesignerElementTypeText = 0,
    SMDesignerElementTypeImage
};

@interface SMDesignerElement : NSObject <NSCopying>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) SMDesignerElementType type;
@property (nonatomic, assign) CGRect frameDots;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *fontName;
@property (nonatomic, assign) CGFloat fontSizeDots;
@property (nonatomic, assign) BOOL bold;
@property (nonatomic, assign) NSTextAlignment alignment;

@property (nonatomic, strong, nullable) NSImage *image;
@property (nonatomic, copy, nullable) NSString *imagePath;

+ (instancetype)textElementWithText:(NSString *)text frame:(CGRect)frame;
+ (instancetype)imageElementWithImage:(NSImage *)image path:(nullable NSString *)path frame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
