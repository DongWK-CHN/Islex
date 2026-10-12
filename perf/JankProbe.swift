import AppKit
import Foundation
import SwiftUI

final class PerfProbe: NSObject {
    static func install() { _ = PerfProbe.shared }
    private static let shared = PerfProbe()

    private var samples: [String: [Double]] = [:]
    private var stallLog: [(Double, Double)] = []
    private var phase = "warmup"
    private var phaseEndsAt: CFTimeInterval = 0
    private var transitionWorst: [Double] = []
    private var currentWorst: Double = 0
    private var transitionStart: CFTimeInterval = 0
    private var stepIndex = 0
    private var cycle = 0
    private let totalCycles = 5

    private let probeQueue = DispatchQueue(label: "perf.latency", qos: .userInitiated)
    private var src: DispatchSourceTimer?

    private var cpuAtStart: (Double, Double) = (0, 0)
    private var wallAtStart: CFTimeInterval = 0

    private var bodyCounts: [String: Int] = [:]
    static func bodyEval(_ name: String) { shared.bodyCounts[name, default: 0] += 1 }

    private var notes: [(Double, String, Double)] = []
    private let notesStart = CACurrentMediaTime()
    static func note(_ tag: String, _ value: Double) {
        shared.notes.append((CACurrentMediaTime() - shared.notesStart, tag, value))
        if shared.notes.count > 4000 { shared.notes.removeFirst(2000) }
    }
    private func bodyCount(_ name: String) -> Int { bodyCounts[name] ?? 0 }

