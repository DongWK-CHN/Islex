//  IsleX 灵屿 —— 酷狗音乐 plist 直连（真正的底层通道，无屏幕录制）
//  酷狗（Mac Catalyst）把「当前播放歌曲」实时写入容器内 userCurrentPlayList.plist：
//    ~/Library/Containers/com.kugou.mac.Music/Data/Library/Preferences/userCurrentPlayList.plist
//  字段（结构 userPlayList = [队列数组, 当前歌曲字典, "当前索引"]）：
//    musictitle   = "歌手 - 歌名"（需剥离 singerName 前缀）
//    singerName   = 歌手
//    musicTime    = 总时长（秒，整数）
//    totalProgress= 总时长（秒，浮点）
//    currentProgress = 当前进度（秒，浮点）—— 仅在播放状态变化/周期同步时写入
//  播放状态推断（plist 不持续写入进度）：
//    1) 切歌（title/artist 变化）→ 视为开始播放
//    2) 进度明显前进（>0.5s）→ 播放中
//    3) 文件重写但进度不变且此前在播 → 暂停
//  进度本地 ticker 推进（与 AppleScript 源同一套策略）。
//  封面：酷狗明文日志 .klog 里含 "union_cover" 图片 URL（同歌曲一起写入，切歌即更新）。

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

    // ---- 状态机 ----
    private var lastElapsed = -1.0
    private var lastMtime: Date?
    private var lastTitle = ""
    private var lastArtist = ""
    private var isPlaying = false
    private var hasFirstSnapshot = false
    private var tickerElapsed = -1.0
    private var lastTickerDate = Date()
    /// 最近一次判定「播放」的时间（用于暂停判定防抖：开始播放后的二次写入不误判暂停）
    private var lastPlayEventAt = Date.distantPast
    private var lastCoverURL = ""
    private var appliedCoverURL = ""
    /// 已提示过完全磁盘访问（避免每次启动都弹系统设置）
    private var fdaPrompted = false
    /// 仲裁日志节流（避免让位/接管日志刷屏）
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
        // 当前歌曲：userPlayList[1]（字典）或 userPlayList[0] 数组首项
        var song: [String: Any]?
        if list.count > 1, let d = list[1] as? [String: Any] { song = d }
        else if let arr = list.first as? [Any], let d = arr.first as? [String: Any] { song = d }
        guard let s = song,
              let rawTitle = s["musictitle"] as? String,
              !rawTitle.isEmpty else { return nil }
        let singer = (s["singerName"] as? String) ?? ""
        // musictitle 常为 "歌手 - 歌名"，剥离歌手前缀得到纯歌名
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
        // 酷狗未运行：标记暂停（若之前显示在播）
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
            // 文件存在但读不到 → TCC 限制（容器/磁盘访问）。诊断具体缺失项
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

        // ---- 播放状态推断（事件驱动：酷狗播放中不写文件，只有开始/切歌/暂停/拖动时 plist 更新）----
        var newPlaying = isPlaying
        var correctedElapsed = snap.elapsed
        // klog 播放信号：仅用于首帧判定（暂停时酷狗也写网络日志，不能只看 mtime）
        let klogActive = isKlogPlayingActive(within: 8)
        // 本轮是否有「真实播放信号」（切歌/进度移动）—— 仲裁防御用
        var realAdvance = false

        if !hasFirstSnapshot {
            // 首次读到：不当作切歌，是否在播由 klog 播放信号判定（避免启动时误判）
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
            // 切歌 = 播放事件（播放中切歌是常态；暂停中切歌由后续 plist 重写纠正）
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
            // 进度前进（恢复播放/拖动快进）= 播放事件
            newPlaying = true
            realAdvance = true
            correctedElapsed = snap.elapsed
            tickerElapsed = snap.elapsed
            lastTickerDate = now
            lastPlayEventAt = now
            if newPlaying != isPlaying { startupLog("酷狗判定：进度前进 \(snap.elapsed)") }
        } else if snap.elapsed < lastElapsed - 2.0 {
            // 进度回退（重播/跳转）= 播放事件
            newPlaying = true
            realAdvance = true
            correctedElapsed = snap.elapsed
            tickerElapsed = snap.elapsed
            lastTickerDate = now
            lastPlayEventAt = now
            if newPlaying != isPlaying { startupLog("酷狗判定：进度回退 \(snap.elapsed)") }
        } else if snap.mtime != lastMtime && isPlaying {
            // plist 重写但进度不变 = 暂停信号（判播放后 5 秒内的二次写入忽略，避免开始播放误判）
            if Date().timeIntervalSince(lastPlayEventAt) < 5 {
                // 保持播放（ticker 继续推进）
            } else {
                newPlaying = false
                correctedElapsed = snap.elapsed
                tickerElapsed = snap.elapsed
                if newPlaying != isPlaying { startupLog("酷狗判定：plist 重写进度不变 → 暂停") }
            }
        }
        // 无事件（文件静止）：保持状态，本地 ticker 推进

        lastElapsed = snap.elapsed
        lastMtime = snap.mtime

        // 本地 ticker：播放中按时间推进
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
            // 播完本曲：可能已切歌，回到文件快照
            tickerElapsed = snap.elapsed
            lastTickerDate = now
        }

        apply(title: snap.title, artist: snap.artist, duration: snap.duration, elapsed: newPlaying ? tickerElapsed : correctedElapsed, playing: newPlaying, realAdvance: realAdvance)
    }

    // MARK: - 应用到状态（与 AppleScript 源同一套多源仲裁）

    private func apply(title: String, artist: String, duration: Double, elapsed: Double, playing: Bool, realAdvance: Bool) {
        // 本地节流（不能用 AppState 的全局 lastNowPlayingUpdate：
        // AppleScript 轮询每 0.5s 刷新它，会饿死本源的写入）
        state.notePlaying(Self.bundleId, playing)
        let cur = state.nowPlayingApp
        if cur != Self.bundleId {
            if playing {
                if state.nowPlaying.isPlaying && state.startedLater(cur, than: Self.bundleId) { return }
                // 防御：本轮无真实进度信号（仅推断播放）且其它源在播 → 不抢占，避免 klog/状态机误判霸占
                if !realAdvance && state.nowPlaying.isPlaying {
                    arbLog("酷狗仲裁：无真实进度信号，不抢占在播的 \(cur)")
                    return
                }
            } else {
                // 候选暂停：当前在播 → 不抢占；当前有显示且候选不晚于当前 → 保持；
                // 当前无显示（冷启动/全暂停）→ 候选可直接展示
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

    /// 最新 .klog 是否刚写入「播放中」信号（isPlaying:1）：
    /// 仅 mtime 新鲜不够——酷狗暂停时后台也会持续写网络/心跳日志；
    /// 且必须只查文件尾部的最近写入（历史 isPlaying:1 残留会长期留在文件前部）
    private func isKlogPlayingActive(within seconds: TimeInterval) -> Bool {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: klogDir) else { return false }
        let klogs = files.filter { $0.hasSuffix(".klog") }.sorted()
        guard let newest = klogs.last else { return false }
        let path = "\(klogDir)/\(newest)"
        guard let mtime = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate]) as? Date,
              Date().timeIntervalSince(mtime) < seconds else { return false }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return false }
        // 含二进制数据，容错解码；只扫尾部 16KB（约十几秒的写入量）
        let s = String(decoding: data.suffix(16 * 1024), as: UTF8.self)
        return s.contains("isPlaying:1")
    }

    /// 仲裁决策日志（节流，避免让位/接管刷屏）
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
            // 含二进制时按行尝试
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let s = String(data: data, encoding: .utf8) else { return nil }
            return extractCover(from: s)
        }
        return extractCover(from: text)
    }

    private func extractCover(from text: String) -> String? {
        // 找最后一次 union_cover = "http..."
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
