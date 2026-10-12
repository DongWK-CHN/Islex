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

// MARK: - 根视图

struct NotchRootView: View {
    @ObservedObject var state: AppState

    private var w: CGFloat { state.isExpanded ? state.expandedWidth : state.compactWidth }
    private var h: CGFloat { state.isExpanded ? state.expandedHeight : state.compactHeight }
    private var r: CGFloat { state.isExpanded ? state.expandedRadius : state.compactRadius }

    private var compactScaleFactor: CGFloat {
        state.isExpanded ? 1.0 : state.appearanceCompactScale * (state.isHovering ? 1.04 : 1.0)
    }

    // 内容层固定按展开尺寸布局，过渡时只变遮罩，避免每帧重排整页。
    private var contentW: CGFloat { state.expandedWidth }
    private var contentH: CGFloat { state.expandedHeight }

    private var glassColors: [Color] {
        let isLight = state.appearanceTheme == 1
            || (state.appearanceTheme == 0 && NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .aqua)
        return isLight
            ? [Color.black.opacity(0.62), Color.black.opacity(0.76)]
            : [Color.black.opacity(0.72), Color.black.opacity(0.85)]
    }

    var body: some View {
        #if PERF
        let _ = PerfProbe.bodyEval("root")
        #endif
        ZStack(alignment: .top) {
            chromeLayer
            contentLayer
        }
        .frame(width: state.windowWidth, height: state.windowHeight, alignment: .top)
        .animation(.spring(response: 0.5, dampingFraction: 0.62), value: state.isHovering)
        .id(state.appearanceShape)
        .overlay(alignment: .top) { ToastLayer(state: state) }
        // 不要用无 value 的 .animation：任何状态变化都会触发动画重绘。
        .onValueChange(of: state.currentPage) { _ in
            (NSApp.delegate as? AppDelegate)?.repositionIsland()
        }
    }

    @ViewBuilder
    private var chromeLayer: some View {
        Group {
            if state.backgroundImageEnabled, let img = state.backgroundImage {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .clipShape(IslandShape(width: w, height: h, radius: r))
            } else if state.backgroundCustomEnabled {
                IslandShape(width: w, height: h, radius: r)
                    .fill(state.islandBackground)
            }
            IslandShape(width: w, height: h, radius: r)
                .fill(
                    LinearGradient(
                        colors: state.backgroundCustomEnabled
                            ? [state.islandBackground, state.islandBackground.opacity(0.82)]
                            : glassColors,
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    IslandShape(width: w, height: h, radius: r)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.03)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )

            if state.marqueeEnabled {
                MarqueeBorder(width: w, height: h, radius: r,
                              theme: state.marqueeTheme,
                              lite: state.isTransitioning,
                              cpuLinked: state.marqueeCpuLinked,
                              lowMemory: state.lowMemoryMode,
                              reduceMotion: state.reduceMotion)
            }

            if state.isExpanded && state.auroraEnabled && !state.isTransitioning && !state.reduceMotion {
                AuroraTexture(width: w, height: h, radius: r)
            }
        }
        .scaleEffect(compactScaleFactor, anchor: .top)
    }

    @ViewBuilder
    private var contentLayer: some View {
        Group {
            if state.isExpanded {
                ExpandedView(state: state)
                    .transition(.opacity)
            } else {
                CompactView(state: state)
                    .transition(.opacity)
                    .scaleEffect(compactScaleFactor, anchor: .top)
            }
        }
        .frame(width: contentW, height: contentH, alignment: .top)
        .clipShape(IslandShape(width: w, height: h, radius: r))
    }
}

// MARK: - 音量 / 亮度 HUD 胶囊（独立出来，可离屏渲染验证）

struct HudCapsule: View {
    let icon: String
    let value: Float
    var scale: CGFloat = 1
    var debugFlow: CGFloat? = nil