    private override init() {
        super.init()
        startLatencyProbe()
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] t in
            guard let self = self else { return }
            self.dismissSheets()
            guard let win = NSApp.windows.first(where: { $0.contentView != nil && $0.frame.height > 80 }) else { return }
            t.invalidate()
            print("[perf] winid=\(win.windowNumber) frame=\(Int(win.frame.width))x\(Int(win.frame.height))")
            print("[perf] window ready, warmup 2.5s")
            let mode = ProcessInfo.processInfo.environment["PERF_MODE"] ?? "cycles"
            self.schedule(after: 2.5) {
                if mode == "volume" {
                    self.startVolumeScript(media: false)
                } else if mode == "volumemedia" {
                    self.startVolumeScript(media: true)
                } else if mode == "mediapage" {
                    self.startMediaPageScript()
                } else if mode == "hudrender" {
                    self.renderHudFrames()
                } else {
                    self.startCycles()
                }
            }
        }
        Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { [weak self] _ in self?.finish() }
    }

    private func dismissSheets() {
        for w in NSApp.windows {
            for s in w.sheets { s.sheetParent?.endSheet(s) }
        }
    }

    private func startLatencyProbe() {
        let t = DispatchSource.makeTimerSource(queue: probeQueue)
        t.schedule(deadline: .now() + .milliseconds(500), repeating: .milliseconds(8), leeway: .milliseconds(1))
        t.setEventHandler { [weak self] in
            let sent = CACurrentMediaTime()
            DispatchQueue.main.async {
                guard let self = self else { return }
                let now = CACurrentMediaTime()
                let dt = (now - sent) * 1000.0
                self.samples[self.phase, default: []].append(dt)
                if self.phase == "transition" { self.stallLog.append((now - self.transitionStart, dt)) }
                if dt > self.currentWorst { self.currentWorst = dt }
            }
        }
        t.resume()
        src = t
    }

    private func schedule(after: TimeInterval, _ body: @escaping () -> Void) {
        let ids = DispatchTime.now() + after
        DispatchQueue.main.asyncAfter(deadline: ids, execute: body)
    }

    private func enter(_ name: String, _ duration: TimeInterval) {
        if phase == "transition" {
            transitionWorst.append(currentWorst)
            print("[perf] cycle=\(cycle) transition worst stall=\(fmt(currentWorst))ms")
        }
        phase = name
        currentWorst = 0
        if name == "transition" { transitionStart = CACurrentMediaTime() }
        phaseEndsAt = CACurrentMediaTime() + duration
    }

    private func startCycles() {
        let ru = rusageSelf()
        cpuAtStart = ru
        wallAtStart = CACurrentMediaTime()
        print("[perf] start cycles: cpu user=\(fmt(ru.0)) sys=\(fmt(ru.1))")
        nextStep()
    }

    private func nextStep() {
        switch stepIndex % 4 {
        case 0:
            AppState.shared.withExpanded(true)
            enter("transition", 0.9)
            schedule(after: 0.9) { self.stepIndex += 1; self.nextStep() }
        case 1:
            enter("expandedIdle", 1.6)
            schedule(after: 1.6) { self.stepIndex += 1; self.nextStep() }
        case 2:
            AppState.shared.withExpanded(false)
            enter("transition", 0.9)
            schedule(after: 0.9) { self.stepIndex += 1; self.nextStep() }
        default:
            enter("collapsedIdle", 1.0)
            cycle += 1
            schedule(after: 1.0) {
                self.stepIndex += 1
                if self.cycle >= self.totalCycles { self.finish() } else { self.nextStep() }
            }
        }
    }

    private func startVolumeScript(media: Bool) {
        let ru = rusageSelf()
        cpuAtStart = ru
        wallAtStart = CACurrentMediaTime()
        let original = AppState.shared.systemVolume
        print("[perf] volume script start: original=\(original) media=\(media) cpu user=\(fmt(ru.0))")
        if media {
            AppState.shared.toggleMockMedia()
            print("[perf] mock media on: isPlaying=\(AppState.shared.nowPlaying.isPlaying) title=\(AppState.shared.nowPlaying.title)")
        }
        enter("hudIdleBefore", 1.5)
        schedule(after: 1.5) {
            print("[perf] HUD 常显（流光动画运行）")
            AppState.shared.showVolumeToast(value: 0.5, muted: false)
            self.enter("hudAnimating", 2.5)
            self.schedule(after: 2.5) {
                print("[perf] 模拟按住音量键：100ms/次 × 30")
                self.enter("hudKeyRepeat", 3.2)
                self.repeatVolumeKey(30, 0, original)
            }
        }
    }

    private func startMediaPageScript() {
        let ru = rusageSelf()
        cpuAtStart = ru
        wallAtStart = CACurrentMediaTime()
        let original = AppState.shared.systemVolume
        AppState.shared.toggleMockMedia()
        AppState.shared.withExpanded(true)
        AppState.shared.currentPage = AppState.shared.displayPosition(of: 1)
        print("[perf] 媒体页展开 + 模拟播放：page=\(AppState.shared.currentPage) expanded=\(AppState.shared.isExpanded)")
        enter("pageIdle", 2.5)
        schedule(after: 2.5) {
            AppState.shared.showVolumeToast(value: 0.5, muted: false)
            self.enter("pageHudAnimating", 2.5)
            self.schedule(after: 2.5) {
                print("[perf] 模拟按住音量键：100ms/次 × 30")
                self.enter("pageHudKeyRepeat", 3.2)
                self.repeatVolumeKey(30, 0, original)
            }
        }
    }

    private func renderHudFrames() {
#if !HUD_NO_RENDER
        if #available(macOS 14.0, *) {
            MainActor.assumeIsolated {
                let dir = ProcessInfo.processInfo.environment["PERF_SHOT_DIR"] ?? "perf/results/hudrender"
                try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
                let flows: [CGFloat] = [-0.45, 0.0, 0.45, 0.9, 1.35, 1.8]
                for (i, f) in flows.enumerated() {
                    let view = ZStack {
                        Color(red: 0.07, green: 0.07, blue: 0.09)
                        HudCapsule(icon: "speaker.wave.2.fill", value: 0.62, debugFlow: f)
                    }
                    .frame(width: 330, height: 80)
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 2
                    if let cg = renderer.cgImage,
                       let rep = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) {
                        let url = URL(fileURLWithPath: dir).appendingPathComponent(String(format: "hud-%02d.png", i))
                        try? rep.write(to: url)
                        print("[perf] frame flow=\(f) -> \(url.lastPathComponent)")
                    }
                }
                print("[perf] hud frames: \(dir)")
            }
        } else {
            print("[perf] hudrender 需要 macOS 14+")
        }
