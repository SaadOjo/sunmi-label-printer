import AppKit
import SwiftUI

let ojoDotsPerMillimeter: CGFloat = 8.0

enum LabelPreset: String, CaseIterable, Identifiable, Codable {
    case fiftyByTwenty = "50 × 20 mm"
    case seventyEightBySixty = "78 × 60 mm"
    case custom = "Custom"

    var id: String { rawValue }

    var size: (width: Double, height: Double, gap: Double)? {
        switch self {
        case .fiftyByTwenty:
            return (50, 20, 3)
        case .seventyEightBySixty:
            return (78, 60, 3)
        case .custom:
            return nil
        }
    }
}

enum DesignerElementKind: String, Codable {
    case text
    case image
}

enum DesignerTextAlignment: String, CaseIterable, Identifiable, Codable {
    case left = "Left"
    case center = "Center"
    case right = "Right"

    var id: String { rawValue }

    var nsAlignment: NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }

    var swiftUIAlignment: Alignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }

    var multilineTextAlignment: TextAlignment {
        switch self {
        case .left: return .leading
        case .center: return .center
        case .right: return .trailing
        }
    }
}

struct DesignerElement: Identifiable, @unchecked Sendable {
    let id: UUID
    var kind: DesignerElementKind
    var frameDots: CGRect
    var text: String
    var fontName: String
    var fontSizeDots: CGFloat
    var isBold: Bool
    var alignment: DesignerTextAlignment
    var image: NSImage?
    var imageName: String?

    init(id: UUID = UUID(),
         kind: DesignerElementKind,
         frameDots: CGRect,
         text: String = "Text",
         fontName: String = "Helvetica Neue",
         fontSizeDots: CGFloat = 28,
         isBold: Bool = false,
         alignment: DesignerTextAlignment = .left,
         image: NSImage? = nil,
         imageName: String? = nil) {
        self.id = id
        self.kind = kind
        self.frameDots = frameDots
        self.text = text
        self.fontName = fontName
        self.fontSizeDots = fontSizeDots
        self.isBold = isBold
        self.alignment = alignment
        self.image = image
        self.imageName = imageName
    }
}

struct LabelPreviewResult: @unchecked Sendable {
    let image: NSImage
}

struct LabelPrintSnapshot: @unchecked Sendable {
    let widthMM: Double
    let heightMM: Double
    let gapMM: Double
    let density: Int
    let invertBitmapBits: Bool
    let elements: [DesignerElement]

    func makePrintData() -> Data {
        TSPLRasterBuilder.printData(widthMM: widthMM,
                                    heightMM: heightMM,
                                    gapMM: gapMM,
                                    density: density,
                                    invertBitmapBits: invertBitmapBits,
                                    elements: elements)
    }
}

@MainActor
final class LabelDesignerStore: ObservableObject {
    @Published var selectedPreset: LabelPreset = .fiftyByTwenty {
        didSet { schedulePersistenceIfReady() }
    }
    @Published var widthMM: Double = 50 {
        didSet {
            mediaValueChanged()
            schedulePersistenceIfReady()
        }
    }
    @Published var heightMM: Double = 20 {
        didSet {
            mediaValueChanged()
            schedulePersistenceIfReady()
        }
    }
    @Published var gapMM: Double = 3 {
        didSet {
            let value = clamped(gapMM, min: 0, max: 20)
            if abs(value - gapMM) > 0.001 { gapMM = value }
            schedulePersistenceIfReady()
        }
    }
    @Published var density: Int = 12 {
        didSet {
            let value = Int(clamped(Double(density), min: 0, max: 15))
            if value != density { density = value }
            schedulePersistenceIfReady()
        }
    }
    @Published var invertBitmapBits: Bool = true {
        didSet { schedulePersistenceIfReady() }
    }
    @Published var showGrid: Bool = true {
        didSet { schedulePersistenceIfReady() }
    }
    @Published private(set) var elements: [DesignerElement] = []
    @Published var selectedElementID: UUID?
    @Published private(set) var bitmapPreviewImage: NSImage?
    @Published private(set) var isRenderingBitmapPreview: Bool = false

    private var isNormalizingMedia = false
    private var isApplyingPreset = false
    private static let persistenceKey = "OJOPrintStudioSwift.LabelDesignerState.v4"
    private static let legacyPersistenceKeys = [
        "OJOPrintStudioSwift.LabelDesignerState.v3",
        "OJOPrintStudioSwift.LabelDesignerState.v2",
        "OJOPrintStudioSwift.LabelDesignerState.v1"
    ]
    private static let defaultInvertBitmapBits = true