    var body: some View {
        HStack(spacing: 11 * scale) {
            sysImage(icon)
                .font(.system(size: tfs(17) * scale))
                .foregroundColor(.white.opacity(0.95))
                .frame(width: 24 * scale)
            FlowingBar(value: value, width: 176 * scale, height: 7 * scale, debugFlow: debugFlow)
        }
        .padding(.horizontal, 18 * scale)
        .padding(.vertical, 11 * scale)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.88), Color.black.opacity(0.78)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.06), Color.white.opacity(0.28)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 10, y: 3)
        .transition(.opacity)
        .allowsHitTesting(false)
    }
}

// MARK: - 瞬时提示层（音量/亮度 HUD、转换完成、快捷提示、OTA 横幅）

struct ToastLayer: View {
    @ObservedObject var state: AppState

    var body: some View {
        #if PERF
        let _ = PerfProbe.bodyEval("toast")
        #endif
        Group {
            if state.showConverterDone || state.quickMsg != nil || state.updateAvailable
                || state.volumeToastVisible || state.keyboardToastVisible {
                VStack(spacing: 6) {
                    if state.volumeToastVisible || state.keyboardToastVisible {
                        HudCapsule(
                            icon: state.volumeToastVisible
                                ? (state.volumeToastMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                : "keyboard",
                            value: state.volumeToastVisible ? state.volumeToastValue : state.keyboardToastValue,
                            scale: state.hudScale
                        )
                    }
                    if state.showConverterDone {
                        HStack(spacing: 4) {
                            sysImage("checkmark.circle.fill")
                                .font(.system(size: tfs(10)))
                                .foregroundColor(.green)
                            Text("转换完成")
                                .font(.system(size: tfs(9), weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.88)))
                        .overlay(Capsule().stroke(Color.green.opacity(0.5), lineWidth: 0.5))
                        .shadow(color: state.lowMemoryMode ? .clear : .green.opacity(0.3), radius: 5)
                        .transition(.opacity.combined(with: .scale(scale: 0.7)))
                        .allowsHitTesting(false)
                    }
                    if let msg = state.quickMsg {
                        HStack(spacing: 4) {
                            sysImage("exclamationmark.triangle.fill")
                                .font(.system(size: tfs(9)))
                                .foregroundColor(Color(red: 1.0, green: 0.72, blue: 0.35))
                            Text(msg)
                                .font(.system(size: tfs(9), weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.88)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.4), radius: 5)
                        .transition(.opacity.combined(with: .scale(scale: 0.7)))
                        .allowsHitTesting(false)
                    }
                    if state.updateAvailable {
                        HStack(spacing: 8) {
                            sysImage("arrow.down.circle.fill")
                                .font(.system(size: tfs(9)))
                                .foregroundColor(.green)
                            Text("发现新版本 v\(state.updateVersion)")
                                .font(.system(size: tfs(9), weight: .semibold))
                                .foregroundColor(.white)
                            if !state.updateNotes.isEmpty {
                                Text(state.updateNotes)
                                    .font(.system(size: tfs(7.5)))
                                    .foregroundColor(.white.opacity(0.5))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            Button {
                                Updater.openDownload()
                                state.updateVersion = ""
                            } label: {
                                Text("更新")
                                    .font(.system(size: tfs(8), weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 9).padding(.vertical, 2.5)
                                    .background(Capsule().fill(Color.white))
                            }
                            .buttonStyle(PressBtn())
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    state.updateVersion = ""
                                }
                            } label: {
                                sysImage("xmark")
                                    .font(.system(size: tfs(7), weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .buttonStyle(PressBtn())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.92)))
                        .overlay(Capsule().stroke(Color.green.opacity(0.4), lineWidth: 0.5))
                        .shadow(color: state.lowMemoryMode ? .clear : .green.opacity(0.25), radius: 5)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .offset(y: state.notchPadding + 10)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.quickMsg)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state.showConverterDone)
    }
}

// MARK: - 走马灯流光边框（独立刷新：旋转动画不再带动整窗重绘）

struct MarqueeBorder: View {
    let width: CGFloat
    let height: CGFloat
    let radius: CGFloat
    let theme: AppState.MarqueeTheme
    let lite: Bool
    let cpuLinked: Bool
    let lowMemory: Bool
    let reduceMotion: Bool

    @State private var rotation: Double = 0
    @State private var timer: Timer?
    @State private var origin: Double = ProcessInfo.processInfo.systemUptime

    private var outerColors: [Color] { theme.colors.map { $0.opacity(0.30) } }
    private var middleColors: [Color] { [theme.core.opacity(0.55), .white.opacity(0.9), theme.core.opacity(0.55)] }
    private var innerColors: [Color] { [theme.core.opacity(0.45), .white.opacity(0.95), theme.core.opacity(0.45)] }

    var body: some View {
        ZStack {
            if !lite {
                layer(outerColors, highlight: 0.55, spread: 0.34, angleOffset: 0, lineWidth: 5, blur: 5, opacity: 0.8)
                layer(middleColors, highlight: 0.53, spread: 0.16, angleOffset: 30, lineWidth: 3, blur: 2, opacity: 0.85)
            }
            layer(innerColors, highlight: 0.54, spread: 0.10, angleOffset: 60, lineWidth: 1.5, blur: 0.5, opacity: 0.95)
        }
        .onAppear { restart() }
        .onDisappear { timer?.invalidate(); timer = nil }
        .onValueChange(of: lowMemory) { _ in restart() }
        .onValueChange(of: cpuLinked) { _ in restart() }
        .onValueChange(of: reduceMotion) { _ in restart() }
    }

    private func layer(_ colors: [Color], highlight: Double, spread: Double, angleOffset: Double,
                       lineWidth: CGFloat, blur: CGFloat, opacity: Double) -> some View {
        IslandShape(width: width, height: height, radius: radius)
            .fill(
                AngularGradient(
                    gradient: Gradient(stops: AppState.marqueeStops(colors: colors, highlight: highlight, spread: spread)),
                    center: .center,
                    angle: .degrees(rotation + angleOffset)
                )
            )
            .mask(
                IslandShape(width: width, height: height, radius: radius)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth))
            )
            .blur(radius: blur)
            .opacity(opacity)
    }

    private func restart() {
        timer?.invalidate()
        timer = nil
        guard !reduceMotion else { rotation = 0; return }
        let interval: TimeInterval
        if lowMemory {
            interval = 0.15
        } else if cpuLinked {
            interval = 0.05
        } else {
            interval = 1.0 / 60.0
        }
        let dur = max(AppState.shared.marqueeEffectiveDuration, 0.2)
        origin = ProcessInfo.processInfo.systemUptime - rotation / 360.0 * dur
        let t = Timer(timeInterval: interval, repeats: true) { _ in
            let d = max(AppState.shared.marqueeEffectiveDuration, 0.2)
            let angle = (ProcessInfo.processInfo.systemUptime - origin) / d * 360.0
            rotation = angle.truncatingRemainder(dividingBy: 360)
        }
        t.tolerance = 0
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

// MARK: - 极光质感（独立刷新：不再以 20Hz 带动根视图整体重绘）

struct AuroraTexture: View {
    let width: CGFloat
    let height: CGFloat
    let radius: CGFloat

    @State private var phase: Double = 0
    @State private var timer: Timer?

    var body: some View {
        IslandShape(width: width, height: height, radius: radius)
            .fill(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.04),
                        Color.purple.opacity(0.02),
                        Color(red: 0.0, green: 0.8, blue: 0.8).opacity(0.04),
                        Color.blue.opacity(0.02),
                        Color.purple.opacity(0.04),
                    ]),
                    center: .center,
                    angle: .degrees(phase)
                )
            )
            .blur(radius: 12)
            .opacity(0.6)
            .allowsHitTesting(false)
            .onAppear {
                phase = 0
                let t = Timer(timeInterval: 0.05, repeats: true) { _ in
                    phase = (phase + 0.3).truncatingRemainder(dividingBy: 360)
                }
                RunLoop.main.add(t, forMode: .common)
                timer = t
            }
            .onDisappear { timer?.invalidate(); timer = nil }
    }
}

