import SwiftUI

@main
struct QPMApp: App {
    @StateObject private var monitor = VPNMonitor()
    
    var body: some Scene {
        MenuBarExtra("QPM", systemImage: monitor.iconName) {
            ContentView(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}
