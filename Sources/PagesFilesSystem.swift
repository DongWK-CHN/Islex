import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers
import ImageIO
import ServiceManagement
import ApplicationServices
import CoreAudio
import IOKit
import Foundation

// MARK: - 页面 3：文件中转站

struct FileStationPageView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                sysImage("tray.full").font(.system(size: tfs(10))).foregroundColor(.white.opacity(0.5))
                Text("文件中转站").font(.system(size: tfs(10), weight: .semibold)).foregroundColor(.white.opacity(0.5))
                Spacer()
                if !state.droppedFiles.isEmpty {
                    Text("\(state.droppedFiles.count) 个 · \(state.formatFileSize(state.totalFileSize))")
                        .font(.system(size: tfs(8))).foregroundColor(.white.opacity(0.3))
                    Button { state.clearAllFiles() } label: {
                        sysImage("trash")
                            .font(.system(size: tfs(9)))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(PressBtn())
                }
            }

            if state.droppedFiles.isEmpty {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 44, height: 44)
                        sysImage("arrow.down.doc")
                            .font(.system(size: tfs(22))).foregroundColor(.white.opacity(0.25))
                    }
                    Text("拖放文件到此")
                        .font(.system(size: tfs(11), weight: .medium)).foregroundColor(.white.opacity(0.4))
                    Text("文件将复制到中转站")
                        .font(.system(size: tfs(9))).foregroundColor(.white.opacity(0.25))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: rr(10))
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        .foregroundColor(state.isDragTargeted ? .white.opacity(0.4) : .white.opacity(0.12))
                )
                .background(
                    RoundedRectangle(cornerRadius: rr(10))
                        .fill(
                            LinearGradient(
                                colors: state.isDragTargeted
                                    ? [Color.white.opacity(0.08), Color.white.opacity(0.03)]
                                    : [Color.white.opacity(0.02), Color.clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                )
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(state.droppedFiles) { file in
                            FileRow(state: state, file: file)
                        }
                        HStack(spacing: 4) {
                            sysImage("plus.circle.dashed").font(.system(size: tfs(9)))
                            Text("继续拖放添加").font(.system(size: tfs(9)))
                        }
                        .foregroundColor(.white.opacity(0.2))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: rr(10))
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        .foregroundColor(state.isDragTargeted ? .white.opacity(0.4) : .white.opacity(0.08))
                )
                .background(
                    RoundedRectangle(cornerRadius: rr(10))
                        .fill(
                            LinearGradient(
                                colors: state.isDragTargeted
                                    ? [Color.white.opacity(0.08), Color.white.opacity(0.03)]
                                    : [Color.white.opacity(0.02), Color.clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                )
            }
        }
        .padding(.vertical, 2)
        .fileDrop(targeted: $state.isDragTargeted) { providers in
            for provider in providers {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    var fileURL: URL?
                    if let data = item as? Data {
                        fileURL = URL(dataRepresentation: data, relativeTo: nil)
                    } else if let url = item as? URL {
                        fileURL = url
                    } else if let str = item as? String {
                        fileURL = URL(fileURLWithPath: str)
                    }
                    if let url = fileURL {
                        DispatchQueue.main.async {
                            AppState.shared.addFile(url)
                        }
                    }
                }
            }
            return true
        }
    }
}

struct FileRow: View {
    @ObservedObject var state: AppState
    let file: FileItem

    var body: some View {
        HStack(spacing: 8) {
            if let icon = file.icon {
                Image(nsImage: icon).resizable().scaledToFit().frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.2), radius: 2)
            } else {
                sysImage("doc").font(.system(size: tfs(14))).foregroundColor(.white.opacity(0.5))
                    .frame(width: 22, height: 22)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(file.name)
                    .font(.system(size: tfs(10), weight: .medium)).foregroundColor(.white)
                    .lineLimit(1)
                Text(state.formatFileSize(file.size))
                    .font(.system(size: tfs(8))).foregroundColor(.white.opacity(0.35))
            }
            Spacer(minLength: 0)

            Button { state.openFile(file) } label: {
                sysImage("arrow.up.forward.app").font(.system(size: tfs(9)))
                    .foregroundColor(.white.opacity(0.5)).frame(width: 18, height: 18)
            }
            .buttonStyle(PressBtn())

