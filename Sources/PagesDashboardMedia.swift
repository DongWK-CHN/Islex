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

// MARK: - 页面 0：仪表盘（时钟 + 日历 + 快捷控制）

struct CalendarCell {
    let day: Int
    let isCurrentMonth: Bool
    let isToday: Bool
}

struct CalendarData {
    let weekdays: [String] = ["日", "一", "二", "三", "四", "五", "六"]
    let cells: [CalendarCell]
    let monthLabel: String

    private static let cnMonths = ["一月", "二月", "三月", "四月", "五月", "六月",
                                   "七月", "八月", "九月", "十月", "十一月", "十二月"]

    static func current() -> CalendarData {
        let cal = Calendar.current
        let now = Date()
        guard let interval = cal.dateInterval(of: .month, for: now) else {
            return CalendarData(cells: [], monthLabel: "")
        }
        let firstDay = interval.start
        let firstWeekday = cal.component(.weekday, from: firstDay)
        let numDays = cal.range(of: .day, in: .month, for: now)!.count
        let today = cal.component(.day, from: now)
        let monthIdx = cal.component(.month, from: now) - 1

        let prevMonth = cal.date(byAdding: .month, value: -1, to: firstDay)!
        let prevNumDays = cal.range(of: .day, in: .month, for: prevMonth)!.count

        var cells: [CalendarCell] = []
        for i in stride(from: firstWeekday - 1, through: 0, by: -1) {
            cells.append(CalendarCell(day: prevNumDays - i, isCurrentMonth: false, isToday: false))
        }
        for d in 1...numDays {
            cells.append(CalendarCell(day: d, isCurrentMonth: true, isToday: d == today))
        }
        var nextDay = 1
        while cells.count % 7 != 0 {
            cells.append(CalendarCell(day: nextDay, isCurrentMonth: false, isToday: false))
            nextDay += 1
        }
        return CalendarData(cells: cells, monthLabel: cnMonths[monthIdx])
    }
}

struct CalendarView: View {
    let data: CalendarData

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 0) {
                ForEach(data.weekdays, id: \.self) { wd in
                    Text(wd)
                        .font(.system(size: tfs(9), weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                }
            }
            let rows = data.cells.count / 7
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let cell = data.cells[row * 7 + col]
                        Text("\(cell.day)")
                            .font(.system(size: tfs(10), weight: cell.isToday ? .bold : .regular))
                            .foregroundColor(cell.isToday ? .white :
                                (cell.isCurrentMonth ? .white.opacity(0.65) : .white.opacity(0.18)))
                            .frame(maxWidth: .infinity, minHeight: 16)
                            .background(
                                Group {
                                    if cell.isToday {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.08)],
                                                    startPoint: .top, endPoint: .bottom
                                                )
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                            )
                                    }
                                }
                            )
                    }
                }
            }
        }
    }
}

struct DashboardPageView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 3) {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Button { state.openSettings(tab: 0) } label: {
                    sysImage("gearshape")
                        .font(.system(size: tfs(14)))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(MediaBtn())
                .accessibilityLabel(L("设置"))

                Button {
                    state.pomodoroToggle()
                    if state.pomodoroIsRunning { state.currentPage = state.displayPosition(of: 2) }
                } label: {
                    VStack(spacing: 1) {
                        sysImage(state.pomodoroIsRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: tfs(11)))
                        Text(state.pomodoroIsRunning ? state.pomodoroTimeDisplay : L("开始"))
                            .font(.system(size: tfs(8), weight: .medium))
                    }
                    .foregroundColor(state.pomodoroPhase.color)
                    .frame(width: 30, height: 30)
                }
                .buttonStyle(MediaBtn())
                .accessibilityLabel(state.pomodoroIsRunning ? L("暂停") : L("开始"))

                VStack(spacing: 1) {
                    sysImage("clock.arrow.2.circlepath")
                        .font(.system(size: tfs(9)))
                        .foregroundColor(.white.opacity(0.35))
                    Text(state.systemUptime)
                        .font(.system(size: tfs(7)))
                        .foregroundColor(.white.opacity(0.3))
                }

