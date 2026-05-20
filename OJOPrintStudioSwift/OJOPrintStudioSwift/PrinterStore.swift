import Foundation

struct DiscoveredPrinter: Identifiable, Equatable {
    var id: String { ip }
    let ip: String
    let name: String
    let model: String
    let serialNumber: String

    var title: String {
        name.isEmpty ? "SUNMI printer" : name
    }

    var detail: String {
        [ip, model, serialNumber]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

@MainActor
final class PrinterStore: ObservableObject {
    struct SendError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    @Published var ipAddress: String = "192.168.0.117"
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isBusy: Bool = false
    @Published private(set) var isDiscovering: Bool = false
    @Published private(set) var discoveredPrinters: [DiscoveredPrinter] = []
    @Published var statusMessage: String = "Not connected"

    private let bridge = OJOPrinterBridge()

    var sdkVersion: String {
        OJOPrinterBridge.sdkVersion()
    }

    var connectedAddress: String {
        bridge.connectedIPAddress ?? ipAddress
    }

    func discoverPrinters() {
        isDiscovering = true
        statusMessage = "Searching for SUNMI printers on the local network…"

        bridge.discoverPrinters { [weak self] printerDictionaries, errorMessage in
            Task { @MainActor in
                guard let self else { return }
                self.isDiscovering = false

                let printers = printerDictionaries.compactMap { dictionary -> DiscoveredPrinter? in
                    let ip = dictionary["ip"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    guard !ip.isEmpty else { return nil }
                    return DiscoveredPrinter(ip: ip,
                                             name: dictionary["name"] ?? "SUNMI printer",
                                             model: dictionary["model"] ?? "",
                                             serialNumber: dictionary["sn"] ?? "")
                }

                self.discoveredPrinters = printers
                if let first = printers.first {
                    self.ipAddress = first.ip
                    self.statusMessage = "Found \(printers.count) printer\(printers.count == 1 ? "" : "s"). Selected \(first.ip)."
                } else {
                    self.statusMessage = errorMessage ?? "No SUNMI IP printers found. You can still enter the IP manually."
                }
            }
        }
    }

    func selectPrinter(_ printer: DiscoveredPrinter) {
        ipAddress = printer.ip
        statusMessage = "Selected \(printer.title) at \(printer.ip). Press Connect."
    }

    func connect() {
        let trimmed = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Enter the printer IP address."
            return
        }

        isBusy = true
        statusMessage = "Connecting to \(trimmed)…"
        bridge.connect(toIP: trimmed) { [weak self] success, errorMessage in
            Task { @MainActor in
                guard let self else { return }
                self.isBusy = false
                self.isConnected = success
                if success {
                    self.ipAddress = trimmed
                    self.statusMessage = "Connected to \(trimmed) using SUNMI SDK IP manager."
                } else {
                    self.statusMessage = errorMessage ?? "Failed to connect."
                }
            }
        }
    }

    func disconnect() {
        bridge.disconnect()
        isConnected = false
        statusMessage = "Disconnected"
    }

    func send(_ data: Data, completion: @escaping (Result<Void, SendError>) -> Void) {
        guard isConnected else {
            completion(.failure(SendError(message: "Connect to the printer before printing.")))
            return
        }

        bridge.send(data) { [weak self] success, errorMessage in
            Task { @MainActor in
                if !success {
                    self?.isConnected = false
                }
                completion(success ? .success(()) : .failure(SendError(message: errorMessage ?? "Print failed.")))
            }
        }
    }
}