    private var isRestoringState = false
    private var previewRenderTask: Task<Void, Never>?
    private var persistenceTask: Task<Void, Never>?

    init() {
        if restorePersistedState() {
            schedulePreviewRender(immediate: true)
        } else {
            elements = Self.defaultElements()
            selectedElementID = elements.first?.id
            schedulePreviewRender(immediate: true)
            persistNow()
        }
    }

    var widthDots: CGFloat {
        max(80, CGFloat(widthMM) * ojoDotsPerMillimeter)
    }

    var heightDots: CGFloat {
        max(40, CGFloat(heightMM) * ojoDotsPerMillimeter)
    }

    var selectedElement: DesignerElement? {
        guard let selectedElementID else { return nil }
        return elements.first { $0.id == selectedElementID }
    }

    var summary: String {
        TSPLRasterBuilder.summary(widthMM: widthMM,
                                  heightMM: heightMM,
                                  gapMM: gapMM,
                                  density: density,
                                  invertBitmapBits: invertBitmapBits,
                                  elements: elements)
    }

    func printSnapshot() -> LabelPrintSnapshot {
        LabelPrintSnapshot(widthMM: widthMM,
                           heightMM: heightMM,
                           gapMM: gapMM,
                           density: density,
                           invertBitmapBits: invertBitmapBits,
                           elements: elements)
    }

    func applyPreset(_ preset: LabelPreset) {
        guard let size = preset.size else {
            selectedPreset = .custom
            return
        }
        isApplyingPreset = true
        widthMM = size.width
        heightMM = size.height
        gapMM = size.gap
        selectedPreset = preset
        isApplyingPreset = false
        clampAllElements()
    }

    func addText() {
        let frame = clamp(CGRect(x: 24, y: 24, width: min(260, widthDots - 48), height: 42))
        let element = DesignerElement(kind: .text,
                                      frameDots: frame,
                                      text: "New Text",
                                      fontName: "Helvetica Neue",
                                      fontSizeDots: 26,
                                      isBold: false)
        elements.append(element)
        selectedElementID = element.id
        schedulePreviewRender()
    }

    func addImage(_ image: NSImage, name: String?) {
        let maxWidth = min(widthDots * 0.42, 180)
        let maxHeight = min(heightDots * 0.6, 120)
        let frame = clamp(CGRect(x: 24, y: 24, width: max(48, maxWidth), height: max(40, maxHeight)))
        let element = DesignerElement(kind: .image,
                                      frameDots: frame,
                                      text: "",
                                      image: image,
                                      imageName: name)
        elements.append(element)
        selectedElementID = element.id
        schedulePreviewRender()
    }

    func duplicateSelected() {
        guard let selected = selectedElement else { return }
        var duplicate = selected
        let newFrame = clamp(selected.frameDots.offsetBy(dx: 16, dy: 16))
        duplicate = DesignerElement(id: UUID(),
                                    kind: selected.kind,
                                    frameDots: newFrame,
                                    text: selected.text,
                                    fontName: selected.fontName,
                                    fontSizeDots: selected.fontSizeDots,
                                    isBold: selected.isBold,
                                    alignment: selected.alignment,
                                    image: selected.image,
                                    imageName: selected.imageName)
        elements.append(duplicate)
        selectedElementID = duplicate.id
        schedulePreviewRender()
    }

    func deleteSelected() {
        guard let selectedElementID else { return }
        elements.removeAll { $0.id == selectedElementID }
        self.selectedElementID = elements.last?.id
        schedulePreviewRender()
    }

    func select(_ id: UUID?) {
        selectedElementID = id
        schedulePersistenceIfReady()
    }

    func setFrame(for id: UUID, frame: CGRect) {
        updateElement(id: id) { element in
            element.frameDots = frame
        }
    }

    func setText(for id: UUID, text: String) {
        updateElement(id: id) { element in
            element.text = text
        }
    }

    func makePrintData() -> Data {
        printSnapshot().makePrintData()
    }

    var selectedText: String {
        get { selectedElement?.text ?? "" }
        set { updateSelected { $0.text = newValue } }
    }

    var selectedFontName: String {
        get { selectedElement?.fontName ?? "Helvetica Neue" }
        set { updateSelected { $0.fontName = newValue } }
    }

