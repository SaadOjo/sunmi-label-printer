import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DesignerView: View {
    @EnvironmentObject private var printerStore: PrinterStore
    @EnvironmentObject private var designerStore: LabelDesignerStore
    @State private var printMessage: String = "Ready"
    @State private var isPreparingPrint: Bool = false
    @AppStorage("OJOPrintStudioSwift.Designer.showElementsPanel") private var showElementsPanel: Bool = true

    private let fonts = ["Helvetica Neue", "Arial", "Avenir Next", "Menlo", "Times New Roman"]

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    mediaCard
                    inspectorCard
                    printCard
                }
                .padding(20)
            }
            .frame(width: 342)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Canvas")
                            .font(.title3.weight(.semibold))
                        Text("\(Int(designerStore.widthDots)) × \(Int(designerStore.heightDots)) dots · \(designerStore.widthMM, specifier: "%.1f") × \(designerStore.heightMM, specifier: "%.1f") mm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Click text once to select, click it again to edit, then click/drag inside the editor to place the cursor or select text.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)

                canvasToolbar
                    .padding(.horizontal, 18)

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
                .padding(.bottom, 18)
            }
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }

    private var mediaCard: some View {
        card(title: "Label setup", subtitle: "Changing width or height immediately updates the canvas proportions.") {
            VStack(spacing: 10) {
                Picker("Preset", selection: $designerStore.selectedPreset) {
                    ForEach(LabelPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .onChange(of: designerStore.selectedPreset) { newValue in
                    designerStore.applyPreset(newValue)
                }

                HStack(spacing: 10) {
                    numberField("Width", value: Binding(get: { designerStore.widthMM }, set: { designerStore.widthMM = $0 }), suffix: "mm")
                    numberField("Height", value: Binding(get: { designerStore.heightMM }, set: { designerStore.heightMM = $0 }), suffix: "mm")
                }
                HStack(spacing: 10) {
                    numberField("Gap", value: Binding(get: { designerStore.gapMM }, set: { designerStore.gapMM = $0 }), suffix: "mm")
                    Spacer()
                }
            }
        }
    }

    private var canvasToolbar: some View {
        HStack(spacing: 8) {
            Button {
                designerStore.addText()
            } label: {
                Label("Text", systemImage: "textformat")
            }

            Button {
                addImage()
            } label: {
                Label("Image", systemImage: "photo")
            }

            Divider()
                .frame(height: 22)

            Button {
                designerStore.duplicateSelected()
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            .disabled(designerStore.selectedElement == nil)

            Button {
                designerStore.deleteSelected()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(designerStore.selectedElement == nil)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showElementsPanel.toggle()
                }
            } label: {
                Label("Elements", systemImage: "list.bullet.rectangle")
            }
            .help(showElementsPanel ? "Hide elements panel" : "Show elements panel")

            Toggle("Grid", isOn: $designerStore.showGrid)
                .toggleStyle(.checkbox)
        }
        .controlSize(.small)
        .buttonStyle(.bordered)
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
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
                .help("Hide elements panel")
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
        .help("Select \(elementID(for: element, index: index))")
    }

    private var inspectorCard: some View {
        card(title: "Inspector", subtitle: "Positions and sizes are in printer dots.") {
            if let selected = designerStore.selectedElement {
                VStack(alignment: .leading, spacing: 11) {
                    Text(selected.kind == .text ? "Text element" : "Image element")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    if selected.kind == .text {
                        TextField("Text", text: Binding(get: { designerStore.selectedText }, set: { designerStore.selectedText = $0 }))
                            .textFieldStyle(.roundedBorder)

                        Picker("Font", selection: Binding(get: { designerStore.selectedFontName }, set: { designerStore.selectedFontName = $0 })) {
                            ForEach(fonts, id: \.self) { font in
                                Text(font).tag(font)
                            }
                        }

                        HStack(spacing: 10) {
                            numberField("Font size", value: Binding(get: { designerStore.selectedFontSize }, set: { designerStore.selectedFontSize = $0 }), suffix: "dot")
                            Toggle("Bold", isOn: Binding(get: { designerStore.selectedIsBold }, set: { designerStore.selectedIsBold = $0 }))
                                .toggleStyle(.checkbox)
                                .frame(width: 80)
                        }

                        Picker("Align", selection: Binding(get: { designerStore.selectedAlignment }, set: { designerStore.selectedAlignment = $0 })) {
                            ForEach(DesignerTextAlignment.allCases) { alignment in
                                Text(alignment.rawValue).tag(alignment)
                            }
                        }
                        .pickerStyle(.segmented)
                    } else {
                        Text(selected.imageName ?? "Imported image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 10) {
                        numberField("X", value: Binding(get: { designerStore.selectedX }, set: { designerStore.selectedX = $0 }), suffix: "")
                        numberField("Y", value: Binding(get: { designerStore.selectedY }, set: { designerStore.selectedY = $0 }), suffix: "")
                    }
                    HStack(spacing: 10) {
                        numberField("W", value: Binding(get: { designerStore.selectedW }, set: { designerStore.selectedW = $0 }), suffix: "")
                        numberField("H", value: Binding(get: { designerStore.selectedH }, set: { designerStore.selectedH = $0 }), suffix: "")
                    }
                }
            } else {
                Text("Select an element on the canvas.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var printCard: some View {
        card(title: "Print", subtitle: "Preview and send the current design to the connected printer.") {
            VStack(alignment: .leading, spacing: 10) {
                bitmapPreview

                Button {
                    printLabel()
                } label: {
                    Label(isPreparingPrint ? "Preparing…" : "Print Label", systemImage: "printer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!printerStore.isConnected || isPreparingPrint)

                Text(printMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
    }

    private var bitmapPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("1-bit bitmap preview")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
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
                        Text("Preview refreshes after editing pauses.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 82, maxHeight: 150)
            .padding(8)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
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

    private func numberField(_ title: String, value: Binding<Double>, suffix: String) -> some View {
        DeferredNumberField(title: title, value: value, suffix: suffix)
    }

    private func card<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DeferredNumberField: View {
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