                VStack(spacing: 1) {
                    sysImage("thermometer.medium")
                        .font(.system(size: tfs(10)))
                        .foregroundColor(state.cpuTempIndicatorColor)
                    Text(state.cpuTemp > 0 ? String(format: "%.0f°C", state.cpuTemp) : state.thermalLevel)
                        .font(.system(size: tfs(7)))
                        .foregroundColor(.white.opacity(0.35))
                }

                VStack(spacing: 1) {
                    sysImage(state.isCharging ? "bolt.fill" : "battery.100")
                        .font(.system(size: tfs(11)))
                        .foregroundColor(state.isCharging ? .green :
                            (state.batteryLevel <= 20 ? .red : .white.opacity(0.55)))
                        .shadow(color: state.lowMemoryMode ? .clear : (state.isCharging ? .green.opacity(0.4) : .clear), radius: 3)
                    Text("\(state.batteryLevel)%")
                        .font(.system(size: tfs(8)))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .frame(width: 72)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.02), Color.white.opacity(0.1), Color.white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 0.5)

            VStack(spacing: 5) {
                if state.appearanceShape == 1 { Spacer(minLength: 0) }
                RealtimeDashboardClock()

                Spacer(minLength: 0)

                if state.nowPlaying.hasMedia {
                    Button { state.currentPage = state.displayPosition(of: 1) } label: {
                        VStack(spacing: 2) {
                            HStack(spacing: 5) {
                                if let img = state.nowPlaying.artwork {
                                    Image(nsImage: img).resizable().scaledToFill()
                                        .frame(width: 16, height: 16).clipped().cornerRadius(rr(3))
                                        .shadow(color: .black.opacity(0.3), radius: 2)
                                } else {
                                    sysImage("music.note")
                                        .font(.system(size: tfs(9)))
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(width: 16, height: 16)
                                }
                                EqualizerBars(playing: state.nowPlaying.isPlaying).frame(width: 12, height: 9)
                            }
                            if !state.nowPlaying.title.isEmpty {
                                Text(state.nowPlaying.title)
                                    .font(.system(size: tfs(7)))
                                    .foregroundColor(.white.opacity(0.4))
                                    .lineLimit(1)
                                    .frame(maxWidth: 100)
                            }
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                        )
                    }
                    .buttonStyle(PressBtn())
                }
            }
            .frame(width: 124)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.02), Color.white.opacity(0.1), Color.white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 0.5)

            VStack(spacing: 6) {
                if state.appearanceShape == 1 { Spacer(minLength: 0) }
                CalendarView(data: data)
                    .padding(.horizontal, 8)

                Spacer(minLength: 0)

                if !state.droppedFiles.isEmpty {
                    Button { state.currentPage = state.displayPosition(of: 3) } label: {
                        HStack(spacing: 4) {
                            sysImage("tray.fill")
                                .font(.system(size: tfs(8)))
                            Text("\(state.droppedFiles.count) 个文件")
                                .font(.system(size: tfs(8)))
                            Spacer()
                            Text(formatFileSize(state.totalFileSize))
                                .font(.system(size: tfs(7)))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: rr(5)).fill(Color.white.opacity(0.05)))
                    }
                    .buttonStyle(PressBtn())
                }
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 0, maxHeight: .infinity)

        DashboardWeatherStrip(state: state)
            .padding(.horizontal, 2)
    }
    .padding(.vertical, 1)
    .onAppear { state.fetchWeather() }
}

    private var data: CalendarData { CalendarData.current() }

    private func formatFileSize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.0fKB", kb) }
        return String(format: "%.1fMB", kb / 1024)
    }
}

// MARK: - 页面 1：媒体（歌词 + SMTC 控制 + 封面）

struct MediaPageView: View {
    @ObservedObject var state: AppState
    @State private var scrubFraction: CGFloat?
    @State private var dragVolume: Float?

    private var displayFraction: CGFloat {
        if let s = scrubFraction { return s }
        guard state.nowPlaying.duration > 0 else { return 0 }
        return CGFloat(state.nowPlaying.elapsed / state.nowPlaying.duration)
    }

    private var displayVol: Float {
        if let d = dragVolume { return d }
        return state.systemVolume
    }

