#!/bin/bash
set -e

echo "=== Publishing QPM to GitHub Releases ==="
gh release create v1.0.0 QPM-v1.0.0.zip --title "v1.0.0: Native macOS Release" --notes "100% Native Swift App" || echo "Release might already exist"

echo "=== Creating Homebrew Tap ==="
gh repo create homebrew-qpm --public --description "Homebrew Tap for QPM" || true
rm -rf /tmp/homebrew-qpm
mkdir -p /tmp/homebrew-qpm
cd /tmp/homebrew-qpm
git init
mkdir Casks

cat << 'EOF' > Casks/qpm.rb
cask "qpm" do
  version "1.0.0"
  sha256 "400d79d3ca709ea4d29d87404cc2fe8e9d215284f45f8d98d9a233d1821fa3f5"

  url "https://github.com/7axman/QPM/releases/download/v#{version}/QPM-v#{version}.zip"
  name "QPM"
  desc "ProtonVPN Port Sync for qBittorrent"
  homepage "https://github.com/7axman/QPM"

  app "QPM.app"
end
EOF

git add .
git commit -m "Initial release of QPM Cask"
git branch -M main
git remote add origin https://github.com/7axman/homebrew-qpm.git
git push -f -u origin main

echo "=== SUCCESS! ==="
echo "Users can now install using:"
echo "brew install 7axman/qpm/qpm"
