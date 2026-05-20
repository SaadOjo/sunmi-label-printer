import AppKit
import SwiftUI

struct LabelCanvasView: View {
    @ObservedObject var store: LabelDesignerStore
    @State private var activeDragID: UUID?
    @State private var activeDragStartFrame: CGRect?
    @State private var activeDragTranslation: CGSize = .zero
    @State private var activeResizeID: UUID?
    @State private var activeResizeStartFrame: CGRect?
    @State private var activeResizeTranslation: CGSize = .zero
    @State private var editingTextID: UUID?
    @State private var inlineText: String = ""
    @State private var isInlineTextFocused: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let pageDots = CGSize(width: store.widthDots, height: store.heightDots)
            let scale = canvasScale(for: geometry.size, pageDots: pageDots)
            let pageSize = CGSize(width: pageDots.width * scale, height: pageDots.height * scale)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
                        .frame(width: pageSize.width, height: pageSize.height)
                        .contentShape(Rectangle())

                    if store.showGrid {
                        grid(scale: scale)
                            .frame(width: pageSize.width, height: pageSize.height)
                    }

                    ForEach(store.elements) { element in
                        elementView(element, scale: scale)
                    }

                    selectionOverlay(scale: scale)
                        .frame(width: pageSize.width, height: pageSize.height)
                        .allowsHitTesting(false)

                    inlineTextEditor(scale: scale)
                        .frame(width: pageSize.width, height: pageSize.height)
                        .zIndex(900)