            Button {
                state.setConverterFileURL(file.url)
                state.currentPage = state.displayPosition(of: 5)
            } label: {
                sysImage("arrow.triangle.2.circlepath").font(.system(size: tfs(9)))
                    .foregroundColor(.white.opacity(0.5)).frame(width: 18, height: 18)
            }
            .buttonStyle(PressBtn())

            Button { state.removeFile(file) } label: {
                sysImage("xmark.circle.fill").font(.system(size: tfs(11)))
                    .foregroundColor(.red.opacity(0.7)).frame(width: 18, height: 18)
            }
            .buttonStyle(PressBtn())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: rr(6))
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
        )
    }
}

// MARK: - 页面 4：快捷应用

struct AppLauncherPageView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L("快捷应用")).font(.system(size: tfs(10), weight: .semibold)).foregroundColor(.white.opacity(0.5))
                Spacer()
                Button { state.editing.toggle() } label: {
                    sysImage(state.editing ? "checkmark.circle.fill" : "pencil")
                        .font(.system(size: tfs(11))).foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(PressBtn())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("快速添加（点击添加，再次点击直接启动）").font(.system(size: tfs(8))).foregroundColor(.white.opacity(0.35))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(state.quickPresets, id: \.scheme) { p in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    state.addPresetApp(p)
                                }
                            } label: {
                                VStack(spacing: 2) {
                                    sysImage(p.icon)
                                        .font(.system(size: tfs(14)))
                                        .foregroundColor(.white)
                                        .frame(width: 26, height: 26)
                                        .background(
                                            Circle().fill(
                                                LinearGradient(
                                                    colors: [Color.blue.opacity(0.45), Color.blue.opacity(0.2)],
                                                    startPoint: .top, endPoint: .bottom
                                                )
                                            )
                                        )
                                    Text(p.name)
                                        .font(.system(size: tfs(7)))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .frame(width: 40)
                            }
                            .buttonStyle(PressBtn())
                            .helpAny("添加 \(p.name)")
                        }
                        Button {
                            state.addCustomLinkViaDialog()
                        } label: {
                            VStack(spacing: 2) {
                                sysImage("link.badge.plus")
                                    .font(.system(size: tfs(14)))
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(
                                        Circle().fill(
                                            LinearGradient(
                                                colors: [Color.green.opacity(0.45), Color.green.opacity(0.2)],
                                                startPoint: .top, endPoint: .bottom
                                            )
                                        )
                                    )
                                Text("链接")
                                    .font(.system(size: tfs(7)))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(width: 40)
                        }
                        .buttonStyle(PressBtn())
                        .helpAny("添加自定义链接")
                    }
                    .padding(.vertical, 2)
                }
            }

            ScrollView(.vertical, showsIndicators: false) {
                let rows = stride(from: 0, to: state.apps.count, by: 5)
                    .map { Array(state.apps[$0..<min($0 + 5, state.apps.count)]) }
                VStack(spacing: 10) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 10) {
                            ForEach(row) { app in appCell(app) }
                        }
                    }
                    if state.editing {
                        HStack(spacing: 10) {
                            Button { state.addAppViaPanel() } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: rr(8))
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                        .foregroundColor(.white.opacity(0.2))
                                    sysImage("plus").font(.system(size: tfs(18), weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(width: 36, height: 36)
                            }
                            .buttonStyle(PressBtn())
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func appCell(_ app: AppShortcut) -> some View {
        ZStack(alignment: .topTrailing) {
            Button { state.launch(app) } label: {
                VStack(spacing: 4) {
                    if let img = app.iconImage {
                        Image(nsImage: img).resizable().scaledToFill()
                            .frame(width: 36, height: 36).clipped().cornerRadius(rr(8))
                            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: rr(8))
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                            sysImage(app.icon).font(.system(size: tfs(18)))
                                .foregroundColor(.white)
                        }
                        .frame(width: 36, height: 36)
                    }
                    Text(app.name)
                        .font(.system(size: tfs(8)))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .buttonStyle(LaunchBtn())
            .helpAny(app.name)

            if state.editing {
                Button { state.removeApp(app) } label: {
                    sysImage("minus.circle.fill")
                        .font(.system(size: tfs(14))).foregroundColor(.red)
                        .background(Circle().fill(Color.black))
                }
                .buttonStyle(PressBtn())
                .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - 页面 5：系统（合盖不休眠）

struct SystemPageView: View {
    @ObservedObject var state: AppState

    private var cpuTempColor: Color { state.cpuTempIndicatorColor }

    private var cpuTempText: String {
        state.cpuTemp > 0
            ? String(format: "%.0f°C", state.cpuTemp)
            : state.thermalLevel
    }

    private func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: rr(12))
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: rr(12))
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }

    private func toastToggleRow(title: String, icon: String, isOn: Bool, onToggle: @escaping (Bool) -> Void, caption: String) -> some View {
        VStack(spacing: 2) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onToggle(!isOn)
                }
            } label: {
                HStack(spacing: 8) {
                    sysImage(icon)
                        .font(.system(size: tfs(11)))
                        .foregroundColor(isOn ? .lgCyan : .white.opacity(0.3))
                    Text(title)
                        .font(.system(size: tfs(9)))
                        .foregroundColor(.white.opacity(0.7))
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
            Text(caption)
                .font(.system(size: tfs(7)))
                .foregroundColor(.white.opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 22)
        }
    }

    private func openNotificationsSettings() {
        let schemes = [
            "x-apple.systempreferences:com.apple.Notifications-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.notifications",
        ]
        for s in schemes {
            if let url = URL(string: s) {
                NSWorkspace.shared.open(url)
                return
            }
        }
    }

    private var suppressStatusText: String {
        if !state.volumeSuppressPermitted {
            return "未授权：请在 系统设置 → 隐私与安全性 → 辅助功能 勾选本应用，授权后自动生效（无需重启）"
        }
        if !state.volumeSuppressInstalled { return "正在安装拦截器…" }
        if !state.volumeSuppressEnabled { return "拦截器被系统暂停，正在恢复…" }
        return "已生效：按音量键系统动画不再出现（收到事件 \(state.volumeSuppressEvents) / 拦截 \(state.volumeSuppressCount)）"
    }

    private var suppressStatusColor: Color {
        if !state.volumeSuppressPermitted { return .orange }
        if !state.volumeSuppressInstalled || !state.volumeSuppressEnabled { return .yellow }
        return .green
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

    private func promptAccessibilityForVolumeSuppress() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限"
        alert.informativeText = "屏蔽系统音量动画需要「辅助功能」权限。\n请在 系统设置 → 隐私与安全性 → 辅助功能 中勾选 IsleX 灵屿，返回后自动生效（无需重启）。"
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                sysImage("laptopcomputer")
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.white.opacity(0.5))
                Text("系统")
                    .font(.system(size: tfs(10), weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 10) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [cpuTempColor.opacity(0.18), cpuTempColor.opacity(0.06)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 46, height: 46)
                            .overlay(
                                Circle()
                                    .stroke(cpuTempColor.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: cpuTempColor.opacity(0.3), radius: 5)
                        sysImage("thermometer.medium")
                            .font(.system(size: tfs(18), weight: .semibold))
                            .foregroundColor(cpuTempColor)
                    }

                    Text("温度监测")
                        .font(.system(size: tfs(9), weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))

                    Text(cpuTempText)
                        .font(.system(size: tfs(17), weight: .bold, design: .rounded))
                        .foregroundColor(cpuTempColor)
                        
                        .shadow(color: cpuTempColor.opacity(0.4), radius: 3)

                    VStack(spacing: 3) {
                        HStack {
                            Text("CPU 负载")
                                .font(.system(size: tfs(7)))
                                .foregroundColor(.white.opacity(0.3))
                            Spacer()
                            Text("\(Int(state.cpuLoad * 100))%")
                                .font(.system(size: tfs(7), weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                                
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.1))
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [cpuTempColor, cpuTempColor.opacity(0.5)],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(state.cpuLoad))
                                    .shadow(color: cpuTempColor.opacity(0.4), radius: 2)
                            }
                        }
                        .frame(height: 4)
                    }

                    if state.lidNoSleepEnabled {
                        HStack(spacing: 3) {
                            sysImage("zzz").font(.system(size: tfs(7)))
                            Text("保持唤醒中").font(.system(size: tfs(7), weight: .medium))
                        }
                        .foregroundColor(.green.opacity(0.85))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(cardBackground())

                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: state.lidNoSleepEnabled
                                        ? [Color.green.opacity(0.25), Color.green.opacity(0.1)]
                                        : [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .frame(width: 46, height: 46)
                            .overlay(
                                Circle()
                                    .stroke(
                                        state.lidNoSleepEnabled
                                            ? Color.green.opacity(0.5)
                                            : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                        sysImage("zzz")
                            .font(.system(size: tfs(17), weight: .semibold))
                            .foregroundColor(state.lidNoSleepEnabled ? .green : .white.opacity(0.3))
                    }

                    Text("合盖不休眠")
                        .font(.system(size: tfs(9), weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))

                    Text(state.lidNoSleepEnabled ? "保持唤醒中" : "已关闭")
                        .font(.system(size: tfs(17), weight: .bold, design: .rounded))
                        .foregroundColor(state.lidNoSleepEnabled ? .green : .white.opacity(0.4))
                        .shadow(color: state.lowMemoryMode ? .clear : (state.lidNoSleepEnabled ? .green.opacity(0.4) : .clear), radius: 3)

                    Text("合盖时系统保持唤醒，适合外接屏幕")
                        .font(.system(size: tfs(7)))
                        .foregroundColor(.white.opacity(0.3))
                        .multilineTextAlignment(.center)

                    if state.cpuTemp >= 80 || state.thermalLevel == "过高" {
                        HStack(spacing: 3) {
                            sysImage("thermometer.high").font(.system(size: tfs(7)))
                            Text("温度偏高").font(.system(size: tfs(7), weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                    }

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            state.toggleLidNoSleep()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            sysImage("power")
                                .font(.system(size: tfs(9), weight: .bold))
                            Text(state.lidNoSleepEnabled ? "关闭" : "开启")
                                .font(.system(size: tfs(10), weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: state.lidNoSleepEnabled
                                            ? [Color.red.opacity(0.6), Color.red.opacity(0.35)]
                                            : [Color.green.opacity(0.55), Color.green.opacity(0.3)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    (state.lidNoSleepEnabled ? Color.red : Color.green).opacity(0.4),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(
                            color: (state.lidNoSleepEnabled ? Color.red : Color.green).opacity(0.35),
                            radius: 5
                        )
                    }
                    .buttonStyle(PressBtn())
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .background(cardBackground())
            }

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    sysImage("bell.badge.fill")
                        .font(.system(size: tfs(10)))
                        .foregroundColor(.white.opacity(0.5))
                    Text("提示与通知")
                        .font(.system(size: tfs(10), weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                }

                toastToggleRow(title: "音量提示", icon: "speaker.wave.2.fill",
                               isOn: state.volumeToastEnabled,
                               onToggle: { state.setVolumeToastEnabled($0) },
                               caption: "调节音量时在灵动岛下方显示")
                VStack(spacing: 2) {
                    toastToggleRow(title: "屏蔽系统音量 HUD", icon: "speaker.slash.fill",
                                   isOn: state.volumeKeySuppressEnabled,
                                   onToggle: { v in
                                       state.setVolumeKeySuppressEnabled(v)
                                       if v && !state.volumeSuppressPermitted {
                                           promptAccessibilityForVolumeSuppress()
                                       }
                                   },
                                   caption: "拦截音量键，系统音量动画不再出现")
                    if state.volumeKeySuppressEnabled {
                        HStack(spacing: 4) {
                            Circle().fill(suppressStatusColor).frame(width: 5, height: 5)
                            Text(suppressStatusText)
                                .font(.system(size: tfs(7)))
                                .foregroundColor(.white.opacity(0.45))
                            Spacer()
                            if !state.volumeSuppressPermitted {
                                Button("前往授权") { promptAccessibilityForVolumeSuppress() }
                                    .font(.system(size: tfs(7)))
                                    .buttonStyle(PressBtn())
                                    .foregroundColor(.lgCyan)
                            } else {
                                Button("立即重装") { state.forceReinstallInterceptor() }
                                    .font(.system(size: tfs(7)))
                                    .buttonStyle(PressBtn())
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.leading, 22)
                    }
                }
                toastToggleRow(title: "耳机连接提示", icon: "airpodspro",
                               isOn: state.airPodsToastEnabled,
                               onToggle: { state.setAirPodsToastEnabled($0) },
                               caption: "耳机连接/断开时在灵动岛显示")

                Button { openNotificationsSettings() } label: {
                    HStack(spacing: 4) {
                        sysImage("bell.slash.fill").font(.system(size: tfs(8)))
                        Text("关闭系统横幅：系统设置 > 通知 > 蓝牙")
                            .font(.system(size: tfs(8)))
                    }
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                }
                .buttonStyle(PressBtn())
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(cardBackground())

            WidgetNavRow(state: state)

            Text("温度读取需 sudo 授权，未授权时显示热压力状态")
                .font(.system(size: tfs(7)))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(.vertical, 4)
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - 页面 9/8：待办事项

struct TodoListPageView: View {
    @ObservedObject var state: AppState
    @State private var newTodoText = ""
    @State private var selectedPriority: TodoPriority = .medium

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                sysImage("checklist").font(.system(size: tfs(10))).foregroundColor(.white.opacity(0.5))
                Text(L("待办事项")).font(.system(size: tfs(10), weight: .semibold)).foregroundColor(.white.opacity(0.5))
                Spacer()
                if !state.todoItems.isEmpty {
                    Text("\(state.todoItems.filter { !$0.isDone }.count) \(L("项未完成"))")
                        .font(.system(size: tfs(8))).foregroundColor(.white.opacity(0.3))
                    Button { state.clearDoneTodos() } label: {
                        sysImage("trash").font(.system(size: tfs(9))).foregroundColor(.white.opacity(0.4))
                    }.buttonStyle(PressBtn())
                }
            }

            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(TodoPriority.allCases, id: \.self) { p in
                        Button {
                            selectedPriority = p
                        } label: {
                            sysImage(p.icon)
                                .font(.system(size: tfs(9)))
                                .foregroundColor(selectedPriority == p ? p.color : .white.opacity(0.25))
                        }
                        .buttonStyle(PressBtn())
                    }
                }
                TextField(L("添加待办事项…"), text: $newTodoText)
                    .textFieldStyle(.plain)
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.white)
                Button {
                    addTodo()
                } label: {
                    sysImage("plus.circle.fill")
                        .font(.system(size: tfs(14)))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(PressBtn())
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: rr(6)).fill(Color.white.opacity(0.06)))

            if state.todoItems.isEmpty {
                VStack(spacing: 6) {
                    sysImage("checkmark.circle").font(.system(size: tfs(22))).foregroundColor(.white.opacity(0.15))
                    Text(L("暂无待办事项")).font(.system(size: tfs(10))).foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(state.todoItems) { item in
                            TodoRow(state: state, item: item)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    private func addTodo() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        state.addTodo(title: trimmed, priority: selectedPriority)
        newTodoText = ""
        selectedPriority = .medium
    }
}

struct TodoRow: View {
    @ObservedObject var state: AppState
    let item: TodoItem

    var body: some View {
        HStack(spacing: 6) {
            Button { state.toggleTodo(item.id) } label: {
                sysImage(item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: tfs(12)))
                    .foregroundColor(item.isDone ? .green : .white.opacity(0.35))
            }
            .buttonStyle(PressBtn())

            sysImage(item.priority.icon)
                .font(.system(size: tfs(8)))
                .foregroundColor(item.isDone ? .white.opacity(0.15) : item.priority.color)

            Text(item.title)
                .font(.system(size: tfs(10), weight: .medium))
                .foregroundColor(item.isDone ? .white.opacity(0.25) : .white)
                .strikethrough(item.isDone)
                .lineLimit(1)

            Spacer()

            Button { state.removeTodo(item.id) } label: {
                sysImage("xmark.circle.fill")
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.red.opacity(0.5))
            }
            .buttonStyle(PressBtn())
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: rr(5))
                .fill(Color.white.opacity(0.04))
        )
    }
}