    var selectedFontSize: Double {
        get { Double(selectedElement?.fontSizeDots ?? 24) }
        set { updateSelected { $0.fontSizeDots = CGFloat(clamped(newValue, min: 5, max: 140)) } }
    }

    var selectedIsBold: Bool {
        get { selectedElement?.isBold ?? false }
        set { updateSelected { $0.isBold = newValue } }
    }

    var selectedAlignment: DesignerTextAlignment {
        get { selectedElement?.alignment ?? .left }
        set { updateSelected { $0.alignment = newValue } }
    }

    var selectedX: Double {
        get { Double(selectedElement?.frameDots.origin.x ?? 0) }
        set { updateSelected { $0.frameDots.origin.x = CGFloat(newValue) } }
    }

    var selectedY: Double {
        get { Double(selectedElement?.frameDots.origin.y ?? 0) }
        set { updateSelected { $0.frameDots.origin.y = CGFloat(newValue) } }
    }

    var selectedW: Double {
        get { Double(selectedElement?.frameDots.width ?? 0) }
        set { updateSelected { $0.frameDots.size.width = CGFloat(newValue) } }
    }

    var selectedH: Double {
        get { Double(selectedElement?.frameDots.height ?? 0) }
        set { updateSelected { $0.frameDots.size.height = CGFloat(newValue) } }
    }

    private func updateSelected(_ change: (inout DesignerElement) -> Void) {
        guard let selectedElementID else { return }
        updateElement(id: selectedElementID, change)
    }

    private func updateElement(id: UUID, _ change: (inout DesignerElement) -> Void) {
        guard let index = elements.firstIndex(where: { $0.id == id }) else { return }
        var updated = elements[index]
        change(&updated)
        updated.frameDots = clamp(updated.frameDots)
        var nextElements = elements
        nextElements[index] = updated
        elements = nextElements
        schedulePreviewRender()
    }

    private func schedulePreviewRender(immediate: Bool = false) {
        schedulePersistenceIfReady()
        previewRenderTask?.cancel()
        isRenderingBitmapPreview = true

        let width = widthMM
        let height = heightMM
        let snapshotElements = elements
        let delay: UInt64 = immediate ? 0 : 2_000_000_000

        previewRenderTask = Task { [width, height, snapshotElements, delay] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            if Task.isCancelled { return }

            let result = await Task.detached(priority: .utility) {
                LabelPreviewResult(image: TSPLRasterBuilder.previewImage(widthMM: width,
                                                                         heightMM: height,
                                                                         elements: snapshotElements))
            }.value

            if Task.isCancelled { return }
            bitmapPreviewImage = result.image
            isRenderingBitmapPreview = false
        }
    }

    private func mediaValueChanged() {
        guard !isNormalizingMedia else { return }
        isNormalizingMedia = true
        widthMM = clamped(widthMM, min: 10, max: 120)
        heightMM = clamped(heightMM, min: 8, max: 200)
        isNormalizingMedia = false

        guard !isRestoringState else { return }

        if !isApplyingPreset {
            if selectedPreset.size == nil {
                selectedPreset = .custom
            } else if let size = selectedPreset.size,
                      abs(size.width - widthMM) > 0.001 || abs(size.height - heightMM) > 0.001 {
                selectedPreset = .custom
            }
        }
        clampAllElements()
    }

    private func clampAllElements() {
        elements = elements.map { element in
            var next = element
            next.frameDots = clamp(next.frameDots)
            return next
        }
        schedulePreviewRender()
    }

