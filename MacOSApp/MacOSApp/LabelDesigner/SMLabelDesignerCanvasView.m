//
//  SMLabelDesignerCanvasView.m
//  MacOSApp
//

#import "SMLabelDesignerCanvasView.h"

static const CGFloat SMDesignerDotsPerMM = 8.0;
static const CGFloat SMDesignerCanvasPadding = 36.0;

@interface SMLabelDesignerCanvasView ()
@property (nonatomic, assign) BOOL dragging;
@property (nonatomic, assign) CGPoint dragOffsetDots;
@end

@implementation SMLabelDesignerCanvasView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _labelWidthMM = 50;
        _labelHeightMM = 20;
        _zoom = 1.65;
        _showGrid = YES;
        _elements = [NSMutableArray array];
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.88 alpha:1].CGColor;
        [self fitToContent];
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (NSInteger)labelWidthDots {
    return MAX(80, (NSInteger)round(self.labelWidthMM * SMDesignerDotsPerMM));
}

- (NSInteger)labelHeightDots {
    return MAX(40, (NSInteger)round(self.labelHeightMM * SMDesignerDotsPerMM));
}

- (void)setLabelWidthMM:(CGFloat)widthMM heightMM:(CGFloat)heightMM {
    _labelWidthMM = MAX(10, widthMM);
    _labelHeightMM = MAX(8, heightMM);
    [self constrainElementsToLabel];
    [self fitToContent];
    [self setNeedsDisplay:YES];
    if ([self.delegate respondsToSelector:@selector(designerCanvasDidChange:)]) {
        [self.delegate designerCanvasDidChange:self];
    }
}

- (void)fitToContent {
    CGFloat width = self.labelWidthDots * self.zoom + SMDesignerCanvasPadding * 2;
    CGFloat height = self.labelHeightDots * self.zoom + SMDesignerCanvasPadding * 2;
    [self setFrameSize:NSMakeSize(MAX(width, 520), MAX(height, 360))];
}

- (void)addTextElement {
    CGRect frame = CGRectMake(24, 24, MIN(210, self.labelWidthDots - 48), 34);
    SMDesignerElement *element = [SMDesignerElement textElementWithText:@"Double-click text" frame:frame];
    [self.elements addObject:element];
    [self selectElement:element];
    [self notifyElementChanged];
}

- (void)addImageElementWithImage:(NSImage *)image path:(NSString *)path {
    if (!image) {
        return;
    }
    CGFloat maxW = MIN(120, self.labelWidthDots - 40);
    CGFloat maxH = MIN(80, self.labelHeightDots - 40);
    CGFloat aspect = image.size.height > 0 ? image.size.width / image.size.height : 1;
    CGFloat width = maxW;
    CGFloat height = width / MAX(0.1, aspect);
    if (height > maxH) {
        height = maxH;
        width = height * aspect;
    }
    CGRect frame = CGRectMake(MAX(12, (self.labelWidthDots - width) / 2.0),
                              MAX(12, (self.labelHeightDots - height) / 2.0),
                              MAX(20, width),
                              MAX(20, height));
    SMDesignerElement *element = [SMDesignerElement imageElementWithImage:image path:path frame:frame];
    [self.elements addObject:element];
    [self selectElement:element];
    [self notifyElementChanged];
}

- (void)deleteSelectedElement {
    if (!self.selectedElement) {
        return;
    }
    [self.elements removeObject:self.selectedElement];
    [self selectElement:nil];
    [self notifyElementChanged];
}

- (void)duplicateSelectedElement {
    if (!self.selectedElement) {
        return;
    }
    SMDesignerElement *copy = [self.selectedElement copy];
    CGRect frame = copy.frameDots;
    frame.origin.x = MIN(self.labelWidthDots - frame.size.width, frame.origin.x + 16);
    frame.origin.y = MIN(self.labelHeightDots - frame.size.height, frame.origin.y + 16);
    copy.frameDots = frame;
    [self.elements addObject:copy];
    [self selectElement:copy];
    [self notifyElementChanged];
}

- (void)selectElement:(SMDesignerElement *)element {
    _selectedElement = element;
    [self setNeedsDisplay:YES];
    if ([self.delegate respondsToSelector:@selector(designerCanvasSelectionDidChange:)]) {
        [self.delegate designerCanvasSelectionDidChange:self];
    }
}