// MARK: - 实时时钟组件
/// DateFormatter 创建开销大，全局缓存避免反复创建
var fmtCache: [String: DateFormatter] = [:]
func cachedFormatter(_ format: String) -> DateFormatter {
    if let f = fmtCache[format] { return f }
    let f = DateFormatter()
    f.dateFormat = format
    fmtCache[format] = f
    return f
}

// 时钟单独刷新，避免每秒触发整个界面重绘。
struct RealtimeClockText: View {
    var format: String
    var font: Font
    var color: Color = .white
    @State private var now = Date()
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(cachedFormatter(format).string(from: now))
            .font(font)
            .foregroundColor(color)
            .onReceive(timer) { now = $0 }
    }
}

struct RealtimeDashboardClock: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private static let cnWeekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
    private static let cnMonths = ["一月", "二月", "三月", "四月", "五月", "六月",
                                   "七月", "八月", "九月", "十月", "十一月", "十二月"]

    var body: some View {
        VStack(spacing: 5) {
            Text(cachedFormatter("HH:mm").string(from: now))
                .font(.system(size: tfs(30), weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: AppState.shared.lowMemoryMode ? .clear : .white.opacity(0.15), radius: 6)
            Text(Self.cnMonths[Calendar.current.component(.month, from: now) - 1])
                .font(.system(size: tfs(10)))
                .foregroundColor(.white.opacity(0.45))
            Text("\(Calendar.current.component(.day, from: now))")
                .font(.system(size: tfs(26), weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(Self.cnWeekdays[Calendar.current.component(.weekday, from: now) - 1])
                .font(.system(size: tfs(10)))
                .foregroundColor(.white.opacity(0.45))
        }
        .onReceive(timer) { now = $0 }
    }
}

struct IslandShape: Shape {
    var width: CGFloat
    var height: CGFloat
    var radius: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(width, AnimatablePair(height, radius)) }
        set { width = newValue.first; height = newValue.second.first; radius = newValue.second.second }
    }

    func path(in rect: CGRect) -> Path {
        let w = min(width, rect.width)
        let h = min(height, rect.height)
        let x = (rect.width - w) / 2
        return Path(roundedRect: CGRect(x: x, y: 0, width: w, height: h), cornerRadius: radius)
    }
}

