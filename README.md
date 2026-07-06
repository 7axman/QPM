# QPM (qBittorrent ProtonVPN Manager)

QPM is a background daemon designed specifically for macOS that permanently fixes two major annoyances when torrenting over ProtonVPN with qBittorrent:

1. **Automatic Port Forwarding Sync:** ProtonVPN dynamically changes your assigned port. This script automatically asks ProtonVPN for your new port every time you connect, logs into qBittorrent, and updates your `listen_port` silently.
2. **Automatic Network Interface Binding (`utun` fix):** macOS dynamically reassigns the `utunX` interface number (e.g., `utun4` becomes `utun5`) when VPNs reconnect. To prevent IP leaks, you should bind qBittorrent to the specific VPN interface. QPM automatically scans your network to locate ProtonVPN's active interface (by finding the `10.2.x.x` IP) and instantly updates qBittorrent's Network Interface setting to perfectly match it.

## Key Features
* **Zero Configuration After Setup:** Simply run the installer and the background macOS `LaunchAgent` will start automatically every time you log in.
* **Modern Cookie Support:** Fully supports newer qBittorrent versions that use `QBT_SID_XXXX` cookies instead of the legacy `SID` cookie.
* **Strict Interface Matching:** Prevents traffic leaks by never accidentally reverting to "Any interface" and by ignoring non-ProtonVPN `utun` interfaces (like iCloud Private Relay).
* **Safe Installation:** Installs entirely inside an isolated Python Virtual Environment without touching system python or homebrew packages globally.

## Prerequisites
* **qBittorrent WebUI Enabled:** Open qBittorrent -> Preferences -> WebUI. Check "Web User Interface (Remote control)" and set a port, username, and password. 
* **ProtonVPN via WireGuard:** You must be using the WireGuard protocol (either through the official ProtonVPN app or the official WireGuard app) connected to a P2P port-forwarding server.

## Installation
1. Download `QPM_Installer.command`
2. Open Terminal and make it executable: `chmod +x QPM_Installer.command`
3. Double click the file to run the installer.
4. Input your qBittorrent WebUI credentials when prompted.

## Uninstallation
Simply double-click `QPM_Installer.command` again and select the **Uninstall** option. It will cleanly remove the LaunchAgent and the script directory.

## License & Credits
QPM is a fork of the excellent [proton-port-sync](https://github.com/deecypher/proton-port-sync) by deecypher. 
The original project was published under the **MIT License**, meaning you are free to share, modify, and distribute it. 

### MIT License
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software...