- (void)notifyElementChanged {
    [self constrainElementsToLabel];
    [self setNeedsDisplay:YES];
    if ([self.delegate respondsToSelector:@selector(designerCanvasDidChange:)]) {
        [self.delegate designerCanvasDidChange:self];
    }
}

- (void)constrainElementsToLabel {
    for (SMDesignerElement *element in self.elements) {
        CGRect frame = element.frameDots;
        frame.size.width = MAX(8, MIN(frame.size.width, self.labelWidthDots));
        frame.size.height = MAX(8, MIN(frame.size.height, self.labelHeightDots));
        frame.origin.x = MAX(0, MIN(frame.origin.x, self.labelWidthDots - frame.size.width));
        frame.origin.y = MAX(0, MIN(frame.origin.y, self.labelHeightDots - frame.size.height));
        element.frameDots = frame;
    }
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [[NSColor colorWithCalibratedWhite:0.88 alpha:1] setFill];
    NSRectFill(self.bounds);

    NSRect labelRect = [self labelRectInView];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor colorWithCalibratedWhite:0 alpha:0.22];
    shadow.shadowBlurRadius = 10;
    shadow.shadowOffset = NSMakeSize(0, -2);
    [NSGraphicsContext saveGraphicsState];
    [shadow set];
    [[NSColor whiteColor] setFill];
    NSRectFill(labelRect);
    [NSGraphicsContext restoreGraphicsState];

    [[NSColor colorWithCalibratedWhite:0.78 alpha:1] setStroke];
    NSFrameRectWithWidth(labelRect, 1);

    if (self.showGrid) {
        [self drawGridInLabelRect:labelRect];
    }

    for (SMDesignerElement *element in self.elements) {
        [self drawElement:element selected:(element == self.selectedElement)];
    }

    NSString *sizeText = [NSString stringWithFormat:@"%.0f × %.0f mm (%ld × %ld dots)", self.labelWidthMM, self.labelHeightMM, (long)self.labelWidthDots, (long)self.labelHeightDots];
    NSDictionary *attrs = @{NSFontAttributeName: [NSFont systemFontOfSize:11], NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.35 alpha:1]};
    [sizeText drawAtPoint:NSMakePoint(labelRect.origin.x, labelRect.origin.y + labelRect.size.height + 10) withAttributes:attrs];
}

- (NSRect)labelRectInView {
    return NSMakeRect(SMDesignerCanvasPadding,
                      SMDesignerCanvasPadding,
                      self.labelWidthDots * self.zoom,
                      self.labelHeightDots * self.zoom);
}

- (void)drawGridInLabelRect:(NSRect)labelRect {
    [[NSColor colorWithCalibratedWhite:0.91 alpha:1] setStroke];
    NSBezierPath *path = [NSBezierPath bezierPath];
    CGFloat step = 5.0 * SMDesignerDotsPerMM * self.zoom;
    for (CGFloat x = labelRect.origin.x + step; x < NSMaxX(labelRect); x += step) {
        [path moveToPoint:NSMakePoint(x, labelRect.origin.y)];
        [path lineToPoint:NSMakePoint(x, NSMaxY(labelRect))];
    }
    for (CGFloat y = labelRect.origin.y + step; y < NSMaxY(labelRect); y += step) {
        [path moveToPoint:NSMakePoint(labelRect.origin.x, y)];
        [path lineToPoint:NSMakePoint(NSMaxX(labelRect), y)];
    }
    path.lineWidth = 1;
    [path stroke];
}

