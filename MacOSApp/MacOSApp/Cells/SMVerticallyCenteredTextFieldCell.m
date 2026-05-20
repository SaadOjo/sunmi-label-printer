//
//  SMVerticallyCenteredTextFieldCell.m
//  MacOSApp
//
//  Created by SM2368 on 2023/11/20.
//

#import "SMVerticallyCenteredTextFieldCell.h"

@interface SMVerticallyCenteredTextFieldCell ()

@property (nonatomic) BOOL mIsEditingOrSelecting;

@end

@implementation SMVerticallyCenteredTextFieldCell


- (NSRect)drawingRectForBounds:(NSRect)rect {
    NSRect newRect = [super drawingRectForBounds:rect];
    if (!self.mIsEditingOrSelecting) {
        NSSize textSize = [self cellSizeForBounds:rect];
        CGFloat heightDelta = newRect.size.height - textSize.height;
        if (heightDelta > 0) {
            newRect.size.height -= heightDelta;
            newRect.origin.y += heightDelta / 2;
        }
    }
    
    return newRect;
}

- (void)selectWithFrame:(NSRect)rect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)delegate start:(NSInteger)selStart length:(NSInteger)selLength {
    NSRect arect = [self drawingRectForBounds:rect];
    self.mIsEditingOrSelecting = YES;
    [super selectWithFrame:arect inView:controlView editor:textObj delegate:delegate start:selStart length:selLength];
    self.mIsEditingOrSelecting = NO;
}

- (void)editWithFrame:(NSRect)rect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)delegate event:(NSEvent *)event {
    NSRect aRect = [self drawingRectForBounds:rect];
    self.mIsEditingOrSelecting = YES;
    [super editWithFrame:aRect inView:controlView editor:textObj delegate:delegate event:event];
    self.mIsEditingOrSelecting = NO;
}



@end
