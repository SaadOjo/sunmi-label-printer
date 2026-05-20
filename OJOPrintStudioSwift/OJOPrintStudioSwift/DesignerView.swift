import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DesignerView: View {
    @EnvironmentObject private var printerStore: PrinterStore
    @EnvironmentObject private var designerStore: LabelDesignerStore
    @State private var printMessage: String = "Ready"
    @State private var isPreparingPrint: Bool = false
    @AppStorage("OJOPrintStudioSwift.Designer.showElementsPanel") private var showElementsPanel: Bool = true
    @AppStorage("OJOPrintStudioSwift.Designer.showBitmapPanel") private var showBitmapPanel: Bool = false

    private let fonts = ["Helvetica Neue", "Arial", "Avenir Next", "Menlo", "Times New Roman"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            canvasToolbar
                .padding(.horizontal, 18)
                .padding(.top, 18)

            HStack(spacing: 12) {
                LabelCanvasView(store: designerStore)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showElementsPanel {
                    canvasElementsPanel
                        .frame(width: 118)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)

            if showBitmapPanel {
                bitmapPanel
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Spacer(minLength: 0)
                    .frame(height: 6)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var canvasToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                toolbarButton("textformat", help: "Add text") {
                    designerStore.addText()
                }

                toolbarButton("photo", help: "Add image") {
                    addImage()
                }

                Divider()
                    .frame(height: 22)

                toolbarButton("plus.square.on.square", help: "Duplicate") {
                    designerStore.duplicateSelected()
                }
                .disabled(designerStore.selectedElement == nil)

                toolbarButton("trash", help: "Delete") {
                    designerStore.deleteSelected()
                }
                .disabled(designerStore.selectedElement == nil)

                selectedElementControls

                Divider()
                    .frame(height: 22)

                toolbarButton("printer", help: "Print") {
                    printLabel()
                }
                .disabled(!printerStore.isConnected || isPreparingPrint)

                toolbarButton(showBitmapPanel ? "rectangle.3.group.fill" : "rectangle.3.group", help: "Bitmap preview") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showBitmapPanel.toggle()
                    }
                }

                toolbarButton(showElementsPanel ? "sidebar.right" : "sidebar.right", help: "Elements") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showElementsPanel.toggle()
                    }
                }

                toolbarButton(designerStore.showGrid ? "grid.circle.fill" : "grid.circle", help: "Grid") {
                    designerStore.showGrid.toggle()
                }
            }
            .controlSize(.small)
            .buttonStyle(.bordered)
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private func toolbarButton(_ systemImage: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 18, height: 16)
        }
        .help(help)
    }

    @ViewBuilder
    private var selectedElementControls: some View {
        if let selected = designerStore.selectedElement {
            Divider()
                .frame(height: 22)

            if selected.kind == .text {
                Picker("Font", selection: Binding(get: { designerStore.selectedFontName }, set: { designerStore.selectedFontName = $0 })) {
                    ForEach(fonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .labelsHidden()
                .frame(width: 126)

                CompactNumberField("Size", value: Binding(get: { designerStore.selectedFontSize }, set: { designerStore.selectedFontSize = $0 }), width: 42)

                Button {
                    designerStore.selectedIsBold = !designerStore.selectedIsBold
                } label: {
                    Text("B")
                        .fontWeight(.bold)
                        .frame(width: 16)
                }

                Picker("Align", selection: Binding(get: { designerStore.selectedAlignment }, set: { designerStore.selectedAlignment = $0 })) {
                    ForEach(DesignerTextAlignment.allCases) { alignment in
                        Text(alignment.rawValue.prefix(1)).tag(alignment)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 92)
            }

            CompactNumberField("W", value: Binding(get: { designerStore.selectedW }, set: { designerStore.selectedW = $0 }), width: 42)
            CompactNumberField("H", value: Binding(get: { designerStore.selectedH }, set: { designerStore.selectedH = $0 }), width: 42)
        }
    }

    private var canvasElementsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Elements")
                    .font(.caption.weight(.semibold))
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showElementsPanel = false
                    }
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            if designerStore.elements.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(Array(designerStore.elements.enumerated()).reversed(), id: \.element.id) { index, element in
                            elementPanelRow(element: element, index: index)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private func elementPanelRow(element: DesignerElement, index: Int) -> some View {
        let selected = designerStore.selectedElementID == element.id
        return Button {
            designerStore.select(element.id)
        } label: {
            HStack(spacing: 7) {
                Circle()
                    .fill(selected ? Color.accentColor : Color.clear)
                    .frame(width: 6, height: 6)
                Image(systemName: element.kind == .text ? "textformat" : "photo")
                    .foregroundColor(.secondary)
                    .frame(width: 14)
                Text(elementID(for: element, index: index))
                    .font(.system(size: 12, weight: selected ? .semibold : .regular, design: .monospaced))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.accentColor.opacity(0.16) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bitmapPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bitmap preview")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(printMessage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showBitmapPanel = false
                    }
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            bitmapPreview
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 132, maxHeight: 176)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    private var bitmapPreview: some View {
        ZStack {
            if let image = designerStore.bitmapPreviewImage {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .blur(radius: designerStore.isRenderingBitmapPreview ? 4 : 0)
                    .opacity(designerStore.isRenderingBitmapPreview ? 0.28 : 1)
            } else {
                Text("Preparing preview…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if designerStore.isRenderingBitmapPreview {
                Color.white.opacity(0.76)
                VStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Buffering bitmap preview…")
                        .font(.caption.weight(.semibold))
                }
                .padding(10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 88, maxHeight: 126)
        .padding(8)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.black.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func elementID(for element: DesignerElement, index: Int) -> String {
        let prefix = element.kind == .text ? "T" : "I"
        return "\(prefix)-\(String(format: "%03d", index + 1))"
    }

    private func addImage() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .gif, .tiff, .bmp]
        if panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
            designerStore.addImage(image, name: url.lastPathComponent)
        }
    }

    private func printLabel() {
        let snapshot = designerStore.printSnapshot()
        isPreparingPrint = true
        printMessage = "Preparing bitmap…"

        Task {
            let data = await Task.detached(priority: .userInitiated) {
                snapshot.makePrintData()
            }.value

            await MainActor.run {
                printMessage = "Sending \(data.count) bytes…"
                printerStore.send(data) { result in
                    isPreparingPrint = false
                    switch result {
                    case .success:
                        printMessage = "Label sent."
                    case .failure(let error):
                        printMessage = error.localizedDescription
                    }
                }
            }
        }
    }
}

struct CompactNumberField: View {
    let title: String
    @Binding var value: Double
    let width: CGFloat

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    init(_ title: String, value: Binding<Double>, width: CGFloat = 52) {
        self.title = title
        self._value = value
        self.width = width
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            TextField(title, text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .frame(width: width)
                .onSubmit {
                    commit()
                    isFocused = false
                }
        }
        .onAppear { text = formatted(value) }
        .onChange(of: value) { newValue in
            if !isFocused { text = formatted(newValue) }
        }
        .onChange(of: isFocused) { focused in
            if focused {
                text = formatted(value)
            } else {
                commit()
            }
        }
        .onDisappear { commit() }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            text = formatted(value)
            return
        }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let parsed = Double(normalized), parsed.isFinite else {
            text = formatted(value)
            return
        }
        value = parsed
        text = formatted(value)
    }

    private func formatted(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.001 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

struct DeferredNumberField: View {
    let title: String
    @Binding var value: Double
    let suffix: String

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                TextField(title, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit {
                        commit()
                        isFocused = false
                    }
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            text = formatted(value)
        }
        .onChange(of: value) { newValue in
            if !isFocused {
                text = formatted(newValue)
            }
        }
        .onChange(of: isFocused) { focused in
            if focused {
                text = formatted(value)
            } else {
                commit()
            }
        }
        .onDisappear {
            commit()
        }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            text = formatted(value)
            return
        }

        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let parsed = Double(normalized), parsed.isFinite else {
            text = formatted(value)
            return
        }

        value = parsed
        text = formatted(value)
    }

    private func formatted(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.001 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