- (void)drawElement:(SMDesignerElement *)element selected:(BOOL)selected {
    NSRect rect = [self viewRectForDotsRect:element.frameDots];
    if (element.type == SMDesignerElementTypeImage) {
        if (element.image) {
            [element.image drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:YES hints:nil];
        }
        else {
            [[NSColor colorWithCalibratedWhite:0.94 alpha:1] setFill];
            NSRectFill(rect);
            [@"Image" drawInRect:rect withAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:12], NSForegroundColorAttributeName: COLOR_77}];
        }
    }
    else {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.alignment = element.alignment;
        style.lineBreakMode = NSLineBreakByTruncatingTail;
        NSFont *font = [self fontForElement:element scaled:YES];
        NSDictionary *attrs = @{NSFontAttributeName: font,
                                NSForegroundColorAttributeName: [NSColor blackColor],
                                NSParagraphStyleAttributeName: style};
        [element.text drawInRect:rect withAttributes:attrs];
    }

    if (selected) {
        [[NSColor systemBlueColor] setStroke];
        NSBezierPath *selection = [NSBezierPath bezierPathWithRect:NSInsetRect(rect, -2, -2)];
        selection.lineWidth = 2;
        [selection stroke];
        [[NSColor systemBlueColor] setFill];
        CGFloat s = 6;
        NSRectFill(NSMakeRect(NSMaxX(rect) - s / 2, NSMaxY(rect) - s / 2, s, s));
    }
}

- (NSFont *)fontForElement:(SMDesignerElement *)element scaled:(BOOL)scaled {
    CGFloat size = MAX(4, element.fontSizeDots * (scaled ? self.zoom : 1));
    NSFont *font = nil;
    if (element.bold) {
        font = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:element.fontName size:size] ?: [NSFont systemFontOfSize:size] toHaveTrait:NSBoldFontMask];
    }
    else {
        font = [NSFont fontWithName:element.fontName size:size];
    }
    return font ?: [NSFont systemFontOfSize:size weight:element.bold ? NSFontWeightBold : NSFontWeightRegular];
}

- (NSRect)viewRectForDotsRect:(CGRect)dotsRect {
    NSRect labelRect = [self labelRectInView];
    return NSMakeRect(labelRect.origin.x + dotsRect.origin.x * self.zoom,
                      labelRect.origin.y + dotsRect.origin.y * self.zoom,
                      dotsRect.size.width * self.zoom,
                      dotsRect.size.height * self.zoom);
}

- (CGPoint)dotsPointForViewPoint:(NSPoint)viewPoint {
    NSRect labelRect = [self labelRectInView];
    return CGPointMake((viewPoint.x - labelRect.origin.x) / self.zoom,
                       (viewPoint.y - labelRect.origin.y) / self.zoom);
}

#pragma mark - Mouse

- (void)mouseDown:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    SMDesignerElement *hit = [self hitTestElementAtPoint:point];
    [self selectElement:hit];
    if (hit) {
        self.dragging = YES;
        CGPoint dots = [self dotsPointForViewPoint:point];
        self.dragOffsetDots = CGPointMake(dots.x - hit.frameDots.origin.x, dots.y - hit.frameDots.origin.y);
        if (event.clickCount == 2 && hit.type == SMDesignerElementTypeText) {
            [self editSelectedTextQuickly];
        }
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if (!self.dragging || !self.selectedElement) {
        return;
    }
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    CGPoint dots = [self dotsPointForViewPoint:point];
    CGRect frame = self.selectedElement.frameDots;
    frame.origin.x = round(dots.x - self.dragOffsetDots.x);
    frame.origin.y = round(dots.y - self.dragOffsetDots.y);
    self.selectedElement.frameDots = frame;
    [self constrainElementsToLabel];
    [self setNeedsDisplay:YES];
    if ([self.delegate respondsToSelector:@selector(designerCanvasDidChange:)]) {
        [self.delegate designerCanvasDidChange:self];
    }
}

- (void)mouseUp:(NSEvent *)event {
    self.dragging = NO;
}

- (SMDesignerElement *)hitTestElementAtPoint:(NSPoint)point {
    for (SMDesignerElement *element in [self.elements reverseObjectEnumerator]) {
        if (NSPointInRect(point, [self viewRectForDotsRect:element.frameDots])) {
            return element;
        }
    }
    return nil;
}

- (void)editSelectedTextQuickly {
    if (!self.selectedElement || self.selectedElement.type != SMDesignerElementTypeText) {
        return;
    }
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Edit text";
    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 260, 24)];
    field.stringValue = self.selectedElement.text ?: @"";
    alert.accessoryView = field;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        self.selectedElement.text = field.stringValue;
        [self notifyElementChanged];
    }
}

@end
