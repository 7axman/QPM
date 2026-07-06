# QPM (qBittorrent ProtonVPN Monitor)

QPM is a blazing fast, 100% native macOS Menu Bar application that perfectly automates ProtonVPN port forwarding for qBittorrent.

When you use ProtonVPN for P2P, they dynamically change your port forwarding number. Instead of manually typing this into qBittorrent every time you connect, QPM runs completely in the background, requests the new port natively using NAT-PMP, and securely pushes it directly to your qBittorrent WebUI. 

## ✨ Key Features
- **100% Native Swift**: No Python scripts, no virtual environments, no terminal commands.
- **macOS Menu Bar UI**: A beautiful, minimalist menu bar popover to check status and force syncs.
- **Automatic Interface Binding**: Scans `ifconfig` automatically to bind qBittorrent strictly to the active VPN interface (e.g. `utun4`) to prevent IP leaks.
- **Instantly Reactive**: Checks your connection gracefully and syncs in milliseconds if you change servers.

## 📦 Installation

Install QPM securely using Homebrew to bypass Apple's developer warnings automatically:

```bash
brew install 7axman/qpm/qpm
```

## ⚙️ Prerequisites (qBittorrent Setup)

Before launching QPM, you must enable the qBittorrent WebUI so QPM has a way to inject the new port.

1. Open **qBittorrent** and go to **Preferences > WebUI**.
2. Check the box for **"Web User Interface (Remote control)"**.
3. Under the Authentication section, set a **Username** and **Password**.
4. Remember the **Port** listed at the top (usually `8080`).
5. Open **QPM** from your Applications folder, click the Menu Bar icon, and type those exact credentials into the UI!

## 🗑️ Uninstallation

If you ever want to remove QPM:
```bash
brew uninstall qpm
```

## License
Released under the MIT License. Forked with ❤️ from [proton-port-sync](https://github.com/deecypher/proton-port-sync).
