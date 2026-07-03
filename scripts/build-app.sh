#!/bin/bash
# 将 SwiftPM release 构建产物打包为可双击运行的 .app bundle。
# 用法: ./scripts/build-app.sh
# 产物: dist/SkillHub.app

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

APP_NAME="SkillHub"
APP_DISPLAY="SkillHub"
BUNDLE_ID="com.skillhub.app"
VERSION="0.1.0"
BUILD="1"
MIN_MACOS="14.0"

DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "==> 构建 release 二进制"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"
if [[ ! -x "$BIN_PATH" ]]; then
  echo "错误: 找不到 release 二进制 $BIN_PATH" >&2
  exit 1
fi

echo "==> 重新生成 $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "==> 拷贝可执行文件"
cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "==> 拷贝 App 图标"
ICON_SRC="Resources/AppIcon.icns"
if [[ -f "$ICON_SRC" ]]; then
  cp "$ICON_SRC" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
  echo "警告: 缺少 $ICON_SRC，.app 将无 App 图标。" >&2
fi

echo "==> 写 Info.plist"
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_DISPLAY}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_DISPLAY}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS}</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>SkillHub 需要调用 Finder 以在文件管理器中显示 skill 目录。</string>
</dict>
</plist>
PLIST

echo "==> 写 PkgInfo"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

echo "==> ad-hoc 签名（Apple Silicon 运行必需）"
codesign --force --deep --sign - "$APP_BUNDLE" 2>&1 | sed 's/^/    /' || {
  echo "警告: ad-hoc 签名失败，Gatekeeper 首次运行可能拦截。" >&2
}

echo "==> 验证签名"
codesign --verify --verbose=2 "$APP_BUNDLE" 2>&1 | sed 's/^/    /'

echo "==> 产物"
du -sh "$APP_BUNDLE"
echo "    $APP_BUNDLE"

echo "==> 完成"
echo "双击运行: open $APP_BUNDLE"
echo "首次若被 Gatekeeper 拦截: 在 Finder 右键 SkillHub.app → 打开 → 仍要打开"
