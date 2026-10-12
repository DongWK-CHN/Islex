//  IsleX 灵屿 —— 页面：跑马灯 / 外观 / 小组件管理
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

// MARK: - 页面 8：跑马灯自定义

struct MarqueeSettingsPageView: View {
    @ObservedObject var state: AppState
    @State private var previewRotation: Double = 0

    private var theme: AppState.MarqueeTheme { state.marqueeTheme }

    var body: some View {
        ScrollView(showsIndicators: false) {
        VStack(spacing: 10) {
            // 标题
            HStack(spacing: 4) {
                sysImage("sparkles")
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.white.opacity(0.5))
                Text("跑马灯自定义")
                    .font(.system(size: tfs(10), weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }

            // 实时预览
            ZStack {
                RoundedRectangle(cornerRadius: rr(17))
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.75), Color.black.opacity(0.88)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                if state.marqueeEnabled {
                    // 外层
                    RoundedRectangle(cornerRadius: rr(17))
                        .fill(
                            AngularGradient(
                                gradient: Gradient(stops: AppState.marqueeStops(
                                    colors: theme.colors.map { $0.opacity(0.30) },
                                    highlight: 0.55, spread: 0.34
                                )),
                                center: .center,
                                angle: .degrees(previewRotation)
                            )
                        )
                        .mask(RoundedRectangle(cornerRadius: rr(17)).stroke(style: StrokeStyle(lineWidth: 5)))
                        .blur(radius: 5)
                        .opacity(0.8)
                    // 中层
                    RoundedRectangle(cornerRadius: rr(17))
                        .fill(
                            AngularGradient(
                                gradient: Gradient(stops: AppState.marqueeStops(
                                    colors: [theme.core.opacity(0.55), .white.opacity(0.9), theme.core.opacity(0.55)],
                                    highlight: 0.53, spread: 0.16
                                )),
                                center: .center,
                                angle: .degrees(previewRotation + 30)
                            )
                        )
                        .mask(RoundedRectangle(cornerRadius: rr(17)).stroke(style: StrokeStyle(lineWidth: 3)))
                        .blur(radius: 2)
                        .opacity(0.85)
                    // 内层
                    RoundedRectangle(cornerRadius: rr(17))
                        .fill(
                            AngularGradient(
                                gradient: Gradient(stops: AppState.marqueeStops(
                                    colors: [theme.core.opacity(0.45), .white.opacity(0.95), theme.core.opacity(0.45)],
                                    highlight: 0.54, spread: 0.10
                                )),
                                center: .center,
                                angle: .degrees(previewRotation + 60)
                            )
                        )
                        .mask(RoundedRectangle(cornerRadius: rr(17)).stroke(style: StrokeStyle(lineWidth: 1.5)))
                        .blur(radius: 0.5)
                        .opacity(0.95)
                }
            }
            .frame(width: 230, height: 34)
            .overlay(
                RoundedRectangle(cornerRadius: rr(17))
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: rr(17)))

            // 启用开关
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    state.setMarqueeEnabled(!state.marqueeEnabled)
                }
            } label: {
                HStack(spacing: 8) {
                    sysImage(state.marqueeEnabled ? "light.beacon.max" : "light.beacon.max")
                        .font(.system(size: tfs(10)))
                        .foregroundColor(state.marqueeEnabled ? .yellow : .white.opacity(0.3))
                    Text("启用流光跑马灯")
                        .font(.system(size: tfs(10), weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    // 胶囊开关
                    ZStack(alignment: state.marqueeEnabled ? .trailing : .leading) {
                        Capsule()
                            .fill(state.marqueeEnabled ? Color.green.opacity(0.55) : Color.white.opacity(0.15))
                            .frame(width: 34, height: 18)
                        Circle()
                            .fill(.white)
                            .frame(width: 14, height: 14)
                            .padding(2)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: rr(10))
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: rr(10))
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
            }
            .buttonStyle(PressBtn())

            // 颜色主题
            VStack(alignment: .leading, spacing: 6) {
                Text("颜色主题")
                    .font(.system(size: tfs(8)))
                    .foregroundColor(.white.opacity(0.35))
                HStack(spacing: 10) {
                    ForEach(0..<AppState.marqueeThemes.count, id: \.self) { i in
                        themeSwatch(index: i)
                    }
                }
            }

            // 速度
            VStack(alignment: .leading, spacing: 6) {
                Text("旋转速度")
                    .font(.system(size: tfs(8)))
                    .foregroundColor(.white.opacity(0.35))
                HStack(spacing: 6) {
                    speedChip("慢", 0)
                    speedChip("正常", 1)
                    speedChip("快", 2)
                }
            }

            // 随 CPU 负载加速
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    state.setMarqueeCpuLinked(!state.marqueeCpuLinked)
                }
            } label: {
                HStack(spacing: 8) {
                    sysImage("cpu")
                        .font(.system(size: tfs(10)))
                        .foregroundColor(state.marqueeCpuLinked ? .lgCyan : .white.opacity(0.3))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("随 CPU 负载加速")
                            .font(.system(size: tfs(10), weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                        Text("负载越高转速越快（1x ~ 3.5x）")
                            .font(.system(size: tfs(7)))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    Spacer(minLength: 0)
                    // 胶囊开关
                    ZStack(alignment: state.marqueeCpuLinked ? .trailing : .leading) {
                        Capsule()
                            .fill(state.marqueeCpuLinked ? Color.green.opacity(0.55) : Color.white.opacity(0.15))
                            .frame(width: 34, height: 18)
                        Circle().fill(.white).frame(width: 14, height: 14).padding(2)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: rr(10))
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: rr(10))
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
            }
            .buttonStyle(PressBtn())

            WidgetNavRow(state: state)
        }
        .padding(.vertical, 4)
        }
        .frame(maxHeight: .infinity)
        .onAppear { startPreview() }
        .onValueChange(of: state.marqueeSpeedIndex) { _ in startPreview() }
        .onValueChange(of: state.marqueeEnabled) { enabled in
            if enabled { startPreview() } else { previewRotation = 0 }
        }
    }

    private func startPreview() {
        guard state.marqueeEnabled else { previewRotation = 0; return }
        previewRotation = 0
        // 减少动效开启时预览静止
        if state.reduceMotion { return }
        withAnimation(.linear(duration: state.marqueeDuration).repeatForever(autoreverses: false)) {
            previewRotation = 360
        }
    }

    private func themeSwatch(index: Int) -> some View {
        let t = AppState.marqueeThemes[index]
        let selected = state.marqueeThemeIndex == index
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                state.setMarqueeTheme(index)
            }
        } label: {
            Circle()
                .fill(
                    LinearGradient(
                        colors: t.colors.count > 1 ? t.colors : [t.colors[0], t.colors[0].opacity(0.4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(
                            selected ? Color.white.opacity(0.9) : Color.white.opacity(0.15),
                            lineWidth: selected ? 2 : 1
                        )
                )
                .scaleEffect(selected ? 1.15 : 1.0)
                .shadow(color: selected ? .white.opacity(0.3) : .clear, radius: 4)
        }
        .buttonStyle(PressBtn())
        .helpAny(t.name)
    }

    private func speedChip(_ title: String, _ index: Int) -> some View {
        let selected = state.marqueeSpeedIndex == index
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                state.setMarqueeSpeed(index)
            }
        } label: {
            Text(title)
                .font(.system(size: tfs(9), weight: .medium))
                .foregroundColor(selected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 16).padding(.vertical, 5)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: selected
                                ? [Color.blue.opacity(0.55), Color.blue.opacity(0.25)]
                                : [Color.white.opacity(0.07), Color.white.opacity(0.03)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                )
                .overlay(
                    Capsule().stroke(
                        selected ? Color.blue.opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: 0.5
                    )
                )
        }
        .buttonStyle(PressBtn())
    }
}

