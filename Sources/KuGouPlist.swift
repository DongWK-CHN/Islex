import AppKit
import Foundation

final class KuGouPlistPoller {
    static let shared = KuGouPlistPoller()
    static let bundleId = "com.kugou.mac.Music"

    private var state: AppState { AppState.shared }
    private var timer: Timer?
    private var running = false

    private var home: String { FileManager.default.homeDirectoryForCurrentUser.path }
    private var plistPath: String {
        "\(home)/Library/Containers/com.kugou.mac.Music/Data/Library/Preferences/userCurrentPlayList.plist"
    }
    private var klogDir: String {
        "\(home)/Library/Containers/com.kugou.mac.Music/Data/Library/Caches/kglogs"
    }

    private var lastElapsed = -1.0
    private var lastMtime: Date?
    private var lastTitle = ""
    private var lastArtist = ""
    private var isPlaying = false
    private var hasFirstSnapshot = false
    private var tickerElapsed = -1.0
    private var lastTickerDate = Date()
    private var lastPlayEventAt = Date.distantPast
    private var lastCoverURL = ""
    private var appliedCoverURL = ""
    private var fdaPrompted = false
    private var lastArbLog = Date.distantPast

    var isRunning: Bool { running }

    private init() {}

    func start() {
        guard !running else { return }
        running = true
        startupLog("酷狗音乐 plist 直连轮询启动")
        poll()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        running = false
        timer?.invalidate()
        timer = nil
    }

    // MARK: - 读取 plist

    private struct Snapshot { var title: String; var artist: String; var duration: Double; var elapsed: Double; var mtime: Date }

    private func readSnapshot() -> Snapshot? {
        let url = URL(fileURLWithPath: plistPath)
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let list = plist["userPlayList"] as? [Any] else { return nil }
        var song: [String: Any]?
        if list.count > 1, let d = list[1] as? [String: Any] { song = d }
        else if let arr = list.first as? [Any], let d = arr.first as? [String: Any] { song = d }
        guard let s = song,
              let rawTitle = s["musictitle"] as? String,
              !rawTitle.isEmpty else { return nil }
        let singer = (s["singerName"] as? String) ?? ""
        var title = rawTitle
        if !singer.isEmpty, rawTitle.hasPrefix(singer + " - ") {
            title = String(rawTitle.dropFirst(singer.count + 3))
        }
        let duration = (s["musicTime"] as? Double) ?? (s["musicTime"] as? Int).map(Double.init) ?? 0
        let total = (s["totalProgress"] as? Double) ?? 0
        let elapsed = (s["currentProgress"] as? Double) ?? 0
        let dur = duration > 0 ? duration : total
        let mtime = (try? FileManager.default.attributesOfItem(atPath: plistPath)[.modificationDate]) as? Date
        return Snapshot(title: title, artist: singer, duration: dur, elapsed: elapsed, mtime: mtime ?? Date())
    }

    // MARK: - 轮询

