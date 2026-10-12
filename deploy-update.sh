#!/bin/bash
# IsleX 灵屿 OTA manifest 生成脚本
# 用法: bash deploy-update.sh <新版本号> "<更新说明>" <dmg/zip 下载地址>
# 会把 latest.json 写到 build/latest.json，部署时上传到 manifestURL 指向的位置即可。
set -e
cd "$(dirname "$0")"

VERSION="${1:?用法: deploy-update.sh <版本号> <说明> <下载地址>}"
NOTES="${2:-}"
URL="${3:-IsleX.dmg}"

cat > build/latest.json <<JSON
{
  "version": "$VERSION",
  "notes": "$NOTES",
  "url": "$URL"
}
JSON

echo "已生成 build/latest.json："
cat build/latest.json
echo ""
echo "下一步：把 build/latest.json 上传到你配置的 manifest 地址"
echo "（macOS: Sources/Updater.swift 的 manifestURL）"