// MARK: - 页面 9：外观设置（尺寸/位置/风格/主题）

struct AppearancePageView: View {
    @ObservedObject var state: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                // 标题
                HStack(spacing: 4) {
                    sysImage("paintbrush.pointed.fill")
                        .font(.system(size: tfs(10)))
                        .foregroundColor(.white.opacity(0.5))
                    Text("外观")
                        .font(.system(size: tfs(10), weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    // 恢复默认
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            state.resetAppearance()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            sysImage("arrow.counterclockwise").font(.system(size: tfs(8)))
                            Text("恢复默认").font(.system(size: tfs(8)))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(PressBtn())
                }

                // 尺寸
                settingsCard {
                    groupLabel("尺寸")
                    NumberStepperRow(title: "基础宽度", value: state.compactWidth, step: 1, minValue: 1, maxValue: 9999) { state.setAppearanceCompactWidth($0) }
                    NumberStepperRow(title: "基础高度", value: state.compactHeight, step: 1, minValue: 10, maxValue: 9999) { state.setAppearanceCompactHeight($0) }
                    NumberStepperRow(title: "展开宽度", value: state.expandedWidth, step: 1, minValue: 50, maxValue: 9999) { state.setAppearanceExpandedWidth($0) }
                    NumberStepperRow(title: "展开高度", value: state.expandedHeight, step: 1, minValue: 30, maxValue: 9999) { state.setAppearanceExpandedHeight($0) }
                    Text("点按 ± 逐像素微调")
                        .font(.system(size: tfs(7)))
                        .foregroundColor(.white.opacity(0.25))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 位置
                settingsCard {
                    groupLabel("位置")
                    NumberStepperRow(title: "水平偏移", value: state.appearanceOffsetX, step: 10, minValue: -9999, maxValue: 9999) { state.setAppearanceOffsetX($0) }
                    NumberStepperRow(title: "垂直偏移", value: state.appearanceOffsetY, step: 10, minValue: -9999, maxValue: 9999) { state.setAppearanceOffsetY($0) }
                }

                // 显示
                settingsCard {
                    groupLabel("显示")
                    NumberStepperRow(title: "展开缩放", value: state.appearanceScale, step: 0.1, minValue: 0.1, maxValue: 999, format: "%.1f") { state.setAppearanceScale($0) }
                    NumberStepperRow(title: "收起缩放", value: state.appearanceCompactScale, step: 0.1, minValue: 0.1, maxValue: 999, format: "%.1f") { state.setAppearanceCompactScale($0) }
                    NumberStepperRow(title: "字体大小", value: state.appearanceFontSize, step: 1, minValue: 9, maxValue: 18) { state.setAppearanceFontSize($0) }
                    NumberStepperRow(title: "HUD 大小", value: state.hudScale, step: 0.1, minValue: 0.7, maxValue: 1.5, format: "%.1f") { state.setHudScale($0) }
                    toggleRow("极光质感", icon: "sparkle", isOn: state.auroraEnabled) { state.setAuroraEnabled($0) }
                    Text("字体随灵动岛大小自动等比例缩放，此为基础字号微调")
                        .font(.system(size: tfs(7)))
                        .foregroundColor(.white.opacity(0.25))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 效果
                settingsCard {
                    groupLabel("效果")
                    chipRow("形态", options: ["自动", "悬浮胶囊"], selected: state.appearanceShape) {
                        state.setAppearanceShape($0)
                    }
                    chipRow("圆角风格", options: ["默认", "圆润", "方正"], selected: state.appearanceCornerStyle) {
                        state.setAppearanceCornerStyle($0)
                    }
                    chipRow("玻璃主题", options: ["跟随系统", "深色"], selected: state.appearanceTheme) {
                        state.setAppearanceTheme($0)
                    }
                    // 显示屏幕：选择灵动岛显示在哪块显示器（多屏场景）
                    ScreenSelectorRow(state: state)
                        .padding(.top, 2)
                }

                // 页面顺序
                settingsCard {
                    HStack {
                        groupLabel("页面顺序")
                        Spacer()
                        Button("恢复默认") { state.resetPageOrder() }
                            .font(.system(size: tfs(8)))
                            .foregroundColor(.white.opacity(0.5))
                            .buttonStyle(PressBtn())
                    }
                    ForEach(0..<state.pageOrder.count, id: \.self) { pos in
                        let page = state.pageOrder[pos]
                        pageOrderRow(name: state.displayName(of: page), pos: pos, page: page)
                    }
                }

                WidgetNavRow(state: state)
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: .infinity)
    }

    private func groupLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: tfs(8)))
            .foregroundColor(.white.opacity(0.35))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 6) {
            content()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: rr(10))
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: rr(10))
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    /// 数值调节行：支持 +/- 步进，也可直接键盘输入数值（回车或失焦生效）
    private struct NumberStepperRow: View {
        let title: String
        let value: CGFloat
        let step: CGFloat
        let minValue: CGFloat
        let maxValue: CGFloat
        var format: String = "%.0f"
        let onSet: (CGFloat) -> Void

        var body: some View {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: tfs(9)))
                    .foregroundColor(.white.opacity(0.6))
                Spacer(minLength: 0)
                Button { step(-step) } label: {
                    sysImage("minus.circle.fill")
                        .font(.system(size: tfs(12)))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(PressBtn())
                NumberField(text: String(format: format, value)) { raw in commit(raw) }
                    .frame(width: 52, height: 18)
                Button { step(step) } label: {
                    sysImage("plus.circle.fill")
                        .font(.system(size: tfs(12)))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(PressBtn())
            }
        }

        private func commit(_ raw: String) {
            guard let v = Double(raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "，", with: ".")) else { return }
            onSet(min(max(CGFloat(v), minValue), maxValue))
        }

        private func step(_ d: CGFloat) {
            onSet(min(max(value + d, minValue), maxValue))
        }
    }

    private func toggleRow(_ title: String, icon: String, isOn: Bool, onToggle: @escaping (Bool) -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onToggle(!isOn)
            }
        } label: {
            HStack(spacing: 8) {
                sysImage(icon)
                    .font(.system(size: tfs(10)))
                    .foregroundColor(isOn ? .lgCyan : .white.opacity(0.3))
                Text(title)
                    .font(.system(size: tfs(9)))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Color.green.opacity(0.55) : Color.white.opacity(0.15))
                        .frame(width: 34, height: 18)
                    Circle().fill(.white).frame(width: 14, height: 14).padding(2)
                }
            }
        }
        .buttonStyle(PressBtn())
    }

    private func pageOrderRow(name: String, pos: Int, page: Int) -> some View {
        HStack(spacing: 6) {
            Text("\(pos + 1)")
                .font(.system(size: tfs(8)))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 16, alignment: .trailing)
            Text(name)
                .font(.system(size: tfs(9)))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Button { state.movePageInOrder(page, up: true) } label: {
                sysImage("chevron.up")
                    .font(.system(size: tfs(8)))
                    .foregroundColor(pos == 0 ? .white.opacity(0.15) : .white.opacity(0.4))
            }
            .buttonStyle(PressBtn())
            .disabled(pos == 0)
            Button { state.movePageInOrder(page, up: false) } label: {
                sysImage("chevron.down")
                    .font(.system(size: tfs(8)))
                    .foregroundColor(pos == state.pageOrder.count - 1 ? .white.opacity(0.15) : .white.opacity(0.4))
            }
            .buttonStyle(PressBtn())
            .disabled(pos == state.pageOrder.count - 1)
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: rr(6)).fill(Color.white.opacity(0.04)))
    }

    private func chipRow(_ title: String, options: [String], selected: Int, onSelect: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: tfs(9)))
                .foregroundColor(.white.opacity(0.6))
            Spacer(minLength: 0)
            ForEach(options.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onSelect(i)
                    }
                } label: {
                    Text(options[i])
                        .font(.system(size: tfs(9), weight: .medium))
                        .foregroundColor(selected == i ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: selected == i
                                        ? [Color.blue.opacity(0.5), Color.blue.opacity(0.25)]
                                        : [Color.white.opacity(0.06), Color.white.opacity(0.04)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        )
                        .overlay(
                            Capsule().stroke(
                                selected == i ? Color.blue.opacity(0.4) : Color.white.opacity(0.08),
                                lineWidth: 0.5
                            )
                        )
                }
                .buttonStyle(PressBtn())
            }
        }
    }
}