                    CanvasMouseOverlay(
                        passthroughRect: inlineEditorRect(scale: scale),
                        onMouseDown: { point, clickCount in
                            beginInteraction(at: point, scale: scale, clickCount: clickCount)
                        },
                        onMouseDragged: { translation in
                            updateInteraction(translation: translation)
                        },
                        onMouseUp: { translation in
                            finishInteraction(translation: translation, scale: scale)
                        }
                    )
                    .frame(width: pageSize.width, height: pageSize.height)
                    .zIndex(1_000)
                }
                .frame(width: pageSize.width, height: pageSize.height, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func canvasScale(for available: CGSize, pageDots: CGSize) -> CGFloat {
        let horizontal = max(0.2, (available.width - 92) / max(1, pageDots.width))
        let vertical = max(0.2, (available.height - 92) / max(1, pageDots.height))
        return min(2.6, max(0.25, min(horizontal, vertical)))
    }

    private func grid(scale: CGFloat) -> some View {
        Canvas { context, size in
            let minorStep = ojoDotsPerMillimeter * scale
            let majorStep = ojoDotsPerMillimeter * 5 * scale

            var minor = Path()
            var x: CGFloat = 0
            while x <= size.width + 0.5 {
                minor.move(to: CGPoint(x: x, y: 0))
                minor.addLine(to: CGPoint(x: x, y: size.height))
                x += minorStep
            }
            var y: CGFloat = 0
            while y <= size.height + 0.5 {
                minor.move(to: CGPoint(x: 0, y: y))
                minor.addLine(to: CGPoint(x: size.width, y: y))
                y += minorStep
            }
            context.stroke(minor, with: .color(Color.black.opacity(0.055)), lineWidth: 0.5)

            var major = Path()
            x = 0
            while x <= size.width + 0.5 {
                major.move(to: CGPoint(x: x, y: 0))
                major.addLine(to: CGPoint(x: x, y: size.height))
                x += majorStep
            }
            y = 0
            while y <= size.height + 0.5 {
                major.move(to: CGPoint(x: 0, y: y))
                major.addLine(to: CGPoint(x: size.width, y: y))
                y += majorStep
            }
            context.stroke(major, with: .color(Color.black.opacity(0.11)), lineWidth: 0.8)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func elementView(_ element: DesignerElement, scale: CGFloat) -> some View {
        let frame = displayedFrame(for: element, scale: scale)
        let selected = store.selectedElementID == element.id

        Group {
            if element.kind == .image, let image = element.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(1)
            } else {
                Text(element.text.isEmpty ? "Text" : element.text)
                    .font(.custom(element.fontName, size: max(5, element.fontSizeDots * scale)))
                    .fontWeight(element.isBold ? .bold : .regular)
                    .foregroundColor(.black)
                    .multilineTextAlignment(element.alignment.multilineTextAlignment)
                    .lineLimit(3)
                    .minimumScaleFactor(0.35)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: element.alignment.swiftUIAlignment)
                    .padding(.horizontal, 2)
            }
        }
        .frame(width: max(1, frame.width * scale), height: max(1, frame.height * scale))
        .background(selected ? Color.accentColor.opacity(0.08) : Color.clear)
        .overlay(
            Rectangle()
                .stroke(selected ? Color.accentColor : Color.black.opacity(0.18),
                        style: StrokeStyle(lineWidth: selected ? 2 : 1, dash: selected ? [] : [4, 3]))
        )
        .position(x: (frame.midX * scale), y: (frame.midY * scale))
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func selectionOverlay(scale: CGFloat) -> some View {
        if let selected = store.selectedElement {
            let frame = displayedFrame(for: selected, scale: scale)
            let width = max(1, frame.width * scale)
            let height = max(1, frame.height * scale)
            let handleSize: CGFloat = 12

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 2)
                    .background(Color.accentColor.opacity(0.07))
                    .frame(width: width, height: height)
                    .position(x: frame.midX * scale, y: frame.midY * scale)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: handleSize, height: handleSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.22), radius: 3, x: 0, y: 1)
                    .position(x: frame.maxX * scale, y: frame.maxY * scale)
            }
        }
    }

    @ViewBuilder
    private func inlineTextEditor(scale: CGFloat) -> some View {
        if let id = editingTextID,
           let element = store.elements.first(where: { $0.id == id }),
           element.kind == .text {
            let frame = displayedFrame(for: element, scale: scale)

            InlineCanvasTextView(text: Binding(
                get: { inlineText },
                set: { newValue in
                    inlineText = newValue
                    store.setText(for: id, text: newValue)
                }
            ),
            isFocused: $isInlineTextFocused,
            fontName: element.fontName,
            fontSize: max(5, element.fontSizeDots * scale),
            isBold: element.isBold,
            alignment: element.alignment.nsAlignment)
            .padding(2)
            .background(Color.white.opacity(0.96))
            .overlay(Rectangle().stroke(Color.accentColor, lineWidth: 2))
            .frame(width: max(24, frame.width * scale), height: max(20, frame.height * scale))
            .position(x: frame.midX * scale, y: frame.midY * scale)
            .onChange(of: isInlineTextFocused) { focused in
                if !focused {
                    finishInlineEditing()
                }
            }
        }
    }

    private func displayedFrame(for element: DesignerElement, scale: CGFloat) -> CGRect {
        var frame = element.frameDots
        if activeDragID == element.id {
            frame.origin.x += activeDragTranslation.width / scale
            frame.origin.y += activeDragTranslation.height / scale
        }
        if activeResizeID == element.id {
            frame.size.width += activeResizeTranslation.width / scale
            frame.size.height += activeResizeTranslation.height / scale
        }
        return clamped(frame)
    }

    private func beginInteraction(at point: CGPoint, scale: CGFloat, clickCount: Int) {
        clearInteraction()

        if editingTextID != nil {
            finishInlineEditing()
        }

        if let selected = store.selectedElement,
           resizeHandleContains(point: point, element: selected, scale: scale) {
            activeResizeID = selected.id
            activeResizeStartFrame = selected.frameDots
            activeResizeTranslation = .zero
            store.select(selected.id)
            return
        }

        if let hit = element(at: point, scale: scale) {
            // Text click flow:
            // 1st click selects the text element.
            // 2nd click on that selected text element enters text-edit mode.
            // Once in edit mode, clicks inside the editor pass through to NSTextView so the cursor lands correctly.
            if hit.kind == .text,
               hit.id == store.selectedElementID || clickCount >= 2 {
                startInlineEditing(hit)
                return
            }

            activeDragID = hit.id
            activeDragStartFrame = hit.frameDots
            activeDragTranslation = .zero
            store.select(hit.id)
            return
        }

        store.select(nil)
    }

    private func updateInteraction(translation: CGSize) {
        if activeResizeID != nil {
            activeResizeTranslation = translation
        } else if activeDragID != nil {
            activeDragTranslation = translation
        }
    }

    private func finishInteraction(translation: CGSize, scale: CGFloat) {
        if let resizeID = activeResizeID, var start = activeResizeStartFrame {
            start.size.width += translation.width / scale
            start.size.height += translation.height / scale
            store.setFrame(for: resizeID, frame: start)
        } else if let dragID = activeDragID, var start = activeDragStartFrame {
            let dx = translation.width / scale
            let dy = translation.height / scale
            if abs(dx) > 0.5 || abs(dy) > 0.5 {
                start.origin.x += dx
                start.origin.y += dy
                store.setFrame(for: dragID, frame: start)
            }
        }
        clearInteraction()
    }

    private func clearInteraction() {
        activeDragID = nil
        activeDragStartFrame = nil
        activeDragTranslation = .zero
        activeResizeID = nil
        activeResizeStartFrame = nil
        activeResizeTranslation = .zero
    }

    private func startInlineEditing(_ element: DesignerElement) {
        clearInteraction()
        store.select(element.id)
        editingTextID = element.id
        inlineText = element.text
        DispatchQueue.main.async {
            isInlineTextFocused = true
        }
    }

    private func finishInlineEditing() {
        guard let id = editingTextID else { return }
        store.setText(for: id, text: inlineText)
        editingTextID = nil
        inlineText = ""
        isInlineTextFocused = false
    }

    private func inlineEditorRect(scale: CGFloat) -> CGRect? {
        guard let id = editingTextID,
              let element = store.elements.first(where: { $0.id == id }) else {
            return nil
        }
        let frame = displayedFrame(for: element, scale: scale)
        return CGRect(x: frame.minX * scale,
                      y: frame.minY * scale,
                      width: max(24, frame.width * scale),
                      height: max(20, frame.height * scale))
            .insetBy(dx: -4, dy: -4)
    }

    private func element(at point: CGPoint, scale: CGFloat) -> DesignerElement? {
        let dotPoint = CGPoint(x: point.x / scale, y: point.y / scale)
        let hitSlopDots = max(3, 8 / scale)
        return store.elements.reversed().first { element in
            clamped(element.frameDots)
                .insetBy(dx: -hitSlopDots, dy: -hitSlopDots)
                .contains(dotPoint)
        }
    }

    private func resizeHandleContains(point: CGPoint, element: DesignerElement, scale: CGFloat) -> Bool {
        let frame = displayedFrame(for: element, scale: scale)
        let center = CGPoint(x: frame.maxX * scale, y: frame.maxY * scale)
        let hitSize: CGFloat = 28
        let hitRect = CGRect(x: center.x - hitSize / 2,
                             y: center.y - hitSize / 2,
                             width: hitSize,
                             height: hitSize)
        return hitRect.contains(point)
    }

    private func clamped(_ frame: CGRect) -> CGRect {
        var rect = frame.standardized
        let widthDots = store.widthDots
        let heightDots = store.heightDots
        rect.size.width = max(4, min(rect.width, widthDots))
        rect.size.height = max(4, min(rect.height, heightDots))
        rect.origin.x = max(0, min(rect.origin.x, widthDots - rect.width))
        rect.origin.y = max(0, min(rect.origin.y, heightDots - rect.height))
        return rect
    }
}

