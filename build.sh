#!/bin/bash
set -e
cd "$(dirname "$0")"

ROOT="$(pwd)"
SRC="$ROOT/Sources"
BUILD_DIR="build"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "===== 生成应用图标 ====="
cat > "$BUILD_DIR/icongen.swift" <<'SWIFT'
import AppKit

@main
struct IconGen {
    static func main() {
        let outDir = CommandLine.arguments[1]
        let fm = FileManager.default
        try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)

        func render(_ px: CGFloat) -> NSImage {
            let img = NSImage(size: NSSize(width: px, height: px))
            img.lockFocus()
            defer { img.unlockFocus() }
            guard let ctx = NSGraphicsContext.current?.cgContext else { return img }

            func rx(_ v: CGFloat) -> CGFloat { px * v }

            let bg = NSBezierPath(roundedRect: NSRect(x: rx(0.02), y: rx(0.02), width: rx(0.96), height: rx(0.96)),
                                  xRadius: rx(0.225), yRadius: rx(0.225))
            let bgGrad = NSGradient(colors: [
                NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.18, alpha: 1),
                NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.09, alpha: 1)
            ])!
            bgGrad.draw(in: bg, angle: -90)

            let glow = NSBezierPath(ovalIn: NSRect(x: rx(0.10), y: rx(0.10), width: rx(0.80), height: rx(0.80)))
            let glowGrad = NSGradient(colors: [
                NSColor(calibratedRed: 0.25, green: 0.80, blue: 1.00, alpha: 0.40),
                NSColor(calibratedRed: 0.55, green: 0.35, blue: 1.00, alpha: 0.22),
                NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.20, alpha: 0)
            ])!
            glowGrad.draw(in: glow, relativeCenterPosition: NSPoint(x: 0, y: 0.22))

            let pillRect = NSRect(x: rx(0.18), y: rx(0.35), width: rx(0.64), height: rx(0.30))
            let pill = NSBezierPath(roundedRect: pillRect, xRadius: rx(0.15), yRadius: rx(0.15))
            let pillGrad = NSGradient(colors: [
                NSColor(calibratedRed: 0.10, green: 0.60, blue: 1.00, alpha: 1),
                NSColor(calibratedRed: 0.38, green: 0.40, blue: 1.00, alpha: 1),
                NSColor(calibratedRed: 0.75, green: 0.30, blue: 0.95, alpha: 1)
            ])!
            pillGrad.draw(in: pill, angle: 50)

            let cx = pillRect.midX
            let baseY = pillRect.minY + rx(0.015)
            let peakY = pillRect.midY - rx(0.012)
            let island = NSBezierPath()
            island.move(to: NSPoint(x: pillRect.minX + rx(0.05), y: baseY))
            island.curve(to: NSPoint(x: cx, y: peakY),
                         controlPoint1: NSPoint(x: pillRect.minX + rx(0.22), y: baseY - rx(0.03)),
                         controlPoint2: NSPoint(x: cx - rx(0.10), y: peakY + rx(0.03)))
            island.curve(to: NSPoint(x: pillRect.maxX - rx(0.05), y: baseY),
                         controlPoint1: NSPoint(x: cx + rx(0.10), y: peakY + rx(0.03)),
                         controlPoint2: NSPoint(x: pillRect.maxX - rx(0.22), y: baseY - rx(0.03)))
            island.close()
            ctx.saveGState()
            pill.addClip()
            NSColor(calibratedWhite: 0.04, alpha: 0.95).setFill()
            island.fill()
            NSColor(calibratedWhite: 1.0, alpha: 0.10).setFill()
            NSBezierPath(rect: NSRect(x: pillRect.minX, y: baseY - rx(0.012), width: pillRect.width, height: rx(0.012))).fill()
            ctx.restoreGState()

            let sunGlow = NSBezierPath(ovalIn: NSRect(x: cx - rx(0.055), y: peakY + rx(0.037), width: rx(0.110), height: rx(0.110)))
            NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.45, alpha: 0.25).setFill()
            sunGlow.fill()
            let sun = NSBezierPath(ovalIn: NSRect(x: cx - rx(0.040), y: peakY + rx(0.052), width: rx(0.080), height: rx(0.080)))
            NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.55, alpha: 1).setFill()
            sun.fill()

            let hiRect = NSRect(x: pillRect.minX + rx(0.035), y: pillRect.maxY - rx(0.065), width: pillRect.width - rx(0.07), height: rx(0.028))
            let hi = NSBezierPath(roundedRect: hiRect, xRadius: rx(0.014), yRadius: rx(0.014))
            NSColor(calibratedWhite: 1.0, alpha: 0.30).setFill()
            hi.fill()

            return img
        }

        let specs: [(Int, Int)] = [(16,1),(16,2),(32,1),(32,2),(128,1),(128,2),(256,1),(256,2),(512,1),(512,2)]
        for (s, sc) in specs {
            let name = sc == 1 ? "icon_\(s)x\(s).png" : "icon_\(s)x\(s)@2x.png"
            let px = CGFloat(s) * CGFloat(sc)
            let img = render(px)
            guard let tiff = img.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else { continue }
            try? png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
        }
    }
}
SWIFT
swiftc -parse-as-library -framework AppKit "$BUILD_DIR/icongen.swift" -o "$BUILD_DIR/icongen"
"$BUILD_DIR/icongen" "$BUILD_DIR/AppIcon.iconset"
iconutil -c icns "$BUILD_DIR/AppIcon.iconset" -o "$BUILD_DIR/AppIcon.icns"

