import SwiftUI

struct ContentView: View {
    @ObservedObject var monitor: VPNMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Circle()
                    .fill(monitor.statusColor)
                    .frame(width: 10, height: 10)
                Text("Status: \(monitor.statusText)")
                    .font(.headline)
            }
            
            // Connection Info
            VStack(alignment: .leading, spacing: 4) {
                Text("VPN Interface: \(monitor.vpnInterface)")
                Text("Assigned Port: \(monitor.activePort.map(String.init) ?? "None")")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Divider()
            
            // Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("qBittorrent Settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Port:")
                        .font(.subheadline)
                    TextField("8080", text: $monitor.qbtPort)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                }
                
                TextField("Username", text: $monitor.qbtUsername)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $monitor.qbtPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Actions
            HStack {
                Button(action: { monitor.forceSync() }) {
                    Label("Force Sync", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: { monitor.quit() }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 250)
    }
}
