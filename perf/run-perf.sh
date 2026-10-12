#!/bin/bash
# 性能实测：编译 + 打包 + 自动展开/收起 + 输出卡顿统计
# 用法: perf/run-perf.sh <variant>   （variant 例如 before / after）
set -e
cd "$(dirname "$0")/.."
NAME="${1:?usage: perf/run-perf.sh <variant> [srcdir]}"
SRC="${2:-Sources}"
OUT="build/perf"
APP="$OUT/$NAME.app"
mkdir -p "$OUT"

echo "==> 编译 $NAME（$(date '+%H:%M:%S')）"
swiftc -swift-version 5 -O -target arm64-apple-macosx14.0 \
  -D NOSMTC -D PERF \
  -framework AppKit -framework SwiftUI -framework Combine -framework Foundation -framework ServiceManagement \
  "$SRC"/*.swift perf/JankProbe.swift -o "$OUT/$NAME"
echo "==> 编译完成（$(date '+%H:%M:%S')）"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$OUT/$NAME" "$APP/Contents/MacOS/IsleX"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp build/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns" 2>/dev/null || true
chmod +x "$APP/Contents/MacOS/IsleX"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "IsleX Developer"; then
  codesign --force --deep -s "IsleX Developer" "$APP" >/dev/null 2>&1
else
  codesign --force --deep -s - "$APP" >/dev/null 2>&1
fi

echo "==> 暂停正在运行的 /Applications/IsleX.app，保证实测环境干净"
pkill -f "/Applications/IsleX.app/Contents/MacOS/IsleX" 2>/dev/null || true
pkill -f "build/perf/.*/Contents/MacOS/IsleX" 2>/dev/null || true
sleep 1.5

LOG="$OUT/$NAME.log"
: > "$LOG"
"$APP/Contents/MacOS/IsleX" > "$LOG" 2>&1 &
PID=$!
# PERF_SAMPLE="<日志中的标记>"：等日志出现该标记后用 sample 抓 3 秒热点
SAMPLE_MARK="${PERF_SAMPLE:-}"
SAMPLED=0
for i in $(seq 1 200); do
  grep -q "\[perf\] done" "$LOG" 2>/dev/null && break
  kill -0 $PID 2>/dev/null || break
  if [ -n "$SAMPLE_MARK" ] && [ "$SAMPLED" = "0" ] && grep -q "$SAMPLE_MARK" "$LOG" 2>/dev/null; then
    SAMPLED=1
    sample $PID 3 -file "$OUT/$NAME-sample.txt" >/dev/null 2>&1 || true
  fi
  sleep 0.5
done
sleep 0.5
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true

echo "===== $NAME 实测结果 ====="
grep "\[perf\]" "$LOG" || { echo "(无探针输出，日志尾部：)"; tail -30 "$LOG"; }
