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

// MARK: - 页面 6：格式转换器

struct FileConverterPageView: View {
    @ObservedObject var state: AppState

    private var typeLabel: String {
        guard let f = state.converterFile else { return "—" }
        switch AppState.converterType(for: f.url) {
        case .image: return "图片"
        case .audio: return "音频"
        case .text: return "文本"
        case .unsupported: return "不支持"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                sysImage("arrow.triangle.2.circlepath.doc")
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.white.opacity(0.5))
                Text(L("格式转换"))
                    .font(.system(size: tfs(10), weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }

            HStack(spacing: 8) {
                Button { state.pickConverterFile() } label: {
                    HStack(spacing: 4) {
                        sysImage("folder").font(.system(size: tfs(9)))
                        Text(L("选择文件")).font(.system(size: tfs(9), weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
                }
                .buttonStyle(PressBtn())

                if let f = state.converterFile {
                    HStack(spacing: 5) {
                        if let icon = f.icon {
                            Image(nsImage: icon).resizable().scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                        Text(f.name)
                            .font(.system(size: tfs(9)))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        Text("· \(typeLabel)")
                            .font(.system(size: tfs(8)))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(L("支持图片 / 音频 / 文本"))
                        .font(.system(size: tfs(9)))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !state.converterFormats.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("转换为"))
                        .font(.system(size: tfs(8)))
                        .foregroundColor(.white.opacity(0.35))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(state.converterFormats, id: \.self) { fmt in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        state.converterTarget = fmt
                                    }
                                } label: {
                                    Text(fmt)
                                        .font(.system(size: tfs(9), weight: .medium))
                                        .foregroundColor(state.converterTarget == fmt ? .white : .white.opacity(0.5))
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: state.converterTarget == fmt
                                                            ? [Color.blue.opacity(0.55), Color.blue.opacity(0.25)]
                                                            : [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                                                        startPoint: .top, endPoint: .bottom
                                                    )
                                                )
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    state.converterTarget == fmt
                                                        ? Color.blue.opacity(0.5)
                                                        : Color.white.opacity(0.08),
                                                    lineWidth: 0.5
                                                )
                                        )
                                }
                                .buttonStyle(PressBtn())
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            VStack(spacing: 5) {
                Button {
                    state.convertFile()
                } label: {
                    HStack(spacing: 6) {
                        if state.converterWorking {
                            ActivitySpinner().frame(width: 12, height: 12)
                        } else {
                            sysImage("arrow.right.doc.on.clipboard")
                                .font(.system(size: tfs(10), weight: .bold))
                        }
                        Text(state.converterWorking ? "转换中…" : "开始转换")
                            .font(.system(size: tfs(11), weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: rr(10))
                            .fill(
                                LinearGradient(
                                    colors: state.converterWorking || state.converterFile == nil || state.converterTarget.isEmpty
                                        ? [Color.white.opacity(0.08), Color.white.opacity(0.03)]
                                        : [Color.blue.opacity(0.55), Color.blue.opacity(0.25)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: rr(10))
                            .stroke(
                                (state.converterFile == nil || state.converterTarget.isEmpty)
                                    ? Color.white.opacity(0.05)
                                    : Color.blue.opacity(0.4),
                                lineWidth: 0.5
                            )
                    )
                    .opacity(state.converterFile == nil || state.converterTarget.isEmpty || state.converterWorking ? 0.6 : 1)
                }
                .buttonStyle(PressBtn())
                .disabled(state.converterWorking || state.converterFile == nil || state.converterTarget.isEmpty)

                HStack(spacing: 4) {
                    Circle()
                        .fill(
                            state.converterStatus.hasPrefix("转换完成")
                                ? Color.green.opacity(0.8)
                                : (state.converterStatus.hasPrefix("转换失败") || state.converterStatus.contains("不支持")
                                    ? Color.red.opacity(0.8)
                                    : (state.converterStatus == "正在转换…" ? Color.orange.opacity(0.8) : Color.white.opacity(0.3)))
                        )
                        .frame(width: 5, height: 5)
                    Text(state.converterStatus)
                        .font(.system(size: tfs(8)))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 6) {
                Button {
                    state.currentPage = state.displayPosition(of: 3)
                } label: {
                    HStack(spacing: 3) {
                        sysImage("tray").font(.system(size: tfs(8)))
                        Text("打开文件中转站").font(.system(size: tfs(8)))
                    }
                    .foregroundColor(.white.opacity(0.45))
                }
                .buttonStyle(PressBtn())
                Text("· 转换结果自动保存到中转站")
                    .font(.system(size: tfs(8)))
                    .foregroundColor(.white.opacity(0.2))
            }

            WidgetNavRow(state: state)
        }
        .padding(.vertical, 4)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - 页面 8：状态（硬件温度 / 合盖不休眠）

struct StatusPageView: View {
    @ObservedObject var state: AppState

    private var totalRAM: Double {
        Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024 / 1024
    }

    private var memoryUsageFraction: Double {
        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        let kr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0.5 }
        let used = Double(vmStats.active_count + vmStats.wire_count + vmStats.compressor_page_count)
        let total = Double(vmStats.active_count + vmStats.wire_count + vmStats.compressor_page_count + vmStats.inactive_count + vmStats.free_count + vmStats.speculative_count)
        guard total > 0 else { return 0.5 }
        return min(used / total, 1.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                sysImage("thermometer.medium")
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.white.opacity(0.5))
                Text(L("硬件状态"))
                    .font(.system(size: tfs(10), weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    metricCell(icon: "thermometer.medium",
                               value: state.cpuTemp > 0 ? String(format: "%.0f°C", state.cpuTemp) : state.thermalLevel,
                               color: state.cpuTempIndicatorColor, label: "CPU 温度")
                    metricCell(icon: "cpu",
                               value: String(format: "%.0f%%", state.cpuLoad * 100),
                               color: state.cpuLoad > 0.8 ? .red : (state.cpuLoad > 0.5 ? .orange : .green),
                               label: "CPU 使用率")
                }
                HStack(spacing: 4) {
                    metricCell(icon: "memorychip",
                               value: String(format: "%.1f GB", memoryUsageFraction * totalRAM),
                               color: memoryUsageFraction > 0.8 ? .red : (memoryUsageFraction > 0.6 ? .orange : .green),
                               label: "内存 \(Int(memoryUsageFraction * 100))%")
                    metricCell(icon: "battery.100",
                               value: "\(state.batteryLevel)%",
                               color: state.batteryLevel <= 20 ? .red : .white,
                               label: "电池")
                }
            }
            .padding(.vertical, 5).padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: rr(10))
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: rr(10))
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            )

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    sysImage("hammer.fill")
                        .font(.system(size: tfs(8)))
                        .foregroundColor(.white.opacity(0.4))
                    Text("AI 编码工具")
                        .font(.system(size: tfs(8), weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text("CPU / RAM · GPU 显示活跃")
                        .font(.system(size: tfs(6)))
                        .foregroundColor(.white.opacity(0.22))
                }
                HStack(spacing: 4) {
                    aiTile(icon: "hammer.fill", name: "Trae Code",
                           cpu: state.aiUsage["traecode"]?.cpu ?? 0,
                           ram: state.aiUsage["traecode"]?.ramMB ?? 0,
                           gpuActive: state.aiGpuActive["traecode"] ?? false,
                           running: state.aiTraeCodeRunning, installed: state.traeCodeInstalled) {
                        state.openTraeCode()
                    }
                    aiTile(icon: "sparkles", name: "Trae Work",
                           cpu: state.aiUsage["trae"]?.cpu ?? 0,
                           ram: state.aiUsage["trae"]?.ramMB ?? 0,
                           gpuActive: state.aiGpuActive["trae"] ?? false,
                           running: state.traeRunning, installed: state.traeWorkInstalled) {
                        state.openTraeWork()
                    }
                }
                HStack(spacing: 4) {
                    aiTile(icon: "briefcase.fill", name: "WorkBuddy",
                           cpu: state.aiUsage["workbuddy"]?.cpu ?? 0,
                           ram: state.aiUsage["workbuddy"]?.ramMB ?? 0,
                           gpuActive: state.aiGpuActive["workbuddy"] ?? false,
                           running: state.aiWorkbuddyRunning, installed: state.aiWorkbuddyInstalled) {
                        state.launchWorkBuddy()
                    }
                    aiTile(icon: "terminal.fill", name: "Claude Code",
                           cpu: state.aiUsage["claude"]?.cpu ?? 0,
                           ram: state.aiUsage["claude"]?.ramMB ?? 0,
                           gpuActive: state.aiGpuActive["claude"] ?? false,
                           running: state.aiClaudeRunning, installed: state.aiClaudeInstalled) {
                        if state.aiClaudeInstalled {
                            state.launchAICLI("claude")
                        } else if let u = URL(string: "https://claude.com/claude-code") {
                            NSWorkspace.shared.open(u)
                        }
                    }
                }
                HStack(spacing: 4) {
                    aiTile(icon: "chevron.left.forwardslash.chevron.right", name: "Codex",
                           cpu: state.aiUsage["codex"]?.cpu ?? 0,
                           ram: state.aiUsage["codex"]?.ramMB ?? 0,
                           gpuActive: state.aiGpuActive["codex"] ?? false,
                           running: state.aiCodexRunning, installed: state.aiCodexInstalled) {
                        if state.aiCodexInstalled {
                            state.launchAICLI("codex")
                        } else if let u = URL(string: "https://developers.openai.com/codex") {
                            NSWorkspace.shared.open(u)
                        }
                    }
                }
            }
            .padding(.vertical, 5).padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: rr(10))
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: rr(10))
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            )

            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(state.lidNoSleepEnabled ? 0.22 : 0.05))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.green.opacity(state.lidNoSleepEnabled ? 0.5 : 0.1), lineWidth: 1))
                    sysImage("zzz")
                        .font(.system(size: tfs(12)))
                        .foregroundColor(state.lidNoSleepEnabled ? .green : .white.opacity(0.35))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(L("合盖不休眠"))
                        .font(.system(size: tfs(9), weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text(state.lidNoSleepEnabled ? "已开启" : "已关闭")
                        .font(.system(size: tfs(8)))
                        .foregroundColor(state.lidNoSleepEnabled ? Color.green.opacity(0.8) : .white.opacity(0.35))
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        state.toggleLidNoSleep()
                    }
                } label: {
                    ZStack(alignment: state.lidNoSleepEnabled ? .trailing : .leading) {
                        Capsule()
                            .fill(state.lidNoSleepEnabled ? Color.green.opacity(0.55) : Color.white.opacity(0.15))
                            .frame(width: 34, height: 18)
                        Circle().fill(.white).frame(width: 14, height: 14).padding(2)
                    }
                }
                .buttonStyle(PressBtn())
            }
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: rr(10))
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: rr(10))
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            )

            Spacer()
            Text("温度与合盖状态也显示在收起态右侧小组件")
                .font(.system(size: tfs(7)))
                .foregroundColor(.white.opacity(0.25))
        }
        .padding(.vertical, 4)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func metricCell(icon: String, value: String, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            sysImage(icon)
                .font(.system(size: tfs(7)))
                .foregroundColor(color)
                .frame(width: 12)
            Text(label)
                .font(.system(size: tfs(7)))
                .foregroundColor(.white.opacity(0.45))
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: tfs(7.5), weight: .semibold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: rr(8))
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: rr(8))
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func aiTile(icon: String, name: String, cpu: Double, ram: Double,
                        gpuActive: Bool,
                        running: Bool, installed: Bool,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(running ? Color.green : (installed ? Color.white.opacity(0.35) : Color.white.opacity(0.2)))
                        .frame(width: 5, height: 5)
                        .shadow(color: running ? .green.opacity(0.7) : .clear, radius: 2)
                    sysImage(icon)
                        .font(.system(size: tfs(7.5)))
                        .foregroundColor(installed ? .white.opacity(0.7) : .white.opacity(0.3))
                    Text(name)
                        .font(.system(size: tfs(7.5), weight: .semibold))
                        .foregroundColor(installed ? .white.opacity(0.85) : .white.opacity(0.3))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(!installed ? "未安装" : (running ? "运行中" : "启动"))
                        .font(.system(size: tfs(6), weight: .medium))
                        .foregroundColor(running ? .green.opacity(0.9) : .white.opacity(0.3))
                        .lineLimit(1)
                }
                Text(metricLine(cpu: cpu, ram: ram, gpuActive: gpuActive, running: running, installed: installed))
                    .font(.system(size: tfs(6.5)))
                    .foregroundColor(.white.opacity(0.35))
                    .lineLimit(1)
            }
            .padding(.horizontal, 7).padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: rr(8))
                    .fill(running ? Color.white.opacity(0.07) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: rr(8))
                    .stroke(running ? Color.green.opacity(0.25) : Color.white.opacity(0.06), lineWidth: 0.5)
            )
        }
        .buttonStyle(PressBtn())
        .helpAny(!installed ? "未安装：点击前往官方安装" : (running ? "运行中：点击切换到它" : "启动 \(name)"))
    }

    private func metricLine(cpu: Double, ram: Double, gpuActive: Bool, running: Bool, installed: Bool) -> String {
        guard installed else { return "点击查看安装方式 · GPU —" }
        let ramText = ram > 0 ? String(format: "%.0fM", ram) : (running ? "…" : "—")
        let cpuText = running ? String(format: "CPU %.0f%%", min(cpu, 999)) : "CPU —"
        let gpuText = gpuActive ? "GPU 活跃" : "GPU —"
        return "\(cpuText) · RAM \(ramText) · \(gpuText)"
    }
}