private struct InlineCanvasTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let fontName: String
    let fontSize: CGFloat
    let isBold: Bool
    let alignment: NSTextAlignment

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> EditableTextView {
        let textView = EditableTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 3, height: 2)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                  height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = .zero
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = false
        textView.onFocusLost = {
            isFocused = false
        }
        applyStyle(to: textView)
        textView.string = text
        return textView
    }

    func updateNSView(_ textView: EditableTextView, context: Context) {
        context.coordinator.parent = self
        textView.onFocusLost = {
            isFocused = false
        }
        applyStyle(to: textView)

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges.compactMap { rangeValue in
                let range = rangeValue.rangeValue
                guard range.location <= (text as NSString).length else { return nil }
                return NSValue(range: NSRange(location: range.location,
                                              length: min(range.length, (text as NSString).length - range.location)))
            }
        }

        if isFocused, textView.window?.firstResponder !== textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    private func applyStyle(to textView: NSTextView) {
        let baseFont = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        textView.font = isBold ? NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask) : baseFont
        textView.alignment = alignment
        textView.textColor = .black
        textView.insertionPointColor = .controlAccentColor
        textView.typingAttributes = [
            .font: textView.font ?? baseFont,
            .foregroundColor: NSColor.black
        ]
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: InlineCanvasTextView

        init(_ parent: InlineCanvasTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }

    final class EditableTextView: NSTextView {
        var onFocusLost: (() -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }

        override func resignFirstResponder() -> Bool {
            let result = super.resignFirstResponder()
            if result {
                DispatchQueue.main.async { [weak self] in
                    self?.onFocusLost?()
                }
            }
            return result
        }
    }
}