    private func poll() {
        guard running else { return }
        guard NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleId).first != nil else {
            if isPlaying {
                isPlaying = false
                var np = state.nowPlaying
                np.isPlaying = false
                np.rate = 0
                state.notePlaying(Self.bundleId, false)
                state.nowPlaying = np
            }
            return
        }
        guard let snap = readSnapshot() else {
            if !fdaPrompted {
                fdaPrompted = true
                let dockOK = (try? Data(contentsOf: URL(fileURLWithPath: "\(home)/Library/Preferences/com.apple.dock.plist"))) != nil
                let safariOK = (try? Data(contentsOf: URL(fileURLWithPath: "\(home)/Library/Safari/CloudTabs.db"))) != nil
                startupLog("酷狗 plist 读取失败：dock=\(dockOK) safari=\(safariOK) —— 需在 系统设置→隐私与安全性→完全磁盘访问 中开启 IsleX 后重启")
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                    NSWorkspace.shared.open(url)
                }
            }
            return
        }
        let now = Date()

        var newPlaying = isPlaying
        var correctedElapsed = snap.elapsed
        let klogActive = isKlogPlayingActive(within: 8)
        var realAdvance = false

        if !hasFirstSnapshot {
            hasFirstSnapshot = true
            newPlaying = klogActive
            correctedElapsed = snap.elapsed
            lastTitle = snap.title
            lastArtist = snap.artist
            tickerElapsed = snap.elapsed
            lastTickerDate = now
            if newPlaying { lastPlayEventAt = now }
            if newPlaying != isPlaying { startupLog("酷狗判定：首帧 klog播放信号=\(klogActive)") }
        } else if snap.title != lastTitle || snap.artist != lastArtist {
            newPlaying = true
            realAdvance = true
            correctedElapsed = snap.elapsed
            lastTitle = snap.title
            lastArtist = snap.artist
            tickerElapsed = snap.elapsed
            lastTickerDate = now
            lastPlayEventAt = now
            if newPlaying != isPlaying { startupLog("酷狗判定：切歌 \(snap.title)") }
        } else if snap.elapsed > lastElapsed + 0.5 {
            newPlaying = true
            realAdvance = true
            correctedElapsed = snap.elapsed
            tickerElapsed = snap.elapsed
            lastTickerDate = now
            lastPlayEventAt = now
            if newPlaying != isPlaying { startupLog("酷狗判定：进度前进 \(snap.elapsed)") }
        } else if snap.elapsed < lastElapsed - 2.0 {
            newPlaying = true
            realAdvance = true
            correctedElapsed = snap.elapsed
            tickerElapsed = snap.elapsed
            lastTickerDate = now
            lastPlayEventAt = now
            if newPlaying != isPlaying { startupLog("酷狗判定：进度回退 \(snap.elapsed)") }
        } else if snap.mtime != lastMtime && isPlaying {
            if Date().timeIntervalSince(lastPlayEventAt) < 5 {
            } else {
                newPlaying = false
                correctedElapsed = snap.elapsed
                tickerElapsed = snap.elapsed
                if newPlaying != isPlaying { startupLog("酷狗判定：plist 重写进度不变 → 暂停") }
            }
        }

        lastElapsed = snap.elapsed
        lastMtime = snap.mtime

        if newPlaying {
            let dt = now.timeIntervalSince(lastTickerDate)
            if dt > 0, dt < 5 {
                tickerElapsed += dt
            } else if dt >= 5 {
                tickerElapsed = snap.elapsed
                lastTickerDate = now
            }
            lastTickerDate = now
        }
        if newPlaying && tickerElapsed >= 0 && snap.duration > 0 && tickerElapsed >= snap.duration - 0.5 {
            tickerElapsed = snap.elapsed
            lastTickerDate = now
        }

        apply(title: snap.title, artist: snap.artist, duration: snap.duration, elapsed: newPlaying ? tickerElapsed : correctedElapsed, playing: newPlaying, realAdvance: realAdvance)
    }

    // MARK: - 应用到状态（与 AppleScript 源同一套多源仲裁）

    private func apply(title: String, artist: String, duration: Double, elapsed: Double, playing: Bool, realAdvance: Bool) {
        state.notePlaying(Self.bundleId, playing)
        let cur = state.nowPlayingApp
        if cur != Self.bundleId {
            if playing {
                if state.nowPlaying.isPlaying && state.startedLater(cur, than: Self.bundleId) { return }
                if !realAdvance && state.nowPlaying.isPlaying {
                    arbLog("酷狗仲裁：无真实进度信号，不抢占在播的 \(cur)")
                    return
                }
            } else {
                if state.nowPlaying.isPlaying { return }
                if !state.nowPlayingApp.isEmpty && state.playedNotLaterThan(Self.bundleId, than: cur) { return }
            }
        }
        var np = state.nowPlaying
        let songChanged = title != np.title || artist != np.artist || state.nowPlayingApp != Self.bundleId
        if songChanged {
            arbLog("酷狗仲裁：接管显示（\(playing ? "播放" : "暂停")）")
            np.title = title
            np.artist = artist
            np.album = ""
            np.artwork = nil
            state.nowPlayingApp = Self.bundleId
            fetchCoverIfNeeded(title: title)
        }
        if duration > 0 { np.duration = duration }
        if elapsed > np.elapsed + 0.3 || (songChanged && elapsed < np.elapsed - 2.0) {
            np.elapsed = elapsed
        }
        np.isPlaying = playing
        np.rate = playing ? 1 : 0
        if songChanged {
            startupLog("酷狗 plist 直连：\(title) - \(artist) 播放=\(playing)")
            state.nowPlaying = np
            state.fetchLyrics()
        } else {
            state.nowPlaying = np
        }
        isPlaying = playing
    }

    // MARK: - 封面（酷狗明文日志 union_cover）

    // 只看 .klog 尾部最近的 isPlaying:1；酷狗暂停时也会写心跳日志，mtime 不可靠。
    private func isKlogPlayingActive(within seconds: TimeInterval) -> Bool {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: klogDir) else { return false }
        let klogs = files.filter { $0.hasSuffix(".klog") }.sorted()
        guard let newest = klogs.last else { return false }
        let path = "\(klogDir)/\(newest)"
        guard let mtime = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate]) as? Date,
              Date().timeIntervalSince(mtime) < seconds else { return false }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return false }
        let s = String(decoding: data.suffix(16 * 1024), as: UTF8.self)
        return s.contains("isPlaying:1")
    }

    private func arbLog(_ msg: String) {
        guard Date().timeIntervalSince(lastArbLog) > 3 else { return }
        lastArbLog = Date()
        startupLog(msg)
    }

    private func fetchCoverIfNeeded(title: String) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            guard let url = self.extractCoverURL() else { return }
            let full = url.replacingOccurrences(of: "{size}", with: "400")
            guard full != self.appliedCoverURL,
                  let imgURL = URL(string: full),
                  let data = try? Data(contentsOf: imgURL, options: [.mappedIfSafe]),
                  let img = NSImage(data: data) else { return }
            self.appliedCoverURL = full
            DispatchQueue.main.async {
                self.state.applyArtwork(img, forTitle: title)
            }
        }
    }

    private func extractCoverURL() -> String? {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: klogDir) else { return nil }
        let klogs = files.filter { $0.hasSuffix(".klog") }.sorted()
        guard let newest = klogs.last else { return nil }
        let path = "\(klogDir)/\(newest)"
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let s = String(data: data, encoding: .utf8) else { return nil }
            return extractCover(from: s)
        }
        return extractCover(from: text)
    }

    private func extractCover(from text: String) -> String? {
        var found: String?
        for line in text.split(separator: "\n") {
            guard line.contains("union_cover") else { continue }
            let s = String(line)
            guard let range = s.range(of: #""(http[^"]+)""#, options: .regularExpression) else { continue }
            let url = String(s[range].dropFirst().dropLast())
            if url.contains("kugou.com") { found = url }
        }
        return found
    }
}
