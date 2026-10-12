//  IsleX 灵屿 —— 设置窗口（菜单栏入口）
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

// MARK: - 设置窗口（菜单栏图标「设置」打开，不占用灵动岛本体页面）

final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "IsleX 灵屿 设置"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.contentView = NSHostingView(rootView: SettingsWindowView(state: AppState.shared))
        super.init(window: panel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show(tab: Int = 0) {
        NotificationCenter.default.post(name: .openSettingsTab, object: nil, userInfo: ["tab": tab])
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let openSettingsTab = Notification.Name("openSettingsTab")
}

struct SettingsWindowView: View {
    @ObservedObject var state: AppState
    @State private var tab = 0
    private var tabs: [String] { [L("外观"), L("系统"), L("跑马灯"), L("小组件")] }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                sysImage("gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                Text(L("IsleX 灵屿 设置"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            HStack(spacing: 6) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { i, t in
                    Button {
                        tab = i
                    } label: {
                        Text(t)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(tab == i ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(Capsule().fill(tab == i ? Color.blue.opacity(0.45) : Color.white.opacity(0.05)))
                    }
                    .buttonStyle(PressBtn())
                }
                Spacer()
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    switch tab {
                    case 0: appearanceTab
                    case 1: systemTab
                    case 2: marqueeTab
                    default: widgetsTab
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .padding(16)
        .frame(minWidth: 440, minHeight: 480)
        .background(Color(red: 0.09, green: 0.09, blue: 0.11))
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsTab)) { note in
            if let t = note.userInfo?["tab"] as? Int { tab = t }
        }
    }

    // MARK: 外观
    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsGroup(L("形态与风格")) {
                chipRow(options: ["自动（贴合刘海）", "悬浮胶囊"], selected: state.appearanceShape) { state.setAppearanceShape($0) }
                chipRow(options: ["圆角默认", "圆润", "方正"], selected: state.appearanceCornerStyle) { state.setAppearanceCornerStyle($0) }
                chipRow(options: ["玻璃跟随系统", "深色"], selected: state.appearanceTheme) { state.setAppearanceTheme($0) }
            }
            settingsGroup(L("尺寸与位置")) {
                let cw = state.appearanceCompactWidth > 0 ? state.appearanceCompactWidth : state.compactWidth
                let ch = state.appearanceCompactHeight > 0 ? state.appearanceCompactHeight : state.compactHeight
                let ew = state.appearanceExpandedWidth > 0 ? state.appearanceExpandedWidth : state.expandedWidth
                let eh = state.appearanceExpandedHeight > 0 ? state.appearanceExpandedHeight : state.expandedHeight
                sliderSizeRow(L("收起宽度"), value: cw, range: min(80, cw)...max(700, cw)) { state.setAppearanceCompactWidth($0) }
                sliderSizeRow(L("收起高度"), value: ch, range: min(16, ch)...max(160, ch)) { state.setAppearanceCompactHeight($0) }
                sliderSizeRow(L("展开宽度"), value: ew, range: min(200, ew)...max(1800, ew)) { state.setAppearanceExpandedWidth($0) }
                sliderSizeRow(L("展开高度"), value: eh, range: min(120, eh)...max(1200, eh)) { state.setAppearanceExpandedHeight($0) }
                stepperRow(L("水平偏移"), value: state.appearanceOffsetX, step: 2, range: -200...200) { state.setAppearanceOffsetX($0) }
                stepperRow(L("垂直偏移"), value: state.appearanceOffsetY, step: 2, range: -200...200) { state.setAppearanceOffsetY($0) }
            }
            settingsGroup(L("显示")) {
                stepperRow(L("展开缩放"), value: state.appearanceScale, step: 0.1, range: 0.5...3.0) { state.setAppearanceScale($0) }
                stepperRow(L("收起缩放"), value: state.appearanceCompactScale, step: 0.1, range: 0.5...3.0) { state.setAppearanceCompactScale($0) }
                stepperRow(L("字体大小"), value: state.appearanceFontSize, step: 1, range: 9...18) { state.setAppearanceFontSize($0) }
                toggleRow(L("极光质感（Aurora Texture）"), isOn: state.auroraEnabled) { state.setAuroraEnabled($0) }
            }
            settingsGroup(L("自定义背景")) {
                toggleRow(L("自定义背景颜色"), isOn: state.backgroundCustomEnabled) { state.setBackgroundCustomEnabled($0) }
                if state.backgroundCustomEnabled {
                    sliderRow("红", value: state.backgroundRed) { state.setBackgroundColor(red: $0, green: state.backgroundGreen, blue: state.backgroundBlue) }
                    sliderRow("绿", value: state.backgroundGreen) { state.setBackgroundColor(red: state.backgroundRed, green: $0, blue: state.backgroundBlue) }
                    sliderRow("蓝", value: state.backgroundBlue) { state.setBackgroundColor(red: state.backgroundRed, green: state.backgroundGreen, blue: $0) }
                    RoundedRectangle(cornerRadius: 8)
                        .fill(state.islandBackground)
                        .frame(height: 24)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                }
                Divider().background(Color.white.opacity(0.1))
                toggleRow(L("自定义背景图片"), isOn: state.backgroundImageEnabled) { state.setBackgroundImageEnabled($0) }
                if state.backgroundImageEnabled {
                    HStack {
                        Button(L("选择图片…")) { state.pickBackgroundImage() }
                            .buttonStyle(.bordered)
                        if state.backgroundImage != nil {
                            Text(L("已选择图片"))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            settingsGroup(L("性能")) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(state.lowMemoryMode ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text(state.lowMemoryMode
                        ? "低配模式已自动启用（内存 ≤ 6GB）：动态模糊已禁用、后台轮询降频，优先保证流畅"
                        : "内存充足，完整性能模式")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
            settingsGroup(L("页面布局（每页独立）")) {
                Text("每页可独立设置：布局风格（紧凑/标准/大卡片）、展开尺寸、内容区块显示")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(0..<state.pageCount, id: \.self) { page in
                    pageLayoutRow(page: page)
                }
            }
            Button(L("恢复默认")) { state.resetAppearance() }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .buttonStyle(PressBtn())
        }
    }

    // MARK: 系统
    private var systemTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsGroup(L("语言")) {
                HStack(spacing: 8) {
                    Text(L("界面语言"))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    Picker("", selection: $state.appLanguage) {
                        Text("中文").tag("zh")
                        Text("English").tag("en")
                        Text("日本語").tag("ja")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                    Spacer()
                }
            }
            settingsGroup(L("电源")) {
                toggleRow(L("合盖不休眠"), isOn: state.lidNoSleepEnabled) { _ in state.toggleLidNoSleep() }
            }
            settingsGroup(L("提示与通知")) {
                toggleRow(L("耳机连接提示"), isOn: state.airPodsToastEnabled) { state.setAirPodsToastEnabled($0) }
            }
            settingsGroup(L("CPU 温度")) {
                HStack(spacing: 6) {
                    sysImage("thermometer.medium")
                        .font(.system(size: 14))
                        .foregroundColor(state.cpuTempIndicatorColor)
                    Text(state.cpuTemp > 0 ? String(format: "%.0f°C", state.cpuTemp) : state.thermalLevel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(state.cpuTempIndicatorColor)
                }
            }
        }
    }

    // MARK: 音量键拦截（辅助功能授权引导与状态）
#if !APPSTORE
    private var suppressText: String {
        if !state.volumeSuppressPermitted {
            return "未授权：请点下方「前往授权」，在 系统设置 → 隐私与安全性 → 辅助功能 中勾选 IsleX 灵屿，返回后自动生效（无需重启）"
        }
        if !state.volumeSuppressInstalled { return "正在安装拦截器…" }
        if !state.volumeSuppressEnabled { return "拦截器被系统暂停，正在恢复…" }
        return "已生效：按音量键系统动画不再出现（收到事件 \(state.volumeSuppressEvents) / 拦截 \(state.volumeSuppressCount)）"
    }

    private var suppressColor: Color {
        if !state.volumeSuppressPermitted { return .orange }
        if !state.volumeSuppressInstalled || !state.volumeSuppressEnabled { return .yellow }
        return .green
    }

    private func promptSuppressAuth() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "屏蔽系统音量动画需要「辅助功能」权限。\n请在 系统设置 → 隐私与安全性 → 辅助功能 中勾选 IsleX 灵屿，返回后自动生效（无需重启）。"
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    private func openAccessibilitySettings() {
        let schemes = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security",
        ]
        for s in schemes {
            if let url = URL(string: s) {
                NSWorkspace.shared.open(url)
                return
            }
        }
    }
#endif

    // MARK: 跑马灯
    private var marqueeTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsGroup(L("跑马灯边框")) {
                toggleRow(L("启用动态边框"), isOn: state.marqueeEnabled) { state.setMarqueeEnabled($0) }
                if state.marqueeEnabled {
                    chipRow(options: AppState.marqueeThemes.map { $0.name }, selected: state.marqueeThemeIndex) { state.setMarqueeTheme($0) }
                    HStack {
                        Text(L("速度"))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                        Button("-") { state.setMarqueeSpeed(max(0, state.marqueeSpeedIndex - 1)) }
                            .font(.system(size: 14, weight: .bold))
                            .buttonStyle(PressBtn())
                            .foregroundColor(.white.opacity(0.7))
                        Text([L("慢"), L("中"), L("快"), L("很快"), L("极快")][min(max(state.marqueeSpeedIndex, 0), 4)])
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 40, alignment: .trailing)
                        Button("+") { state.setMarqueeSpeed(min(4, state.marqueeSpeedIndex + 1)) }
                            .font(.system(size: 14, weight: .bold))
                            .buttonStyle(PressBtn())
                            .foregroundColor(.white.opacity(0.7))
                    }
                    toggleRow(L("CPU 联动"), isOn: state.marqueeCpuLinked) { state.setMarqueeCpuLinked($0) }
                }
            }
        }
    }

    // MARK: 小组件
    private var widgetsTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsGroup(L("灵屿页面显示")) {
                ForEach(0..<state.pageOrder.count, id: \.self) { pos in
                    let page = state.pageOrder[pos]
                    HStack(spacing: 8) {
                        Text("\(pos + 1). \(state.displayName(of: page))")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                        if page == 0 {
                            Text(L("固定"))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.35))
                        } else {
                            Toggle("", isOn: Binding(
                                get: { !state.hiddenPages.contains(page) },
                                set: { on in state.togglePageHidden(page) }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 2)
                }
                Button(L("全部显示")) { state.showAllPages() }
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .buttonStyle(PressBtn())
            }
        }
    }

    // MARK: 通用控件
    private func settingsGroup<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.45))
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
    }

    private func toggleRow(_ title: String, isOn: Bool, _ onChange: @escaping (Bool) -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { onChange(!isOn) }
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Color.green.opacity(0.55) : Color.white.opacity(0.15))
                        .frame(width: 36, height: 20)
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .padding(2)
                }
            }
        }
        .buttonStyle(PressBtn())
    }

    private func chipRow(options: [String], selected: Int, _ onSelect: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(options.enumerated()), id: \.offset) { i, o in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { onSelect(i) }
                } label: {
                    Text(o)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selected == i ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(selected == i ? Color.blue.opacity(0.5) : Color.white.opacity(0.07)))
                }
                .buttonStyle(PressBtn())
            }
            Spacer()
        }
    }

    /// 单页布局设置：风格 / 自定义尺寸 / 区块开关
    private func pageLayoutRow(page: Int) -> some View {
        let cfg = state.pageLayout(for: page)
        let blocks = PageLayoutConfig.pageBlocks[page] ?? []
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                sysImage("square.grid.2x2")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                Text(state.displayName(of: page))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            chipRow(options: ["标准", "紧凑", "大卡片"], selected: cfg.style) {
                state.setPageLayoutStyle(page, $0)
            }
            toggleRow(L("自定义展开尺寸"), isOn: cfg.customSize) {
                state.setPageLayoutCustomSize(page, $0)
            }
            if cfg.customSize {
                let w = cfg.width > 0 ? cfg.width : state.expandedWidth
                let h = cfg.height > 0 ? cfg.height : state.expandedHeight
                sliderSizeRow(L("展开宽度"), value: w, range: min(140, w)...max(1600, w)) { state.setPageLayoutWidth(page, $0) }
                sliderSizeRow(L("展开高度"), value: h, range: min(80, h)...max(1000, h)) { state.setPageLayoutHeight(page, $0) }
                Text(L("拖动滑块可逐像素微调"))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            }
            ForEach(blocks, id: \.id) { block in
                toggleRow(L("显示\(block.name)"), isOn: !cfg.hiddenBlocks.contains(block.id)) { on in
                    if on { state.showPageBlock(page, block.id) }
                    else { state.togglePageBlock(page, block.id) }
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
    }

    private func sliderRow(_ title: String, value: Double, onChange: @escaping (Double) -> Void) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 24, alignment: .leading)
            Slider(value: Binding(get: { value }, set: onChange), in: 0...1)
                .controlSize(.small)
            Text(String(format: "%d", Int(value * 255)))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func stepperRow(_ title: String, value: CGFloat, step: CGFloat, range: ClosedRange<CGFloat>, _ onChange: @escaping (CGFloat) -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Button("-") { onChange(max(range.lowerBound, value - step)) }
                .font(.system(size: 14, weight: .bold))
                .buttonStyle(PressBtn())
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 26, height: 22)
                .background(Circle().fill(Color.white.opacity(0.08)))
            Text(String(format: "%.1f", value))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(minWidth: 44, alignment: .trailing)
            Button("+") { onChange(min(range.upperBound, value + step)) }
                .font(.system(size: 14, weight: .bold))
                .buttonStyle(PressBtn())
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 26, height: 22)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
    }

    /// 精细尺寸行：拖动滑块逐像素调整（右侧实时显示整数值）
    private func sliderSizeRow(_ title: String, value: CGFloat, range: ClosedRange<CGFloat>, _ onChange: @escaping (CGFloat) -> Void) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 52, alignment: .leading)
            Slider(value: Binding(get: { Double(value) }, set: { onChange(CGFloat($0)) }),
                   in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                .controlSize(.small)
            Text("\(Int(value))")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .trailing)
                .monospacedDigit()
        }
    }
}

