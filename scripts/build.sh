#!/bin/bash

set -e

PROJECT_ROOT=$(pwd)
SRC="$PROJECT_ROOT/src"
RES="$PROJECT_ROOT/resources"
DIST="$PROJECT_ROOT/dist"



echo "🛠️ 编译中..."
rm -rf "$DIST"
mkdir -p "$DIST"

clang++ -std=c++17 -fobjc-arc \
    -framework Cocoa -framework Carbon -framework ApplicationServices \
    "$SRC/main.mm" "$SRC/AppDelegate.mm" -o "$DIST/ClipTyper"

echo "🎨 正在生成图标..."
rm -rf "$RES/icon.iconset" "$RES/icon.icns"
mkdir "$RES/icon.iconset"

sips -z 16 16     "$RES/logo.png" --out "$RES/icon.iconset/icon_16x16.png"
sips -z 32 32     "$RES/logo.png" --out "$RES/icon.iconset/icon_16x16@2x.png"
sips -z 32 32     "$RES/logo.png" --out "$RES/icon.iconset/icon_32x32.png"
sips -z 64 64     "$RES/logo.png" --out "$RES/icon.iconset/icon_32x32@2x.png"
sips -z 128 128   "$RES/logo.png" --out "$RES/icon.iconset/icon_128x128.png"
sips -z 256 256   "$RES/logo.png" --out "$RES/icon.iconset/icon_128x128@2x.png"
sips -z 256 256   "$RES/logo.png" --out "$RES/icon.iconset/icon_256x256.png"
sips -z 512 512   "$RES/logo.png" --out "$RES/icon.iconset/icon_256x256@2x.png"
sips -z 512 512   "$RES/logo.png" --out "$RES/icon.iconset/icon_512x512.png"
sips -z 1024 1024 "$RES/logo.png" --out "$RES/icon.iconset/icon_512x512@2x.png"

iconutil -c icns "$RES/icon.iconset" -o "$RES/icon.icns"

echo "📦 打包 ClipTyper.app..."
rm -rf "$DIST/ClipTyper.app"
mkdir -p "$DIST/ClipTyper.app/Contents/MacOS"
mkdir -p "$DIST/ClipTyper.app/Contents/Resources"

cp "$DIST/ClipTyper" "$DIST/ClipTyper.app/Contents/MacOS/"
cp "$RES/logo_menu.png" "$DIST/ClipTyper.app/Contents/Resources/"
cp "$PROJECT_ROOT/Info.plist" "$DIST/ClipTyper.app/Contents/"
cp "$RES/icon.icns" "$DIST/ClipTyper.app/Contents/Resources/"

touch "$DIST/ClipTyper.app"

echo "🎉 构建完成：$DIST/ClipTyper.app"