// MARK: - 收起态

struct CompactView: View {
    @ObservedObject var state: AppState

    var body: some View {
        let side = max((state.compactWidth - state.notchGap) / 2, 0)
        let inset = state.compactInset
        let narrow = side < 42 || state.appearanceShape == 1
        return Group {
            if narrow {
                HStack(spacing: 7) {
                    if state.pomodoroIsRunning {
                        sysImage(state.pomodoroPhase.icon)
                            .font(.system(size: tfs(8)))
                            .foregroundColor(state.pomodoroPhase.color)
                            .shadow(color: state.lowMemoryMode ? .clear : state.pomodoroPhase.color.opacity(0.6), radius: 3)
                        Text(state.pomodoroTimeDisplay)
                            .font(.system(size: tfs(9), weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    if state.nowPlaying.hasMedia && state.nowPlaying.isPlaying {
                        sysImage("speaker.wave.2.fill")
                            .font(.system(size: tfs(8)))
                            .foregroundColor(.white.opacity(0.6))
                        Text(state.nowPlaying.title.isEmpty ? "正在播放" : state.nowPlaying.title)
                            .font(.system(size: tfs(8), weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: state.appearanceShape == 1 ? 40 : 60, alignment: .leading)
                    } else if state.nowPlaying.hasMedia {
                        sysImage("speaker.slash.fill")
                            .font(.system(size: tfs(8)))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    if !(state.nowPlaying.hasMedia && state.nowPlaying.isPlaying) {
                        RealtimeClockText(format: "HH:mm", font: .system(size: tfs(12), weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    if state.pomodoroIsRunning {
                        sysImage(state.pomodoroPhase.icon)
                            .font(.system(size: tfs(9)))
                            .foregroundColor(state.pomodoroPhase.color)
                            .shadow(color: state.lowMemoryMode ? .clear : state.pomodoroPhase.color.opacity(0.6), radius: 3)
                        Text(state.pomodoroTimeDisplay)
                            .font(.system(size: tfs(11), weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else if state.nowPlaying.hasMedia && state.nowPlaying.isPlaying {
                        if let img = state.nowPlaying.artwork {
                            Image(nsImage: img).resizable().scaledToFill()
                                .frame(width: 18, height: 18).clipShape(RoundedRectangle(cornerRadius: rr(4)))
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        } else {
                            sysImage("music.note")
                                .font(.system(size: tfs(10)))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Text(state.nowPlaying.title.isEmpty ? "正在播放" : state.nowPlaying.title)
                            .font(.system(size: tfs(11), weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        EqualizerBars(playing: true).frame(width: 12, height: 8)
                    } else {
                        if state.nowPlaying.hasMedia {
                            sysImage("speaker.slash.fill")
                                .font(.system(size: tfs(8)))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        RealtimeClockText(format: "HH:mm", font: .system(size: tfs(13), weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: max(side - inset, 0), alignment: .leading)

                Color.clear.frame(width: state.notchGap)

                HStack(spacing: 3) {
                    if !state.droppedFiles.isEmpty {
                        sysImage("tray.full")
                            .font(.system(size: tfs(7)))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(state.droppedFiles.count)")
                            .font(.system(size: tfs(7), weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    sysImage("thermometer.medium")
                        .font(.system(size: tfs(8)))
                        .foregroundColor(state.cpuTempIndicatorColor)
                    Text(state.cpuTemp > 0 ? String(format: "%.0f°", state.cpuTemp) : "")
                        .font(.system(size: tfs(7), weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    sysImage(state.isCharging ? "bolt.fill" : "battery.100")
                        .font(.system(size: tfs(8)))
                        .foregroundColor(state.isCharging ? .green :
                            (state.batteryLevel <= 20 ? .red : .white.opacity(0.5)))
                    Text("\(state.batteryLevel)%")
                        .font(.system(size: tfs(7), weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                    if state.lidNoSleepEnabled {
                        sysImage("zzz")
                            .font(.system(size: tfs(8)))
                            .foregroundColor(.green)
                    }
                }
                .frame(width: max(side - inset, 0), alignment: .trailing)
                .contentShape(Rectangle())
                .onTapGesture {
                    state.withExpanded(true, resetPage: false)
                    state.currentPage = state.displayPosition(of: 6)
                }
            }
            }
        }
        .frame(width: state.compactWidth, height: state.compactHeight)
        .contentShape(Rectangle())
        .onTapGesture { state.withExpanded(true) }
        .onHover { hovering in
            state.setHovering(hovering)
        }
        .overlay(
            Group {
                if state.isDragTargeted {
                    IslandShape(width: state.compactWidth, height: state.compactHeight, radius: state.compactRadius)
                        .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
        )
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

// MARK: - 展开态（横扫切换页面）

struct ExpandedView: View {
    @ObservedObject var state: AppState

    private var pageTransition: AnyTransition {
        state.isTransitioning ? .opacity : .opacity.combined(with: .scale(scale: 0.97))
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: state.notchPadding)

            Group {
                switch state.visiblePages.indices.contains(state.currentPage) ? state.visiblePages[state.currentPage] : state.currentPage {
                case 0:
                    DashboardPageView(state: state)
                        .transition(pageTransition)
                case 1:
                    MediaPageView(state: state)
                        .transition(pageTransition)
                    case 2:
                        PomodoroPageView(state: state)
                            .transition(pageTransition)
                    case 3:
                        FileStationPageView(state: state)
                            .transition(pageTransition)
                    case 4:
                        AppLauncherPageView(state: state)
                            .transition(pageTransition)
                    case 5:
                        FileConverterPageView(state: state)
                            .transition(pageTransition)
                    case 6:
                        StatusPageView(state: state)
                            .transition(pageTransition)
                    case 7:
                        TodoListPageView(state: state)
                            .transition(pageTransition)
                    case 8:
                        WeatherPageView(state: state)
                            .transition(pageTransition)
                    case 9:
                        TeleprompterPageView(state: state)
                            .transition(pageTransition)
                    default:
                        DashboardPageView(state: state)
                            .transition(pageTransition)
                    }
                }
                .frame(width: state.pageContentWidth, height: state.contentHeight)
                .clipped()
                .padding(.horizontal, 12)
                .scaleEffect(state.currentPageStyleScale, anchor: .top)
                .animation(state.lowMemoryMode ? nil : .easeInOut(duration: 0.25), value: state.currentPage)

            PageIndicator(currentPage: state.currentPage, pageCount: state.visiblePageCount) { index in
                state.selectPage(index)
            }
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onHover { hovering in
            state.setHovering(hovering)
        }
    }
}

struct CompactInfoChips: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                sysImage("calendar").font(.system(size: tfs(8)))
                RealtimeClockText(format: "M/d", font: .system(size: tfs(9), weight: .medium))
            }
            .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 3) {
                sysImage(state.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: tfs(8)))
                    .foregroundColor(state.isCharging ? .green : (state.batteryLevel <= 20 ? .red : .white.opacity(0.7)))
                Text("\(state.batteryLevel)%").font(.system(size: tfs(9), weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

struct PageIndicator: View {
    let currentPage: Int
    let pageCount: Int
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<pageCount, id: \.self) { i in
                Button { onSelect(i) } label: {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: i == currentPage
                                    ? [Color.white.opacity(0.9), Color.white.opacity(0.5)]
                                    : [Color.white.opacity(0.25), Color.white.opacity(0.15)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: i == currentPage ? 20 : 6, height: 5)
                        .scaleEffect(i == currentPage ? 1.0 : 0.8)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: i == currentPage)
                }
                .buttonStyle(PressBtn())
            }
        }
        .padding(.horizontal, 2)
    }
}

struct FlowingBar: View {
    let value: Float
    var width: CGFloat = 100
    var height: CGFloat = 6
    var debugFlow: CGFloat? = nil
    @State private var displayed: CGFloat = 0

    private var target: CGFloat { width * CGFloat(min(max(value, 0), 1)) }

    var body: some View {
        #if PERF
        let _ = PerfProbe.bodyEval("hudBar")
        #endif
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.16))
            Capsule()
                .fill(LinearGradient(colors: [Color.white, Color.white.opacity(0.72)], startPoint: .leading, endPoint: .trailing))
                .frame(width: max(4, displayed))
                .overlay(FlowHighlight(width: width * 0.5, debugFlow: debugFlow))
                .clipShape(Capsule())
                .shadow(color: .white.opacity(0.4), radius: 2.5)
        }
        .frame(width: width, height: height)
        .clipShape(Capsule())
        .onAppear {
            displayed = target
        }
        .onChange(of: value) { _, _ in
            withAnimation(.easeOut(duration: 0.16)) { displayed = target }
        }
    }
}

struct FlowHighlight: View {
    let width: CGFloat
    var debugFlow: CGFloat? = nil
    @State private var flow: CGFloat = -0.45

    var body: some View {
        #if PERF
        let _ = PerfProbe.bodyEval("flow")
        #endif
        Capsule()
            .fill(LinearGradient(colors: [.clear, .white.opacity(0.9), .clear], startPoint: .leading, endPoint: .trailing))
            .frame(width: width)
            .offset(x: flow * width * 2)
            .onAppear {
                #if PERF
                PerfProbe.bodyEval("flowAppear")
                #endif
                if let f = debugFlow { flow = f; return }
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    flow = 1.8
                }
            }
    }
}
