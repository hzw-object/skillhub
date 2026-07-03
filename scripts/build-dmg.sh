#!/bin/bash
# 将 build-app.sh 产出的 SkillHub.app 打包为可分发的 .dmg 安装包。
# 用法: ./scripts/build-dmg.sh
# 产物: dist/SkillHub-${VERSION}-${ARCH}.dmg
#
# 布局: 简洁的「拖拽安装」窗口 — 左侧 SkillHub.app，右侧 Applications 文件夹快捷方式。
# 压缩: UDZO (zlib-level 影像压缩)，适合 GitHub Release 上传。

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

APP_NAME="SkillHub"
VERSION="0.1.0"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

# 架构：arm64 / x86_64。让 .dmg 文件名带上架构，方便用户下载对位版本。
ARCH="$(uname -m)"
DMG_NAME="$APP_NAME-$VERSION-$ARCH.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"
STAGING_DIR="$DIST_DIR/.dmg-staging"

# ── 前置检查 ──────────────────────────────────────────────────
if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "==> 找不到 $APP_BUNDLE，先运行 ./scripts/build-app.sh" >&2
  exit 1
fi

echo "==> 清理旧产物"
rm -rf "$STAGING_DIR"
rm -f "$DMG_PATH"

echo "==> 准备 .dmg 暂存目录"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# ── 生成 .dmg ──────────────────────────────────────────────────
echo "==> 生成 $DMG_NAME"
# -fs HFS+:   macOS 文件系统，Finder 能正确渲染拖拽布局
# -format UDZO: zlib 压缩的只读影像，体积小、适合分发
# -srcfolder: 把暂存目录整包压入
hdiutil create \
  -volname "$APP_NAME" \
  -fs HFS+ \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH"

# ── 校验 ────────────────────────────────────────────────────────
echo "==> 校验影像完整性"
hdiutil verify "$DMG_PATH" >/dev/null

echo "==> 校验 .app 签名"
codesign --verify --verbose=2 "$APP_BUNDLE" 2>&1 | sed 's/^/    /'

echo "==> 清理暂存"
rm -rf "$STAGING_DIR"

# ── 产物 ────────────────────────────────────────────────────────
SIZE=$(du -h "$DMG_PATH" | cut -f1)
echo ""
echo "==> 完成"
echo "    产物: $DMG_PATH ($SIZE)"
echo "    上传: gh release create v$VERSION \"$DMG_PATH\""