    private func schedulePersistenceIfReady() {
        guard !isRestoringState else { return }
        persistenceTask?.cancel()
        persistenceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            self?.persistNow()
        }
    }

    private func persistNow() {
        let state = PersistedDesignerState(store: self)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.persistenceKey)
        }
    }

    private func restorePersistedState() -> Bool {
        let defaults = UserDefaults.standard
        let currentData = defaults.data(forKey: Self.persistenceKey).map { (data: $0, isLegacy: false) }
        let legacyData = Self.legacyPersistenceKeys.compactMap { key in
            defaults.data(forKey: key).map { (data: $0, isLegacy: true) }
        }.first
        guard let storedData = currentData ?? legacyData,
              let state = try? JSONDecoder().decode(PersistedDesignerState.self, from: storedData.data) else {
            return false
        }

        isRestoringState = true
        widthMM = clamped(state.widthMM, min: 10, max: 120)
        heightMM = clamped(state.heightMM, min: 8, max: 200)
        gapMM = clamped(state.gapMM, min: 0, max: 20)
        density = Int(clamped(Double(state.density), min: 0, max: 15))
        invertBitmapBits = storedData.isLegacy ? Self.defaultInvertBitmapBits : state.invertBitmapBits
        showGrid = state.showGrid
        elements = state.elements.map { $0.designerElement() }.map { element in
            var next = element
            next.frameDots = clamp(next.frameDots)
            return next
        }
        if elements.isEmpty {
            elements = Self.defaultElements()
        }
        if let selectedElementID = state.selectedElementID,
           elements.contains(where: { $0.id == selectedElementID }) {
            self.selectedElementID = selectedElementID
        } else {
            selectedElementID = elements.first?.id
        }
        selectedPreset = state.selectedPreset
        isRestoringState = false
        persistNow()
        return true
    }

    private static func defaultElements() -> [DesignerElement] {
        [
            DesignerElement(kind: .text,
                            frameDots: CGRect(x: 24, y: 22, width: 240, height: 46),
                            text: "OJO Label",
                            fontName: "Helvetica Neue",
                            fontSizeDots: 30,
                            isBold: true),
            DesignerElement(kind: .text,
                            frameDots: CGRect(x: 24, y: 76, width: 260, height: 32),
                            text: "Drag me or edit in Inspector",
                            fontName: "Helvetica Neue",
                            fontSizeDots: 18)
        ]
    }

    private static func imageData(from image: NSImage?) -> Data? {
        guard let image else { return nil }
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            return png
        }
        return image.tiffRepresentation
    }

    private struct PersistedDesignerState: Codable {
        let selectedPreset: LabelPreset
        let widthMM: Double
        let heightMM: Double
        let gapMM: Double
        let density: Int
        let invertBitmapBits: Bool
        let showGrid: Bool
        let selectedElementID: UUID?
        let elements: [PersistedElement]

        @MainActor
        init(store: LabelDesignerStore) {
            selectedPreset = store.selectedPreset
            widthMM = store.widthMM
            heightMM = store.heightMM
            gapMM = store.gapMM
            density = store.density
            invertBitmapBits = store.invertBitmapBits
            showGrid = store.showGrid
            selectedElementID = store.selectedElementID
            elements = store.elements.map { PersistedElement($0) }
        }
    }

    private struct PersistedElement: Codable {
        let id: UUID
        let kind: DesignerElementKind
        let frame: PersistedRect
        let text: String
        let fontName: String
        let fontSizeDots: Double
        let isBold: Bool
        let alignment: DesignerTextAlignment
        let imageData: Data?
        let imageName: String?

        @MainActor
        init(_ element: DesignerElement) {
            id = element.id
            kind = element.kind
            frame = PersistedRect(element.frameDots)
            text = element.text
            fontName = element.fontName
            fontSizeDots = Double(element.fontSizeDots)
            isBold = element.isBold
            alignment = element.alignment
            imageData = LabelDesignerStore.imageData(from: element.image)
            imageName = element.imageName
        }

        func designerElement() -> DesignerElement {
            DesignerElement(id: id,
                            kind: kind,
                            frameDots: frame.cgRect,
                            text: text,
                            fontName: fontName,
                            fontSizeDots: CGFloat(fontSizeDots),
                            isBold: isBold,
                            alignment: alignment,
                            image: imageData.flatMap { NSImage(data: $0) },
                            imageName: imageName)
        }
    }

    private struct PersistedRect: Codable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double

        init(_ rect: CGRect) {
            x = Double(rect.origin.x)
            y = Double(rect.origin.y)
            width = Double(rect.width)
            height = Double(rect.height)
        }

        var cgRect: CGRect {
            CGRect(x: x, y: y, width: width, height: height)
        }
    }

    private func clamp(_ frame: CGRect) -> CGRect {
        var rect = frame.standardized
        rect.size.width = max(4, min(rect.width, widthDots))
        rect.size.height = max(4, min(rect.height, heightDots))
        rect.origin.x = max(0, min(rect.origin.x, widthDots - rect.width))
        rect.origin.y = max(0, min(rect.origin.y, heightDots - rect.height))
        return rect.integral
    }

    private func clamped(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value.isFinite ? value : minValue))
    }
}
