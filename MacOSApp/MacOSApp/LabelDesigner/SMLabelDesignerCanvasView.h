//
//  SMLabelDesignerCanvasView.h
//  MacOSApp
//
//  Minimal free-form label designer canvas: select, drag, draw text/images.
//

#import <AppKit/AppKit.h>
#import "SMDesignerElement.h"

NS_ASSUME_NONNULL_BEGIN

@class SMLabelDesignerCanvasView;

@protocol SMLabelDesignerCanvasViewDelegate <NSObject>
@optional
- (void)designerCanvasSelectionDidChange:(SMLabelDesignerCanvasView *)canvas;
- (void)designerCanvasDidChange:(SMLabelDesignerCanvasView *)canvas;
@end

@interface SMLabelDesignerCanvasView : NSView

@property (nonatomic, weak, nullable) id<SMLabelDesignerCanvasViewDelegate> delegate;
@property (nonatomic, assign) CGFloat labelWidthMM;
@property (nonatomic, assign) CGFloat labelHeightMM;
@property (nonatomic, assign) CGFloat zoom;
@property (nonatomic, strong) NSMutableArray<SMDesignerElement *> *elements;
@property (nonatomic, strong, nullable) SMDesignerElement *selectedElement;
@property (nonatomic, assign) BOOL showGrid;

@property (nonatomic, readonly) NSInteger labelWidthDots;
@property (nonatomic, readonly) NSInteger labelHeightDots;

- (void)setLabelWidthMM:(CGFloat)widthMM heightMM:(CGFloat)heightMM;
- (void)addTextElement;
- (void)addImageElementWithImage:(NSImage *)image path:(nullable NSString *)path;
- (void)deleteSelectedElement;
- (void)duplicateSelectedElement;
- (void)fitToContent;
- (void)notifyElementChanged;
- (void)selectElement:(nullable SMDesignerElement *)element;

@end

NS_ASSUME_NONNULL_END
