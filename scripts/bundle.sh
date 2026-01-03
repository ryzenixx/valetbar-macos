#!/bin/bash
set -e

echo "📦 Bundling Application..."

# Cleanup
rm -rf .build
rm -rf ValetBar.app

# Build
swift build -c release --arch arm64

# Define Paths
EXECUTABLE_PATH=".build/arm64-apple-macosx/release/ValetBar"
BUNDLE_PATH="./ValetBar.app"
CONTENTS_PATH="$BUNDLE_PATH/Contents"
RESOURCES_PATH="$CONTENTS_PATH/Resources"
MACOS_PATH="$CONTENTS_PATH/MacOS"
FRAMEWORKS_PATH="$CONTENTS_PATH/Frameworks"

# Create Bundle Structure
mkdir -p "$MACOS_PATH"
mkdir -p "$RESOURCES_PATH"
mkdir -p "$FRAMEWORKS_PATH"

# Install Executable
cp "$EXECUTABLE_PATH" "$MACOS_PATH/"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$MACOS_PATH/ValetBar"

# Install Resources
cp "Sources/Assets/MenuBarIcon.png" "$RESOURCES_PATH/"
cp "Sources/Assets/AppIcon.icns" "$RESOURCES_PATH/"

# Install Sparkle Framework
find .build -name "Sparkle.framework" -exec cp -R {} "$FRAMEWORKS_PATH/" \;
if [ ! -d "$FRAMEWORKS_PATH/Sparkle.framework" ]; then
    echo "❌ CRITICAL ERROR: Sparkle.framework not found"
    exit 1
fi

# Generate Info.plist
# Note: Version is replaced by the workflow or caller if needed, 
# but here we rely on the input or standard placeholder.
# In the original, it used github.ref_name. We'll accept VERSION as an env var.
VERSION=${VERSION:-"0.0.0"}

cat > "$CONTENTS_PATH/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ValetBar</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.valetbar.app</string>
    <key>CFBundleName</key>
    <string>ValetBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>SUFeedURL</key>
    <string>https://raw.githubusercontent.com/ryzenixx/valetbar-macos/main/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>${SPARKLE_PUBLIC_KEY}</string>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUScheduledCheckInterval</key>
    <integer>3600</integer>
</dict>
</plist>
EOF

echo "✅ App Bundled Successfully!"