build_variant() {
    local APP_NAME="$1"
    local EXTRA_FLAGS="$2"
    local MR_LINK=""
    local OBJC_HEADER=""
    if [ -z "$EXTRA_FLAGS" ]; then
        # 有 MediaRemote 的版本：链接框架 + 引入桥接头（Swift 直接调用 MR 函数）
        MR_LINK="-F /System/Library/PrivateFrameworks -framework MediaRemote"
        OBJC_HEADER="-import-objc-header $ROOT/Resources/MediaRemoteBridge.h"
    fi
    local EXE="IsleX"
    local APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
    local LABEL="有 SMTC / macOS < 26.5"
    if [ -n "$EXTRA_FLAGS" ]; then
        LABEL="无 SMTC / macOS 26.5+"
    fi

    echo ""
    echo "===== 构建 $APP_NAME（$LABEL） ====="
    echo "==> 编译 Swift 源码"
    swiftc -swift-version 5 -O \
      -target arm64-apple-macosx14.0 \
      $OBJC_HEADER \
      $MR_LINK \
      -framework AppKit -framework SwiftUI -framework Combine -framework Foundation -framework ServiceManagement \
      $EXTRA_FLAGS \
      "$SRC"/*.swift -o "$BUILD_DIR/$EXE"

    echo "==> 组装 .app 包结构"
    mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
    cp "$BUILD_DIR/$EXE" "$APP_BUNDLE/Contents/MacOS/$EXE"
    cp "$ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
    cp "$BUILD_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    chmod +x "$APP_BUNDLE/Contents/MacOS/$EXE"

    echo "==> 代码签名（稳定自签名证书「IsleX Developer」：TCC 授权跨重建保留；无证书时回退 ad-hoc）"
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "IsleX Developer"; then
        codesign --force --deep -s "IsleX Developer" "$APP_BUNDLE"
    else
        codesign --force --deep -s - "$APP_BUNDLE"
    fi

    echo "==> 打包 .dmg（拖拽安装布局）"
    local STAGE="$BUILD_DIR/dmg_stage_$APP_NAME"
    rm -rf "$STAGE"; mkdir -p "$STAGE"
    cp -R "$APP_BUNDLE" "$STAGE/"
    ln -s /Applications "$STAGE/Applications"
    local DMG="$BUILD_DIR/$APP_NAME.dmg"
    rm -f "$DMG"
    hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -fs HFS+ -format UDZO "$DMG" >/dev/null
    rm -rf "$STAGE"
    echo "完成: $DMG"
}

build_variant "IsleX" "-D NOSMTC"
build_variant "IsleX-SMTC" ""

echo ""
echo "===== 全部完成 ====="
ls -lh "$BUILD_DIR"/IsleX*.dmg
