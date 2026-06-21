#!/bin/bash
set -e

declare -A PLATFORMS=(
  ["aarch64_generic"]="https://mirrors.pku.edu.cn/immortalwrt/releases/24.10.4/packages/aarch64_generic"
)

declare -A PACKAGE_SOURCES=(
  ["luci-theme-argon"]="luci"
  ["luci-app-argon-config"]="luci"
  ["luci-i18n-argon-config"]="luci"
)

OUT_DIR=$(pwd)
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

for platform in "${!PLATFORMS[@]}"; do
  BASE_URL="${PLATFORMS[$platform]}"
  SAVE_DIR="${OUT_DIR}/${platform}"
  mkdir -p "$SAVE_DIR"

  echo "📦 正在处理平台: $platform"

  for keyword in "${!PACKAGE_SOURCES[@]}"; do
    subdir="${PACKAGE_SOURCES[$keyword]}"
    URL="${BASE_URL}/${subdir}"
    PKG_INDEX="${TMP_DIR}/${platform}_${subdir}_Packages"

    echo "🔍 从 Packages.gz 查找 $keyword"

    if ! curl -fsL "${URL}/Packages.gz" | gunzip -c > "$PKG_INDEX"; then
      echo "⚠️ 无法获取 ${URL}/Packages.gz"
      continue
    fi

    FILE=$(awk -v kw="$keyword" '
      $1=="Filename:" && $2 ~ "^"kw".*\\.ipk$" {
        print $2; exit
      }
    ' "$PKG_INDEX")

    if [ -n "$FILE" ]; then
      echo "⬇️ 正在下载: $FILE"
      curl -fsL -o "${SAVE_DIR}/${FILE##*/}" "${URL}/${FILE}"

      if [[ "$FILE" == *"~"* ]]; then
        NEW_FILE=$(basename "$FILE" | tr '~' '-')
        mv "${SAVE_DIR}/$(basename "$FILE")" "${SAVE_DIR}/${NEW_FILE}"
        echo "🔧 已重命名为: $NEW_FILE"
      fi
    else
      echo "❌ 未找到匹配: $keyword"
    fi
  done
done

echo "✅ argon 主题下载完成，文件已存入 aarch64_generic/ 目录中。"
