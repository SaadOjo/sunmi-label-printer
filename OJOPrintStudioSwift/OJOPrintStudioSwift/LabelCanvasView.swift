import AppKit
import SwiftUI

struct LabelCanvasView: NSViewRepresentable {
    @ObservedObject var store: LabelDesignerStore

    func makeNSView(context: Context) -> DesignerCanvasNSView {
        let view = DesignerCanvasNSView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: DesignerCanvasNSView, context: Context) {
        configure(nsView)
    }

    private func configure(_ view: DesignerCanvasNSView) {
        view.state = DesignerCanvasState(widthDots: store.widthDots,
                                         heightDots: store.heightDots,
                                         showGrid: store.showGrid,
                                         elements: store.elements,
                                         selectedID: store.selectedElementID)
        view.onSelect = { id in
            store.select(id)
        }
        view.onSetFrame = { id, frame in
            store.setFrame(for: id, frame: frame)
        }
        view.onSetText = { id, text in
            store.setText(for: id, text: text)
        }
    }
}

struct DesignerCanvasState {
    var widthDots: CGFloat = 80
    var heightDots: CGFloat = 40
    var showGrid: Bool = true
    var elements: [DesignerElement] = []
    var selectedID: UUID?
}

final class DesignerCanvasNSView: NSView, NSTextViewDelegate {
    var state = DesignerCanvasState() {
        didSet {
            reconcileInlineEditor()
            needsDisplay = true
        }
    }

    var onSelect: ((UUID?) -> Void)?
    var onSetFrame: ((UUID, CGRect) -> Void)?
    var onSetText: ((UUID, String) -> Void)?

    private var activeDragID: UUID?
    private var activeResizeID: UUID?
    private var activeStartFrame: CGRect?
    private var activeTranslation: CGSize = .zero
    private var mouseDownPoint: CGPoint?

    private var editingTextID: UUID?
    private weak var inlineTextView: InlineCanvasNSTextView?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func layout() {
        super.layout()
        updateInlineEditorFrameAndStyle()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        drawBackground()
        drawPage()
        if state.showGrid {
            drawGrid()
        }
        drawElements()
        drawSelectionHandle()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        mouseDownPoint = point
        clearActiveInteraction()

        if editingTextID != nil {
            finishInlineEditing()
        }

        guard pageRect.contains(point) else {
            select(nil)
            return
        }

        if let selected = selectedElement,
           resizeHandleHitRect(for: selected).contains(point) {
            activeResizeID = selected.id
            activeStartFrame = selected.frameDots
            activeTranslation = .zero
            select(selected.id)
            return
        }

        guard let hit = hitTestElement(at: point) else {
            select(nil)
            return
        }

        if hit.kind == .text,
           hit.id == state.selectedID || event.clickCount >= 2 {
            startInlineEditing(hit)
            return
        }

        activeDragID = hit.id
        activeStartFrame = hit.frameDots
        activeTranslation = .zero
        select(hit.id)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let mouseDownPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        activeTranslation = CGSize(width: point.x - mouseDownPoint.x,
                                   height: point.y - mouseDownPoint.y)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let mouseDownPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        let translation = CGSize(width: point.x - mouseDownPoint.x,
                                 height: point.y - mouseDownPoint.y)
        commitActiveInteraction(translation: translation)
        self.mouseDownPoint = nil
    }

    override func keyDown(with event: NSEvent) {
        guard inlineTextView == nil else {
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case 53: // Escape
            select(nil)
        default:
            super.keyDown(with: event)
        }
    }

    // MARK: - Drawing