#endif
        schedule(after: 0.3) { self.finish() }
    }

    private var volumeKeyDirection: String {
        ProcessInfo.processInfo.environment["PERF_VOL_DIR"] ?? "up"
    }

    private func repeatVolumeKey(_ times: Int, _ index: Int, _ original: Float) {
        guard index < times else {
            AppState.shared.setSystemVolume(original)
            print("[perf] 音量已还原为 \(original)")
            schedule(after: 0.8) {
                AppState.shared.withExpanded(false)
                if AppState.shared.mockMediaEnabled { AppState.shared.toggleMockMedia() }
                self.finish()
            }
            return
        }
        let code: Int
        switch volumeKeyDirection {
        case "down": code = 1
        case "alt": code = index % 2 == 0 ? 0 : 1
        default: code = 0
        }
        AppState.shared.handleVolumeKey(code)
        schedule(after: 0.1) { self.repeatVolumeKey(times, index + 1, original) }
    }

    private func finish() {
        src?.cancel()
        if phase == "transition" { transitionWorst.append(currentWorst); currentWorst = 0 }
        let ru = rusageSelf()
        let wall = CACurrentMediaTime() - wallAtStart
        let cpu = (ru.0 - cpuAtStart.0) + (ru.1 - cpuAtStart.1)
        for key in ["transition", "expandedIdle", "collapsedIdle",
                    "hudIdleBefore", "hudAnimating", "hudKeyRepeat",
                    "pageIdle", "pageHudAnimating", "pageHudKeyRepeat", "warmup"] {
            guard let v = samples[key], !v.isEmpty else { continue }
            let s = v.sorted()
            func q(_ p: Double) -> Double { s[min(s.count - 1, Int(Double(s.count - 1) * p))] }
            let over16 = v.filter { $0 > 16.7 }.count
            let over33 = v.filter { $0 > 33 }.count
            let over50 = v.filter { $0 > 50 }.count
            print("[perf] bucket=\(key) n=\(v.count) p50=\(fmt(q(0.5))) p95=\(fmt(q(0.95))) p99=\(fmt(q(0.99))) max=\(fmt(s.last!)) over16=\(over16) over33=\(over33) over50=\(over50)")
            if key == "transition" {
                let stalls = self.stallLog.sorted { $0.1 > $1.1 }.prefix(12)
                let detail = stalls.map { "t+\(Int($0.0 * 1000))ms:\(fmt($0.1))" }.joined(separator: " ")
                print("[perf] transition stalls (offset:ms) \(detail)")
                var hist = [Int: Int]()
                for (off, ms) in self.stallLog where ms > 16.7 { hist[Int(off / 0.2), default: 0] += 1 }
                print("[perf] transition stall hist (200ms bins): " + hist.keys.sorted().map { "bin\($0)=\(hist[$0]!)" }.joined(separator: " "))
            }
        }
        let worst = transitionWorst.max() ?? 0
        let avg = transitionWorst.isEmpty ? 0 : transitionWorst.reduce(0, +) / Double(transitionWorst.count)
        print("[perf] transitions=\(transitionWorst.count) perTransitionWorstAvg=\(fmt(avg)) perTransitionWorstMax=\(fmt(worst))")
        print("[perf] cpu total=\(fmt(cpu))s user=\(fmt(ru.0 - cpuAtStart.0))s sys=\(fmt(ru.1 - cpuAtStart.1))s wall=\(fmt(wall))s cycles=\(cycle)")
        let counts = bodyCounts.keys.sorted().map { "\($0)=\(bodyCounts[$0]!)" }.joined(separator: " ")
        print("[perf] view body evals: \(counts)")
        let volNotes = notes.filter { ["key", "set", "calib", "refresh", "mute"].contains($0.1) }
        print("[perf] vol trace n=\(volNotes.count)")
        for (t, tag, v) in volNotes {
            print(String(format: "[perf-vol] %.2f %@ %.4f", t, tag, v))
        }
        print("[perf] done")
        fflush(stdout)
        exit(0)
    }

    private func rusageSelf() -> (Double, Double) {
        var ru = rusage()
        getrusage(RUSAGE_SELF, &ru)
        func sec(_ t: timeval) -> Double { Double(t.tv_sec) + Double(t.tv_usec) / 1_000_000.0 }
        return (sec(ru.ru_utime), sec(ru.ru_stime))
    }

    private func fmt(_ v: Double) -> String { String(format: "%.1f", v) }
}