    private var volumeIcon: String {
        if state.systemMuted || state.systemVolume < 0.001 { return "speaker.slash.fill" }
        return state.systemVolume < 0.5 ? "speaker.fill" : "speaker.wave.3.fill"
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                if !state.nowPlaying.hasMedia && !state.mockMediaEnabled {
                    Button {
                        state.toggleMockMedia()
                    } label: {
                        HStack(spacing: 3) {
                            sysImage("play.rectangle.fill")
                                .font(.system(size: tfs(8)))
                            Text("Mock 播放")
                                .font(.system(size: tfs(8)))
                        }
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(PressBtn())
                    .helpAny("加载模拟媒体数据用于 UI 测试")
                }
                if state.mockMediaEnabled {
                    HStack(spacing: 3) {
                        Circle().fill(Color.green).frame(width: 5, height: 5)
                        Text("Mock").font(.system(size: tfs(8)))
                    }
                    .foregroundColor(.green.opacity(0.7))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
                    .onTapGesture { state.toggleMockMedia() }
                }
                Spacer()
            }
            if !state.isBlockHidden("artwork") {
                HStack(spacing: 10) {
                    ZStack {
                        if state.nowPlaying.artwork != nil {
                            RoundedRectangle(cornerRadius: rr(8))
                                .fill(Color.white.opacity(0.04))
                                .frame(width: 56, height: 56)
                                .blur(radius: 6)
                                .offset(x: 2, y: 2)
                        }
                        RoundedRectangle(cornerRadius: rr(8)).fill(Color.white.opacity(0.08))
                        if let img = state.nowPlaying.artwork {
                            Image(nsImage: img).resizable().scaledToFill()
                                .frame(width: 48, height: 48).clipped().cornerRadius(rr(8))
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        } else {
                            sysImage("music.note").font(.system(size: 17, weight: .semibold)).foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.nowPlaying.title.isEmpty ? "暂无播放" : state.nowPlaying.title)
                            .font(.system(size: tfs(12), weight: .semibold)).foregroundColor(.white)
                            .lineLimit(1)
                        Text(state.nowPlaying.artist.isEmpty ? "—" : state.nowPlaying.artist)
                            .font(.system(size: tfs(10))).foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                        if !state.nowPlayingApp.isEmpty {
                            HStack(spacing: 3) {
                                sysImage("app").font(.system(size: tfs(8)))
                                Text(state.nowPlayingApp).font(.system(size: tfs(9))).foregroundColor(.white.opacity(0.4))
                                if state.neteaseCDPConnected && state.nowPlayingApp == NeteaseCDPClient.bundleId {
                                    HStack(spacing: 2) {
                                        Circle().fill(Color.green).frame(width: 4, height: 4)
                                        Text(L("网易云直连")).font(.system(size: tfs(8))).foregroundColor(.green.opacity(0.8))
                                    }
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }

            if state.nowPlaying.duration > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.9), Color.white.opacity(0.5)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * displayFraction)
                            .shadow(color: .white.opacity(0.2), radius: 2)
                    }
                    .frame(height: 3)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                scrubFraction = min(max(v.location.x / max(geo.size.width, 1), 0), 1)
                            }
                            .onEnded { v in
                                let fraction = min(max(v.location.x / max(geo.size.width, 1), 0), 1)
                                state.seekMedia(to: state.nowPlaying.duration * fraction)
                                scrubFraction = nil
                            }
                    )
                }
                .frame(height: 20)
                HStack {
                    Text(fmt(scrubFraction != nil ? state.nowPlaying.duration * Double(scrubFraction!) : state.nowPlaying.elapsed))
                    Spacer()
                    Text(fmt(state.nowPlaying.duration))
                }
                .font(.system(size: tfs(9), weight: .medium)).foregroundColor(.white.opacity(0.45))
                
            }

            HStack(spacing: 24) {
                Button { state.sendCommand(MRCommand.previousTrack) } label: {
                    sysImage("backward.fill").font(.system(size: tfs(14)))
                }.buttonStyle(MediaBtn()).accessibilityLabel(L("上一首"))
                Button { state.sendCommand(MRCommand.togglePlayPause) } label: {
                    sysImage(state.nowPlaying.isPlaying ? "pause.fill" : "play.fill").font(.system(size: tfs(18)))
                }.buttonStyle(MediaBtn()).accessibilityLabel(L("播放/暂停"))
                Button { state.sendCommand(MRCommand.nextTrack) } label: {
                    sysImage("forward.fill").font(.system(size: tfs(14)))
                }.buttonStyle(MediaBtn()).accessibilityLabel(L("下一首"))
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                Button {
                    state.setSystemMute(!state.systemMuted)
                } label: {
                    sysImage(volumeIcon)
                        .font(.system(size: tfs(10)))
                        .foregroundColor(state.systemMuted ? .white.opacity(0.25) : .white.opacity(0.6))
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(PressBtn())
                .helpAny(state.systemMuted ? "取消静音" : "静音")

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: state.systemMuted
                                        ? [Color.white.opacity(0.3), Color.white.opacity(0.15)]
                                        : [Color.white.opacity(0.9), Color.white.opacity(0.5)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(displayVol))
                            .shadow(color: .white.opacity(0.2), radius: 2)
                    }
                    .frame(height: 3)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let f = Float(min(max(v.location.x / max(geo.size.width, 1), 0), 1))
                                dragVolume = f
                            }
                            .onEnded { v in
                                let f = Float(min(max(v.location.x / max(geo.size.width, 1), 0), 1))
                                state.setSystemVolume(f)
                                dragVolume = nil
                            }
                    )
                }
                .frame(height: 16)

                Text("\(Int((displayVol * 100).rounded()))%")
                    .font(.system(size: tfs(8), weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: 30, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)

            if !state.isBlockHidden("lyrics") {
                LyricView(state: state)
            }
        }
        .padding(.vertical, 4)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func fmt(_ s: Double) -> String {
        guard s.isFinite, s >= 0 else { return "0:00" }
        let m = Int(s) / 60, sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}

