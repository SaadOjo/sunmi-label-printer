//
//  SMDesignerElement.m
//  MacOSApp
//

#import "SMDesignerElement.h"

@implementation SMDesignerElement

+ (instancetype)textElementWithText:(NSString *)text frame:(CGRect)frame {
    SMDesignerElement *element = [[SMDesignerElement alloc] init];
    element.identifier = [NSUUID UUID].UUIDString;
    element.type = SMDesignerElementTypeText;
    element.frameDots = frame;
    element.text = text.length ? text : @"Text";
    element.fontName = @"Helvetica Neue";
    element.fontSizeDots = 24;
    element.bold = NO;
    element.alignment = NSTextAlignmentLeft;
    return element;
}

+ (instancetype)imageElementWithImage:(NSImage *)image path:(NSString *)path frame:(CGRect)frame {
    SMDesignerElement *element = [[SMDesignerElement alloc] init];
    element.identifier = [NSUUID UUID].UUIDString;
    element.type = SMDesignerElementTypeImage;
    element.frameDots = frame;
    element.image = image;
    element.imagePath = path;
    element.text = @"";
    element.fontName = @"Helvetica Neue";
    element.fontSizeDots = 24;
    element.alignment = NSTextAlignmentCenter;
    return element;
}

- (id)copyWithZone:(NSZone *)zone {
    SMDesignerElement *copy = [[[self class] allocWithZone:zone] init];
    copy.identifier = [NSUUID UUID].UUIDString;
    copy.type = self.type;
    copy.frameDots = self.frameDots;
    copy.text = self.text;
    copy.fontName = self.fontName;
    copy.fontSizeDots = self.fontSizeDots;
    copy.bold = self.bold;
    copy.alignment = self.alignment;
    copy.image = self.image;
    copy.imagePath = self.imagePath;
    return copy;
}

@end
