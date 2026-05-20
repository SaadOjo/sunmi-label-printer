import SwiftUI

enum OJOSection: String, CaseIterable, Identifiable {
    case connect = "Connect"
    case designer = "Designer"
    case settings = "Settings"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .connect: return "wifi"
        case .designer: return "rectangle.and.pencil.and.ellipsis"
        case .settings: return "gearshape"
        }
    }

    var subtitle: String {
        switch self {
        case .connect:
            return "Connect to a SUNMI printer using the SDK"
        case .designer:
            return "Design and print dot-accurate labels"
        case .settings:
            return "Printer output defaults and advanced options"
        }
    }
}

struct ContentView: View {
    @State private var selectedSection: OJOSection = .connect
    @EnvironmentObject private var printerStore: PrinterStore

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 238)
                .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 18)

                Divider()

                Group {
                    switch selectedSection {
                    case .connect:
                        ConnectView()
                    case .designer:
                        DesignerView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("OJO")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text("Print Studio")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 28)
            .padding(.horizontal, 20)

            VStack(spacing: 8) {
                ForEach(OJOSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: section.icon)
                                .frame(width: 22)
                            Text(section.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(selectedSection == section ? Color.accentColor.opacity(0.16) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(printerStore.isConnected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(printerStore.isConnected ? "Connected" : "Offline")
                        .font(.caption.weight(.semibold))
                }
                Text(printerStore.isConnected ? printerStore.connectedAddress : "No printer connected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(selectedSection.rawValue)
                .font(.system(size: 28, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var designerStore: LabelDesignerStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                card(title: "Label setup") {
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
                            DeferredNumberField(title: "Width", value: Binding(get: { designerStore.widthMM }, set: { designerStore.widthMM = $0 }), suffix: "mm")
                            DeferredNumberField(title: "Height", value: Binding(get: { designerStore.heightMM }, set: { designerStore.heightMM = $0 }), suffix: "mm")
                        }

                        HStack(spacing: 10) {
                            DeferredNumberField(title: "Gap", value: Binding(get: { designerStore.gapMM }, set: { designerStore.gapMM = $0 }), suffix: "mm")
                            Spacer()
                        }
                    }
                }

                card(title: "Output") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Density")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                            Stepper(value: $designerStore.density, in: 0...15) {
                                Text("\(designerStore.density)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        Toggle("SUNMI bitmap polarity", isOn: $designerStore.invertBitmapBits)
                            .toggleStyle(.checkbox)
                    }
                }

                card(title: "TSPL") {
                    Text(designerStore.summary)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding(24)
            .frame(maxWidth: 560, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