// MARK: - 歌词同步显示

struct LyricView: View {
    @ObservedObject var state: AppState

    var body: some View {
        Group {
            if !state.nowPlaying.hasMedia {
                Text("打开音乐应用即可显示")
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.white.opacity(0.25))
            } else if state.lyricState == .loading {
                HStack(spacing: 6) {
                    ActivitySpinner().frame(width: 12, height: 12)
                    Text("正在加载歌词…")
                }
                .font(.system(size: tfs(10)))
                .foregroundColor(.white.opacity(0.4))
            } else if state.nowPlaying.lyrics.isEmpty {
                Text(state.lyricState == .notFound ? "未找到歌词" : "纯音乐，暂无歌词")
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.white.opacity(0.35))
            } else {
                LyricScroller(state: state)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: rr(8))
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
    }
}

struct LyricScroller: View {
    @ObservedObject var state: AppState
    @State private var currentIndex = -1
    @State private var backoutWork: DispatchWorkItem?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) { lyricList }
                .id(state.nowPlaying.lyrics)
                .onAppear {
                    backoutWork?.cancel()
                    backoutWork = nil
                    let target = max(state.nowPlaying.currentLyricLine, 0)
                    currentIndex = target
                    proxy.scrollTo(target, anchor: .center)
                }
                .onValueChange(of: state.nowPlaying.currentLyricLine) { newIndex in
                    let target = max(newIndex, 0)
                    guard target != currentIndex else { return }
                    if target < currentIndex {
                        backoutWork?.cancel()
                        let idx = target
                        let work = DispatchWorkItem {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(idx, anchor: .center)
                            }
                            currentIndex = idx
                        }
                        backoutWork = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
                    } else {
                        backoutWork?.cancel()
                        backoutWork = nil
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                        currentIndex = target
                    }
                }
        }
    }

    private var lyricList: some View {
        VStack(spacing: 3) {
            ForEach(Array(state.nowPlaying.lyrics.enumerated()), id: \.element.id) { index, line in
                Text(line.text)
                    .font(.system(size: tfs(11), weight: index == currentIndex ? .semibold : .regular))
                    .foregroundColor(index == currentIndex ? .white : .white.opacity(0.35))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .id(index)
            }
        }
        .padding(.vertical, 19)
    }
}

