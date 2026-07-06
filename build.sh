#!/bin/zsh

echo "Building QPM Native Mac App..."

# Ensure target directories exist
mkdir -p QPM.app/Contents/MacOS
mkdir -p QPM.app/Contents/Resources

# Compile Swift files
swiftc Sources/*.swift -o QPM.app/Contents/MacOS/QPM

# Copy Info.plist
cp Info.plist QPM.app/Contents/Info.plist

echo "Build complete! You can now open QPM.app"