    private func drawBackground() {
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 18, yRadius: 18).fill()
    }

    private func drawPage() {
        let rect = pageRect
        guard rect.width > 0, rect.height > 0 else { return }

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.10)
        shadow.shadowBlurRadius = 18
        shadow.shadowOffset = NSSize(width: 0, height: 6)
        shadow.set()
        NSColor.white.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3).fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor.black.withAlphaComponent(0.12).setStroke()
        let border = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
        border.lineWidth = 1
        border.stroke()
    }

    private func drawGrid() {
        let rect = pageRect
        let scale = canvasScale
        let minorStep = ojoDotsPerMillimeter * scale
        let majorStep = ojoDotsPerMillimeter * 5 * scale

        drawGridLines(in: rect,
                      step: minorStep,
                      color: NSColor.black.withAlphaComponent(0.055),
                      lineWidth: 0.5)
        drawGridLines(in: rect,
                      step: majorStep,
                      color: NSColor.black.withAlphaComponent(0.11),
                      lineWidth: 0.8)
    }

    private func drawGridLines(in rect: CGRect, step: CGFloat, color: NSColor, lineWidth: CGFloat) {
        guard step > 0 else { return }
        let path = NSBezierPath()
        var x = rect.minX
        while x <= rect.maxX + 0.5 {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.line(to: CGPoint(x: x, y: rect.maxY))
            x += step
        }
        var y = rect.minY
        while y <= rect.maxY + 0.5 {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.line(to: CGPoint(x: rect.maxX, y: y))
            y += step
        }
        color.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }

    private func drawElements() {
        for element in state.elements {
            let frame = displayedFrame(for: element)
            let rect = viewRect(for: frame)
            let selected = state.selectedID == element.id

            if selected {
                NSColor.controlAccentColor.withAlphaComponent(0.08).setFill()
                NSBezierPath(rect: rect).fill()
            }

            if !(editingTextID == element.id && element.kind == .text) {
                drawElementContent(element, in: rect)
            }

            drawElementBorder(in: rect, selected: selected)
        }
    }

    private func drawElementContent(_ element: DesignerElement, in rect: CGRect) {
        switch element.kind {
        case .image:
            guard let image = element.image else { return }
            let target = fittedRect(for: image, in: rect.insetBy(dx: 1, dy: 1))
            image.draw(in: target, from: .zero, operation: .sourceOver, fraction: 1.0)
        case .text:
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = element.alignment.nsAlignment
            paragraph.lineBreakMode = .byTruncatingTail

            let fontSize = max(5, element.fontSizeDots * canvasScale)
            let baseFont = NSFont(name: element.fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
            let font = element.isBold
                ? NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                : baseFont

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black,
                .paragraphStyle: paragraph
            ]
            let text = element.text.isEmpty ? "Text" : element.text
            (text as NSString).draw(in: rect.insetBy(dx: 2, dy: 1), withAttributes: attributes)
        }
    }

    private func drawElementBorder(in rect: CGRect, selected: Bool) {
        let path = NSBezierPath(rect: rect)
        path.lineWidth = selected ? 2 : 1
        if selected {
            NSColor.controlAccentColor.setStroke()
        } else {
            var dash: [CGFloat] = [4, 3]
            path.setLineDash(&dash, count: dash.count, phase: 0)
            NSColor.black.withAlphaComponent(0.18).setStroke()
        }
        path.stroke()
    }

    private func drawSelectionHandle() {
        guard let selected = selectedElement else { return }
        let handle = resizeHandleRect(for: selected)
        NSColor.controlAccentColor.setFill()
        NSBezierPath(roundedRect: handle, xRadius: 3, yRadius: 3).fill()
        NSColor.white.setStroke()
        let border = NSBezierPath(roundedRect: handle, xRadius: 3, yRadius: 3)
        border.lineWidth = 2
        border.stroke()
    }

    // MARK: - Interaction

    private func select(_ id: UUID?) {
        state.selectedID = id
        onSelect?(id)
        needsDisplay = true
    }

    private func clearActiveInteraction() {
        activeDragID = nil
        activeResizeID = nil
        activeStartFrame = nil
        activeTranslation = .zero
    }

    private func commitActiveInteraction(translation: CGSize) {
        defer {
            clearActiveInteraction()
            needsDisplay = true
        }

        let scale = canvasScale
        guard scale > 0, var frame = activeStartFrame else { return }

        if let resizeID = activeResizeID {
            frame.size.width += translation.width / scale
            frame.size.height += translation.height / scale
            onSetFrame?(resizeID, frame)
        } else if let dragID = activeDragID {
            let dx = translation.width / scale
            let dy = translation.height / scale
            guard abs(dx) > 0.5 || abs(dy) > 0.5 else { return }
            frame.origin.x += dx
            frame.origin.y += dy
            onSetFrame?(dragID, frame)
        }
    }

    private func hitTestElement(at point: CGPoint) -> DesignerElement? {
        guard let dotPoint = dotPoint(from: point) else { return nil }
        let hitSlopDots = max(3, 8 / max(0.1, canvasScale))
        return state.elements.reversed().first { element in
            clamped(element.frameDots)
                .insetBy(dx: -hitSlopDots, dy: -hitSlopDots)
                .contains(dotPoint)
        }
    }

    private func resizeHandleHitRect(for element: DesignerElement) -> CGRect {
        resizeHandleRect(for: element).insetBy(dx: -8, dy: -8)
    }

    private func resizeHandleRect(for element: DesignerElement) -> CGRect {
        let frame = displayedFrame(for: element)
        let rect = viewRect(for: frame)
        let size: CGFloat = 12
        return CGRect(x: rect.maxX - size / 2,
                      y: rect.maxY - size / 2,
                      width: size,
                      height: size)
    }

    // MARK: - Inline text editing

    private func startInlineEditing(_ element: DesignerElement) {
        finishInlineEditing()
        editingTextID = element.id
        select(element.id)

        let textView = InlineCanvasNSTextView(frame: editorFrame(for: element))
        textView.delegate = self
        textView.string = element.text
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.drawsBackground = true
        textView.backgroundColor = NSColor.white.withAlphaComponent(0.98)
        textView.textContainerInset = NSSize(width: 3, height: 2)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = false
        textView.onResignFirstResponder = { [weak self] in
            self?.finishInlineEditing()
        }

        inlineTextView = textView
        addSubview(textView)
        applyTextStyle(to: textView, element: element)
        window?.makeFirstResponder(textView)
        textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))
        needsDisplay = true
    }

    private func finishInlineEditing() {
        guard let editingTextID else { return }
        if let text = inlineTextView?.string {
            updateLocalText(id: editingTextID, text: text)
            onSetText?(editingTextID, text)
        }
        inlineTextView?.delegate = nil
        inlineTextView?.removeFromSuperview()
        inlineTextView = nil
        self.editingTextID = nil
        needsDisplay = true
    }

    private func reconcileInlineEditor() {
        guard let editingTextID else { return }
        guard state.selectedID == editingTextID,
              let element = element(with: editingTextID),
              element.kind == .text else {
            finishInlineEditing()
            return
        }
        updateInlineEditorFrameAndStyle()
    }

    private func updateInlineEditorFrameAndStyle() {
        guard let textView = inlineTextView,
              let editingTextID,
              let element = element(with: editingTextID) else { return }
        textView.frame = editorFrame(for: element)
        applyTextStyle(to: textView, element: element)
    }

    private func editorFrame(for element: DesignerElement) -> CGRect {
        viewRect(for: displayedFrame(for: element)).insetBy(dx: 2, dy: 2)
    }

    private func applyTextStyle(to textView: NSTextView, element: DesignerElement) {
        let fontSize = max(5, element.fontSizeDots * canvasScale)
        let baseFont = NSFont(name: element.fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let font = element.isBold
            ? NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
            : baseFont
        textView.font = font
        textView.alignment = element.alignment.nsAlignment
        textView.textColor = .black
        textView.insertionPointColor = .controlAccentColor
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView,
              let editingTextID else { return }
        updateLocalText(id: editingTextID, text: textView.string)
        onSetText?(editingTextID, textView.string)
    }

    private func updateLocalText(id: UUID, text: String) {
        guard let index = state.elements.firstIndex(where: { $0.id == id }) else { return }
        state.elements[index].text = text
        needsDisplay = true
    }

    // MARK: - Geometry

    private var canvasScale: CGFloat {
        let horizontal = max(0.2, (bounds.width - 92) / max(1, state.widthDots))
        let vertical = max(0.2, (bounds.height - 92) / max(1, state.heightDots))
        return min(2.6, max(0.25, min(horizontal, vertical)))
    }

    private var pageRect: CGRect {
        let scale = canvasScale
        let size = CGSize(width: state.widthDots * scale, height: state.heightDots * scale)
        return CGRect(x: bounds.midX - size.width / 2,
                      y: bounds.midY - size.height / 2,
                      width: size.width,
                      height: size.height)
    }

    private var selectedElement: DesignerElement? {
        guard let selectedID = state.selectedID else { return nil }
        return element(with: selectedID)
    }

    private func element(with id: UUID) -> DesignerElement? {
        state.elements.first { $0.id == id }
    }

    private func displayedFrame(for element: DesignerElement) -> CGRect {
        var frame = element.frameDots
        let scale = canvasScale
        if activeDragID == element.id {
            frame.origin.x += activeTranslation.width / scale
            frame.origin.y += activeTranslation.height / scale
        }
        if activeResizeID == element.id {
            frame.size.width += activeTranslation.width / scale
            frame.size.height += activeTranslation.height / scale
        }
        return clamped(frame)
    }

    private func viewRect(for frame: CGRect) -> CGRect {
        let page = pageRect
        let scale = canvasScale
        return CGRect(x: page.minX + frame.minX * scale,
                      y: page.minY + frame.minY * scale,
                      width: max(1, frame.width * scale),
                      height: max(1, frame.height * scale))
    }

    private func dotPoint(from point: CGPoint) -> CGPoint? {
        let page = pageRect
        guard page.contains(point) else { return nil }
        let scale = canvasScale
        return CGPoint(x: (point.x - page.minX) / scale,
                       y: (point.y - page.minY) / scale)
    }

    private func clamped(_ frame: CGRect) -> CGRect {
        var rect = frame.standardized
        rect.size.width = max(4, min(rect.width, state.widthDots))
        rect.size.height = max(4, min(rect.height, state.heightDots))
        rect.origin.x = max(0, min(rect.origin.x, state.widthDots - rect.width))
        rect.origin.y = max(0, min(rect.origin.y, state.heightDots - rect.height))
        return rect
    }

    private func fittedRect(for image: NSImage, in rect: CGRect) -> CGRect {
        guard image.size.width > 0, image.size.height > 0, rect.width > 0, rect.height > 0 else {
            return rect
        }
        let scale = min(rect.width / image.size.width, rect.height / image.size.height)
        let width = image.size.width * scale
        let height = image.size.height * scale
        return CGRect(x: rect.midX - width / 2,
                      y: rect.midY - height / 2,
                      width: width,
                      height: height)
    }
}

private final class InlineCanvasNSTextView: NSTextView {
    var onResignFirstResponder: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            DispatchQueue.main.async { [weak self] in
                self?.onResignFirstResponder?()
            }
        }
        return result
    }
}
