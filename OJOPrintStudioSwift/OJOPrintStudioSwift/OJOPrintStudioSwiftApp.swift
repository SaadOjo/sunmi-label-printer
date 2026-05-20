import SwiftUI

@main
struct OJOPrintStudioSwiftApp: App {
    @StateObject private var printerStore = PrinterStore()
    @StateObject private var designerStore = LabelDesignerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(printerStore)
                .environmentObject(designerStore)
                .frame(minWidth: 1100, minHeight: 720)
        }
        .windowStyle(.titleBar)
    }
}
