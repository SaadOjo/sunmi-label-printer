import SwiftUI

struct ConnectView: View {
    @EnvironmentObject private var printerStore: PrinterStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                card {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SUNMI SDK connection")
                                .font(.title3.weight(.semibold))
                            Text("This new SwiftUI app talks to the existing Objective-C SUNMI framework through a small bridge. For now, connect over LAN/IP.")
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .bottom, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Printer IP address")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    TextField("192.168.0.117", text: $printerStore.ipAddress)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 240)
                                }

                                Button {
                                    printerStore.discoverPrinters()
                                } label: {
                                    if printerStore.isDiscovering {
                                        HStack(spacing: 6) {
                                            ProgressView().controlSize(.small)
                                            Text("Searching")
                                        }
                                    } else {
                                        Label("Discover", systemImage: "magnifyingglass")
                                    }
                                }
                                .disabled(printerStore.isDiscovering || printerStore.isBusy)

                                Button {
                                    printerStore.connect()
                                } label: {
                                    if printerStore.isBusy {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Text("Connect")
                                    }
                                }
                                .keyboardShortcut(.defaultAction)
                                .disabled(printerStore.isBusy || printerStore.isDiscovering)

                                Button("Disconnect") {
                                    printerStore.disconnect()
                                }
                                .disabled(!printerStore.isConnected)
                            }

                            if !printerStore.discoveredPrinters.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Discovered printers")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)
                                    ForEach(printerStore.discoveredPrinters) { printer in
                                        Button {
                                            printerStore.selectPrinter(printer)
                                        } label: {
                                            HStack(spacing: 10) {
                                                Image(systemName: printer.ip == printerStore.ipAddress ? "checkmark.circle.fill" : "printer")
                                                    .foregroundColor(printer.ip == printerStore.ipAddress ? .accentColor : .secondary)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(printer.title)
                                                        .font(.system(size: 13, weight: .semibold))
                                                    Text(printer.detail)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                            }
                                            .padding(10)
                                            .background(printer.ip == printerStore.ipAddress ? Color.accentColor.opacity(0.10) : Color(nsColor: .controlBackgroundColor))
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        Divider()

                        HStack(spacing: 10) {
                            Circle()
                                .fill(printerStore.isConnected ? Color.green : Color.gray)
                                .frame(width: 10, height: 10)
                            Text(printerStore.statusMessage)
                                .foregroundColor(printerStore.isConnected ? .primary : .secondary)
                        }
                    }
                }

                card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bridge details")
                            .font(.title3.weight(.semibold))
                        detailRow("SDK", "SunmiPrinterMacOS.framework")
                        detailRow("SDK version", printerStore.sdkVersion)
                        detailRow("Swift bridge", "OJOPrinterBridge.h/.m")
                        detailRow("Current transport", "SUNMI SDK IP manager")
                        detailRow("Label output", "Swift raster renderer → TSPL BITMAP")
                    }
                }

                card {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Important")
                            .font(.title3.weight(.semibold))
                        Text("Designer printing sends TSPL label commands. Make sure the printer is in label mode and the physical label size/gap matches the settings in Designer.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
            Spacer()
        }
        .font(.system(size: 13))
    }
}