// MARK: - 页面 2：番茄钟

struct PomodoroPageView: View {
    @ObservedObject var state: AppState
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: CGFloat = 0.3

    private var phaseDesc: String {
        switch state.pomodoroPhase {
        case .work: return "保持专注，拒绝干扰"
        case .shortBreak: return "放松片刻，喝杯水"
        case .longBreak: return "深度休息，恢复精力"
        }
    }

    private var nextPhase: String {
        switch state.pomodoroPhase {
        case .work:
            return state.pomodoroWorkCount % 4 == 3 ? "→ 长休息" : "→ 短休息"
        case .shortBreak, .longBreak:
            return "→ 专注"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                sysImage(state.pomodoroPhase.icon).font(.system(size: tfs(9)))
                Text(state.pomodoroPhase.rawValue)
                    .font(.system(size: tfs(10), weight: .semibold))
                Text(phaseDesc)
                    .font(.system(size: tfs(7.5)))
                    .foregroundColor(.white.opacity(0.35))
            }
            .foregroundColor(state.pomodoroPhase.color)
            .shadow(color: state.lowMemoryMode ? .clear : state.pomodoroPhase.color.opacity(0.3), radius: 3)

            ZStack {
                if state.pomodoroIsRunning {
                    Circle()
                        .fill(state.pomodoroPhase.color.opacity(pulseOpacity))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                        .blur(radius: 10)
                }

                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: state.pomodoroProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [state.pomodoroPhase.color, state.pomodoroPhase.color.opacity(0.4), state.pomodoroPhase.color]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: state.lowMemoryMode ? .clear : state.pomodoroPhase.color.opacity(0.5), radius: 4)

                VStack(spacing: 0) {
                    Text(state.pomodoroTimeDisplay)
                        .font(.system(size: tfs(24), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(nextPhase)
                        .font(.system(size: tfs(7)))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .onAppear { startPulse() }
            .onValueChange(of: state.pomodoroIsRunning) { _ in startPulse() }

            HStack(spacing: 20) {
                Button { state.pomodoroReset() } label: {
                    sysImage("arrow.counterclockwise").font(.system(size: tfs(12)))
                }.buttonStyle(MediaBtn()).accessibilityLabel(L("重置"))
                Button { state.pomodoroToggle() } label: {
                    ZStack {
                        Circle()
                            .fill(state.pomodoroPhase.color.opacity(0.2))
                            .frame(width: 42, height: 42)
                        sysImage(state.pomodoroIsRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: tfs(18)))
                            .foregroundColor(state.pomodoroPhase.color)
                    }
                }.buttonStyle(PressBtn())
                    .accessibilityLabel(state.pomodoroIsRunning ? L("暂停") : L("开始"))
                Button { state.pomodoroSkip() } label: {
                    sysImage("forward.fill").font(.system(size: tfs(12)))
                }.buttonStyle(MediaBtn()).accessibilityLabel(L("跳过"))
            }

            HStack(spacing: 12) {
                statCard(value: "\(state.todayPomodoroCount)", label: "完成", color: .orange, icon: "checkmark.circle")
                statCard(value: "\(state.todayFocusMinutes)", label: "专注分钟", color: .green, icon: "clock")
                statCard(value: "\(state.pomodoroWorkCount + 1)", label: "轮次", color: .blue, icon: "arrow.triangle.2.circlepath")
            }
        }
        .padding(.vertical, 4)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func statCard(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 3) {
            sysImage(icon)
                .font(.system(size: tfs(8)))
                .foregroundColor(color.opacity(0.7))
            Text(value)
                .font(.system(size: tfs(15), weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: tfs(7)))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: rr(8))
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: rr(8))
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func startPulse() {
        let rm = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if state.pomodoroIsRunning {
            if rm { pulseScale = 1.15; pulseOpacity = 0.1; return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
                pulseOpacity = 0.1
            }
        } else {
            if rm { pulseScale = 1.0; pulseOpacity = 0.3; return }
            withAnimation(.easeOut(duration: 0.3)) {
                pulseScale = 1.0
                pulseOpacity = 0.3
            }
        }
    }
}
