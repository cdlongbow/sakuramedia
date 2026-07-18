#!/usr/bin/env bash
# 从 macOS 里最大的 1024x1024 图标缩出 128/256/512 三档,
# 供 flatpak manifest 装到 /app/share/icons/hicolor/<size>/apps/。
#
# 依赖 ImageMagick(magick 命令,ubuntu 装 imagemagick 包;
# 老版本用 convert 命令,已做兼容)。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLATPAK_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$FLATPAK_DIR/../.." && pwd)"

SRC="$REPO_ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset/icon-512@2x.png"
DST="$FLATPAK_DIR/icons"

if [ ! -f "$SRC" ]; then
  echo "❌ 找不到源图标: $SRC" >&2
  exit 1
fi

if command -v magick >/dev/null 2>&1; then
  RESIZE=(magick)
elif command -v convert >/dev/null 2>&1; then
  RESIZE=(convert)
else
  echo "❌ 需要 ImageMagick(magick 或 convert 命令)" >&2
  exit 1
fi

mkdir -p "$DST"

for size in 128 256 512; do
  "${RESIZE[@]}" "$SRC" -resize "${size}x${size}" "$DST/${size}.png"
  echo "✓ 生成 $DST/${size}.png"
done