private struct CanvasMouseOverlay: NSViewRepresentable {
    var passthroughRect: CGRect?
    var onMouseDown: (CGPoint, Int) -> Void
    var onMouseDragged: (CGSize) -> Void
    var onMouseUp: (CGSize) -> Void

    func makeNSView(context: Context) -> MouseCaptureView {
        let view = MouseCaptureView()
        view.passthroughRect = passthroughRect
        view.onMouseDown = onMouseDown
        view.onMouseDragged = onMouseDragged
        view.onMouseUp = onMouseUp
        return view
    }

    func updateNSView(_ nsView: MouseCaptureView, context: Context) {
        nsView.passthroughRect = passthroughRect
        nsView.onMouseDown = onMouseDown
        nsView.onMouseDragged = onMouseDragged
        nsView.onMouseUp = onMouseUp
    }

    final class MouseCaptureView: NSView {
        var passthroughRect: CGRect?
        var onMouseDown: (CGPoint, Int) -> Void = { _, _ in }
        var onMouseDragged: (CGSize) -> Void = { _ in }
        var onMouseUp: (CGSize) -> Void = { _ in }

        private var mouseDownPoint: CGPoint?

        override var isFlipped: Bool { true }
        override var acceptsFirstResponder: Bool { true }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            if let passthroughRect, passthroughRect.contains(point) {
                return nil
            }
            return super.hitTest(point)
        }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
            let point = convert(event.locationInWindow, from: nil)
            mouseDownPoint = point
            onMouseDown(point, event.clickCount)
        }

        override func mouseDragged(with event: NSEvent) {
            guard let mouseDownPoint else { return }
            let point = convert(event.locationInWindow, from: nil)
            onMouseDragged(CGSize(width: point.x - mouseDownPoint.x,
                                  height: point.y - mouseDownPoint.y))
        }

        override func mouseUp(with event: NSEvent) {
            guard let mouseDownPoint else { return }
            let point = convert(event.locationInWindow, from: nil)
            onMouseUp(CGSize(width: point.x - mouseDownPoint.x,
                             height: point.y - mouseDownPoint.y))
            self.mouseDownPoint = nil
        }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .arrow)
        }
    }
}