// MARK: - 页面 12：小组件管理（显示/隐藏）

struct WidgetsManagePageView: View {
    @ObservedObject var state: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                // 标题
                HStack(spacing: 4) {
                    sysImage("square.grid.2x2")
                        .font(.system(size: tfs(10)))
                        .foregroundColor(.white.opacity(0.5))
                    Text(L("小组件"))
                        .font(.system(size: tfs(10), weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            state.showAllPages()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            sysImage("eye.fill").font(.system(size: tfs(8)))
                            Text(L("全部显示")).font(.system(size: tfs(8)))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(PressBtn())
                }

                VStack(spacing: 4) {
                    ForEach(0..<state.pageOrder.count, id: \.self) { pos in
                        let page = state.pageOrder[pos]
                        let fixed = (page == 0)
                        let hidden = state.hiddenPages.contains(page)
                        HStack(spacing: 8) {
                            Text("\(pos + 1)")
                                .font(.system(size: tfs(8)))
                                .foregroundColor(.white.opacity(0.3))
                                .frame(width: 16, alignment: .trailing)
                            Text(state.displayName(of: page))
                                .font(.system(size: tfs(9)))
                                .foregroundColor(hidden ? .white.opacity(0.35) : .white.opacity(0.7))
                            Spacer()
                            if fixed {
                                Text(L("固定"))
                                    .font(.system(size: tfs(7)))
                                    .foregroundColor(.white.opacity(0.25))
                            } else {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        state.togglePageHidden(page)
                                    }
                                } label: {
                                    ZStack(alignment: hidden ? .leading : .trailing) {
                                        Capsule()
                                            .fill(hidden ? Color.white.opacity(0.15) : Color.green.opacity(0.55))
                                            .frame(width: 34, height: 18)
                                        Circle().fill(.white).frame(width: 14, height: 14).padding(2)
                                    }
                                }
                                .buttonStyle(PressBtn())
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: rr(8)).fill(Color.white.opacity(0.04)))
                    }
                }

