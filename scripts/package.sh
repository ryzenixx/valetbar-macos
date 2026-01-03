#!/bin/bash
set -e

echo "📦 Creating DMG..."

if ! command -v create-dmg &> /dev/null; then
    echo "ℹ️  Installing create-dmg..."
    brew install create-dmg
fi

# Ensure no existing dmg
rm -f "ValetBar.dmg"

create-dmg \
  --volname "ValetBar Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "ValetBar.app" 200 190 \
  --hide-extension "ValetBar.app" \
  --app-drop-link 600 185 \
  "ValetBar.dmg" \
  "ValetBar.app"

if [ ! -f "ValetBar.dmg" ]; then
    echo "❌ CRITICAL ERROR: DMG creation failed"
    exit 1
fi

echo "✅ DMG Created Successfully!"
