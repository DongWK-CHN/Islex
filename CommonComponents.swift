//  IsleX 灵屿 —— 通用组件（按钮样式/加载圈/均衡条等）
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

// MARK: - 通用组件

/// 系统加载圈（兼容 macOS 10.15，替代 SwiftUI ProgressView）
struct ActivitySpinner: NSViewRepresentable {
    func makeNSView(context: Context) -> NSProgressIndicator {
        let v = NSProgressIndicator()
        v.style = .spinning
        v.controlSize = .small
        v.startAnimation(nil)
        return v
    }
    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {}
}

/// 数值输入框（兼容 macOS 10.15，替代 SwiftUI TextField+FocusState，回车/失焦提交）
struct NumberField: NSViewRepresentable {
    let text: String
    let onCommit: (String) -> Void

    func makeNSView(context: Context) -> NSTextField {
        let f = NSTextField(string: text)
        f.isBordered = false
        f.drawsBackground = false
        f.alignment = .right
        f.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        f.textColor = .white
        f.focusRingType = .none
        f.target = context.coordinator
        f.action = #selector(Coordinator.commit(_:))
        f.delegate = context.coordinator
        return f
    }
    func updateNSView(_ v: NSTextField, context: Context) {
        if !context.coordinator.editing, v.stringValue != text {
            v.stringValue = text
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NumberField
        var editing = false
        init(_ p: NumberField) { parent = p }
        @objc func commit(_ sender: NSTextField) {
            editing = false
            parent.onCommit(sender.stringValue)
        }
        func controlTextDidBeginEditing(_ obj: Notification) { editing = true }
        func controlTextDidEndEditing(_ obj: Notification) {
            editing = false
            if let f = obj.object as? NSTextField {
                parent.onCommit(f.stringValue)
            }
        }
    }
}

struct MediaBtn: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(8)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [Color.white.opacity(0.3), Color.white.opacity(0.15)]
                                : [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.2 : 0.06), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct LaunchBtn: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: rr(8))
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [Color.white.opacity(0.2), Color.white.opacity(0.08)]
                                : [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: rr(8))
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.15 : 0.04), lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// 显示屏幕选择行：选择灵动岛定位到哪块显示器（「跟随主屏」为默认）
struct ScreenSelectorRow: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("显示屏幕")
                .font(.system(size: tfs(8.5), weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(Array(state.screenChoices.enumerated()), id: \.element.id) { _, c in
                        Button {
                            state.setScreenTarget(c.id)
                        } label: {
                            Text(c.name)
                                .font(.system(size: tfs(8), weight: .medium))
                                .lineLimit(1)
                                .foregroundColor(state.screenTarget == c.id ? .white : .white.opacity(0.6))
                                .padding(.horizontal, 9).padding(.vertical, 3.5)
                                .background(
                                    Capsule().fill(state.screenTarget == c.id ? Color.blue.opacity(0.45) : Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(PressBtn())
                    }
                }
            }
        }
    }
}

/// 通用按压反馈（替代 .plain）：无自带外观，按下时轻微缩小+变暗，给所有控件一致的点击反馈
struct PressBtn: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct EqualizerBars: View {
    let playing: Bool
    @State private var phase: CGFloat = 0
    @State private var animating = false
    private let heights: [CGFloat] = [0.4, 0.9, 0.55, 0.75]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.5)],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    .frame(width: 2.5, height: 12 * heights[i])
                    .scaleEffect(y: animating ? (0.4 + CGFloat(sin(Double(phase) + Double(i) * 0.8)) * 0.5 + 0.5) : 0.25, anchor: .bottom)
                    .animation(animating && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .easeOut(duration: 0.3), value: animating)
            }
        }
        .onAppear { startOrStop() }
        .onValueChange(of: playing) { _ in startOrStop() }
    }

    private func startOrStop() {
        // 减少动效开启时不播放均衡器动画（静止为低亮度状态）
        if playing && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            animating = true
            phase = .pi * 2
        } else {
            animating = false
            phase = 0
        }
    }
}