                Text("隐藏的小组件不出现在导航与切页循环中；仪表盘与提醒为固定项")
                    .font(.system(size: tfs(7)))
                    .foregroundColor(.white.opacity(0.25))
                    .frame(maxWidth: .infinity, alignment: .leading)

                WidgetNavRow(state: state)
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - 三个小组件导航关联

struct WidgetNavRow: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(spacing: 6) {
            if state.visiblePages.contains(2) { navChip(icon: "timer", title: L("专注"), page: 2) }
            if state.visiblePages.contains(5) { navChip(icon: "arrow.triangle.2.circlepath", title: L("格式转换"), page: 5) }
            if state.visiblePages.contains(6) { navChip(icon: "hammer.fill", title: L("硬件状态"), page: 6) }
            // 设置入口：打开菜单栏设置窗口（设置内容不占用灵动岛本体）
            Button {
                state.openSettings(tab: 0)
            } label: {
                        HStack(spacing: 3) {
                            sysImage("gearshape.fill").font(.system(size: tfs(8)))
                            Text(L("设置")).font(.system(size: tfs(8), weight: .medium))
                        }
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 9).padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
            }
            .buttonStyle(PressBtn())
        }
    }

    private func navChip(icon: String, title: String, page: Int) -> some View {
        let pos = state.displayPosition(of: page)
        let isActive = state.currentPage == pos
        return Button {
            state.currentPage = pos
        } label: {
            HStack(spacing: 3) {
                sysImage(icon).font(.system(size: tfs(8)))
                Text(title).font(.system(size: tfs(8), weight: .medium))
            }
            .foregroundColor(isActive ? .white : .white.opacity(0.5))
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: isActive
                            ? [Color.blue.opacity(0.45), Color.blue.opacity(0.2)]
                            : [Color.white.opacity(0.06), Color.white.opacity(0.04)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            )
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.blue.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(PressBtn())
    }
}

