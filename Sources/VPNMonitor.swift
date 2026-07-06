import Foundation
import SwiftUI
import Network

enum VPNState {
    case disconnected
    case syncing
    case synced
}

class VPNMonitor: ObservableObject {
    @Published var state: VPNState = .disconnected
    @Published var vpnInterface: String = "None"
    @Published var activePort: Int? = nil
    
    @Published var qbtUsername: String {
        didSet { UserDefaults.standard.set(qbtUsername, forKey: "qbtUsername") }
    }
    @Published var qbtPassword: String {
        didSet { UserDefaults.standard.set(qbtPassword, forKey: "qbtPassword") }
    }
    @Published var qbtPort: String {
        didSet { UserDefaults.standard.set(qbtPort, forKey: "qbtPort") }
    }
    
    var iconName: String {
        switch state {
        case .disconnected: return "shield.slash"
        case .syncing: return "arrow.triangle.2.circlepath.shield"
        case .synced: return "checkmark.shield.fill"
        }
    }
    
    var statusText: String {
        switch state {
        case .disconnected: return "Disconnected"
        case .syncing: return "Syncing..."
        case .synced: return "Synced & Safe"
        }
    }
    
    var statusColor: Color {
        switch state {
        case .disconnected: return .red
        case .syncing: return .yellow
        case .synced: return .green
        }
    }
    
    private var timer: Timer?
    private var lastSyncedPort: Int? = nil
    private var lastSyncedIface: String? = nil
    
    init() {
        self.qbtUsername = UserDefaults.standard.string(forKey: "qbtUsername") ?? ""
        self.qbtPassword = UserDefaults.standard.string(forKey: "qbtPassword") ?? ""
        self.qbtPort = UserDefaults.standard.string(forKey: "qbtPort") ?? "8080"
        startMonitoring()
    }
    
    func startMonitoring() {
        // Run immediately, then every 10 seconds
        runSyncCycle()
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.runSyncCycle()
        }
    }
    
    func forceSync() {
        lastSyncedPort = nil // Force it to update
        runSyncCycle()
    }
    
    private func runSyncCycle() {
        DispatchQueue.global(qos: .background).async {
            let iface = self.getVPNInterface()
            
            DispatchQueue.main.async {
                self.vpnInterface = iface ?? "None"
                if iface == nil {
                    self.state = .disconnected
                    self.activePort = nil
                    self.lastSyncedPort = nil
                    self.lastSyncedIface = nil
                }
            }
            
            guard let validIface = iface else { return }
            
            // Request NAT-PMP Port
            self.getNATPort(gateway: "10.2.0.1") { port in
                guard let port = port else { return }
                
                DispatchQueue.main.async {
                    self.activePort = port
                }
                
                if port != self.lastSyncedPort || validIface != self.lastSyncedIface {
                    DispatchQueue.main.async { self.state = .syncing }
                    
                    self.updateQbittorrent(port: port, interface: validIface) { success in
                        if success {
                            self.lastSyncedPort = port
                            self.lastSyncedIface = validIface
                            DispatchQueue.main.async { self.state = .synced }
                        } else {
                            DispatchQueue.main.async { self.state = .disconnected }
                        }
                    }
                }
            }
        }
    }
    
    // Natively execute ifconfig
    private func getVPNInterface() -> String? {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/sbin/ifconfig"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }
        
        var currentIface: String?
        for line in output.components(separatedBy: .newlines) {
            if line.starts(with: "utun") {
                currentIface = line.components(separatedBy: ":").first
            }
            if line.contains("inet 10.2.") {
                return currentIface
            }
        }
        return nil
    }
    
    // Pure Swift UDP NAT-PMP Implementation
    private func getNATPort(gateway: String, completion: @escaping (Int?) -> Void) {
        let host = NWEndpoint.Host(gateway)
        let port = NWEndpoint.Port(integerLiteral: 5351)
        let connection = NWConnection(host: host, port: port, using: .udp)
        
        var completed = false
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let packet: [UInt8] = [0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60] // TCP Mapping, 60s lifetime
                connection.send(content: Data(packet), completion: .contentProcessed({ error in
                    if error != nil {
                        if !completed { completed = true; connection.cancel(); completion(nil) }
                        return
                    }
                    connection.receiveMessage { (data, context, isComplete, error) in
                        if let data = data, data.count >= 16 {
                            let result = (UInt16(data[2]) << 8) | UInt16(data[3])
                            if result == 0 {
                                let extPort = (UInt16(data[10]) << 8) | UInt16(data[11])
                                if !completed { completed = true; connection.cancel(); completion(Int(extPort)) }
                                return
                            }
                        }
                        if !completed { completed = true; connection.cancel(); completion(nil) }
                    }
                }))
            case .failed(_), .cancelled:
                if !completed { completed = true; completion(nil) }
            default:
                break
            }
        }
        connection.start(queue: .global())
        
        // Timeout
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            if !completed { completed = true; connection.cancel(); completion(nil) }
        }
    }
    
    // Native URLSession qBittorrent API
    private func updateQbittorrent(port: Int, interface: String, completion: @escaping (Bool) -> Void) {
        let session = URLSession.shared
        let targetPort = self.qbtPort.isEmpty ? "8080" : self.qbtPort
        let loginUrl = URL(string: "http://localhost:\(targetPort)/api/v2/auth/login")!
        var loginReq = URLRequest(url: loginUrl)
        loginReq.httpMethod = "POST"
        loginReq.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let username = self.qbtUsername.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let password = self.qbtPassword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        loginReq.httpBody = "username=\(username)&password=\(password)".data(using: .utf8)
        
        session.dataTask(with: loginReq) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(false)
                return
            }
            
            let targetPort = self.qbtPort.isEmpty ? "8080" : self.qbtPort
            let prefsUrl = URL(string: "http://localhost:\(targetPort)/api/v2/app/setPreferences")!
            var prefsReq = URLRequest(url: prefsUrl)
            prefsReq.httpMethod = "POST"
            prefsReq.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            let jsonString = "{\"listen_port\":\(port),\"current_network_interface\":\"\(interface)\"}"
            let escapedJson = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            prefsReq.httpBody = "json=\(escapedJson)".data(using: .utf8)
            
            session.dataTask(with: prefsReq) { _, pResp, _ in
                if let pHttpResp = pResp as? HTTPURLResponse, (200...299).contains(pHttpResp.statusCode) {
                    completion(true)
                } else {
                    completion(false)
                }
            }.resume()
            
        }.resume()
    }
    
    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
