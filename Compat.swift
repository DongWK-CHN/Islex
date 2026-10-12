//  IsleX 灵屿 —— 兼容层与工具扩展（tfs/颜色/SF Symbols/拖放）
//  由 main.swift 自动拆分生成，勿手动调整导入。

import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers
import ImageIO
import ServiceManagement
import ApplicationServices
import CoreAudio
import IOKit
#if APPSTORE
import IOKit.ps
#endif
import Foundation

func tfs(_ base: CGFloat) -> CGFloat {
    // 观感优化：最小字号不低于 8pt（原 7pt 级文字过小），整体 +4% 提升可读性
    max(base, 8) * (AppState.shared.fontScale * 1.04)
}

/// 岛内控件圆角同步：按「圆角样式」倍率缩放基础半径（macOS 26 Tahoe 体系：窗口 26 / 面板 18 / 控件 8-9），
/// 使所有内嵌控件随灵动岛外框圆角整体缩放，观感一致。
func rr(_ base: CGFloat) -> CGFloat {
    base * AppState.shared.cornerRadiusMultiplier
}

/// 系统音量变化 C 回调：转发到 AppState 主线程处理（岛内提示 + 状态同步）
let volumeChangeCallback: AudioObjectPropertyListenerProc = { _, _, _, _ in
    DispatchQueue.main.async { AppState.shared.onSystemVolumeChanged() }
    return noErr
}

// MARK: - 颜色扩展（macOS 11 兼容：cyan/mint/teal/indigo 为 macOS 12+，用自定义近似色替代）
extension Color {
    static let lgCyan = Color(red: 0.25, green: 0.85, blue: 0.95)
    static let lgMint = Color(red: 0.40, green: 0.90, blue: 0.75)
    static let lgTeal = Color(red: 0.20, green: 0.75, blue: 0.80)
    static let lgIndigo = Color(red: 0.42, green: 0.45, blue: 0.95)
}

// MARK: - macOS 10.15 兼容层（SF Symbols / onChange / help / onDrop 的可用性封装）

/// 启动诊断日志：写入 ~/Library/Logs/NotchIsland/startup.log，用于定位 10.15 启动崩溃的精确位置
func startupLog(_ msg: String) {
    let fm = FileManager.default
    guard let dir = fm.urls(for: .libraryDirectory, in: .userDomainMask).first?
        .appendingPathComponent("Logs/NotchIsland", isDirectory: true) else { return }
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent("startup.log")
    let line = "[\(Int(Date().timeIntervalSince1970 * 1000))] \(msg)\n"
    if let data = line.data(using: .utf8) {
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }
}

/// SF Symbols 兼容：macOS 11+ 用系统符号，10.15 用 Unicode 字形回退
@ViewBuilder
func sysImage(_ name: String) -> some View {
    if #available(macOS 11.0, *) {
        Image(systemName: name)
    } else {
        Text(legacyGlyph(name)).font(.system(size: 13))
    }
}

func legacyGlyph(_ name: String) -> String {
    switch name {
    case "app": return "▣"
    case "arrow.counterclockwise": return "⟲"
    case "arrow.down.doc": return "↓"
    case "arrow.right.doc.on.clipboard": return "↳"
    case "arrow.triangle.2.circlepath", "arrow.triangle.2.circlepath.doc": return "⇄"
    case "arrow.up.forward.app": return "↗"
    case "backward.fill": return "◀"
    case "calendar": return "▦"
    case "checkmark.circle.fill", "checkmark.seal.fill": return "✓"
    case "chevron.down": return "⌄"
    case "chevron.up": return "⌃"
    case "clock.arrow.2.circlepath": return "⟳"
    case "cpu": return "▤"
    case "doc": return "▤"
    case "exclamationmark.triangle.fill": return "⚠"
    case "eye.fill": return "◉"
    case "folder": return "▸"
    case "forward.fill": return "▶"
    case "gearshape": return "⚙"
    case "hammer.fill": return "⚒"
    case "laptopcomputer": return "▢"
    case "link.badge.plus": return "🔗"
    case "minus.circle.fill": return "−"
    case "music.note": return "♪"
    case "paintbrush.pointed.fill": return "◐"
    case "plus", "plus.circle.fill", "plus.circle.dashed": return "⊕"
    case "power": return "⏻"
    case "sparkles": return "✦"
    case "speaker.fill", "speaker.wave.2.fill", "speaker.wave.3.fill": return "♬"
    case "speaker.slash.fill": return "✕"
    case "square.grid.2x2": return "▦"
    case "thermometer.high", "thermometer.medium": return "▲"
    case "trash": return "🗑"
    case "tray", "tray.fill", "tray.full": return "▭"
    case "xmark.circle.fill": return "✕"
    case "zzz": return "z"
    default: return "•"
    }
}

extension View {
    /// onChange 兼容：macOS 11+ 原生变化检测；10.15 用状态缓存实现「仅值变化时触发」
    @ViewBuilder
    func onValueChange<Value: Equatable>(of value: Value, perform action: @escaping (Value) -> Void) -> some View {
        if #available(macOS 11.0, *) {
            onChange(of: value, perform: action)
        } else {
            modifier(ValueChange10Tracker(value: value, action: action))
        }
    }
}

/// 10.15 专用 onChange 降级：缓存上一次值，仅在值真正变化时触发 action。
/// 不能用 onReceive(Just(value))——它会在每次视图重算时反复触发，若 action 修改状态
/// 将形成「重算 → 触发 → 改状态 → 重算」死循环，CPU 飙升（已修复的启动即 99% 问题）。
struct ValueChange10Tracker<Value: Equatable>: ViewModifier {
    let value: Value
    let action: (Value) -> Void
    @State private var last: Value?

    func body(content: Content) -> some View {
        content
            .onAppear { fireIfChanged() }
            .onReceive(Just(value)) { _ in fireIfChanged() }
    }

    private func fireIfChanged() {
        if last != value {
            last = value
            action(value)
        }
    }
}

extension View {
    /// help 兼容：10.15 无提示则忽略
    @ViewBuilder
    func helpAny(_ text: String) -> some View {
        if #available(macOS 11.0, *) {
            help(text)
        } else {
            self
        }
    }

    /// 文件拖放兼容：macOS 11+ 用 isTargeted 版本；10.15 用 DropDelegate 回退
    @ViewBuilder
    func fileDrop(targeted: Binding<Bool>, action: @escaping ([NSItemProvider]) -> Bool) -> some View {
        if #available(macOS 11.0, *) {
            onDrop(of: [.fileURL], isTargeted: targeted) { action($0) }
        } else {
            onDrop(of: ["public.file-url"], delegate: LegacyFileDropDelegate(targeted: targeted, action: action))
        }
    }
}

/// 10.15 拖放代理：进入/离开/松手时同步高亮状态
struct LegacyFileDropDelegate: DropDelegate {
    let targeted: Binding<Bool>
    let action: ([NSItemProvider]) -> Bool
    func dropEntered(info: DropInfo) { targeted.wrappedValue = true }
    func dropExited(info: DropInfo) { targeted.wrappedValue = false }
    func performDrop(info: DropInfo) -> Bool {
        targeted.wrappedValue = false
        return action(info.itemProviders(for: ["public.file-url"]))
    }
}

