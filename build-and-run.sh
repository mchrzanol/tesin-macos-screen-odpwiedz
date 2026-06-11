#!/bin/bash
set -e

APP_NAME="TestAnswerBar"
APP_DIR="$APP_NAME.app/Contents"

echo "[1/4] Buduję projekt..."
swift build -c debug 2>&1

echo "[2/4] Tworzę bundle .app..."
rm -rf "$APP_NAME.app"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

# Copy binary
cp ".build/arm64-apple-macosx/debug/$APP_NAME" "$APP_DIR/MacOS/$APP_NAME"

# Copy .env next to the .app so the app can find it
if [ -f .env ]; then
    cp .env "$APP_DIR/MacOS/.env"
fi

# Create Info.plist
cat > "$APP_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TestAnswerBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.TestAnswerBar</string>
    <key>CFBundleName</key>
    <string>TestAnswerBar</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "[3/4] Uruchamiam $APP_NAME.app..."
echo "============================================"
echo "  TestAnswerBar działa!"
echo "  Szukaj ikony mózgu na pasku menu."
echo "  Cmd+Shift+1 = zrzut + analiza"
echo "  Cmd+przeciągnij ikonę = zmień pozycję"
echo "  Ctrl+C tutaj = zamknij aplikację"
echo "============================================"

# Run binary directly (inherits Terminal's Screen Recording permission)
cd "$(dirname "$0")"
"$APP_NAME.app/Contents/MacOS/$APP_NAME"
