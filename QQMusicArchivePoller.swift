//  IsleX 灵屿 —— QQ 音乐 archive 直连（无屏幕录制，事件驱动）
//  QQ 音乐（Mac Catalyst）把「当前播放队列」写入容器内 PlayingList.archive（NSKeyedArchiver plist）：
//    ~/Library/Containers/com.tencent.QQMusicMac/Data/Library/Application Support/QQMusicMac/iTemp/PlayingList.archive
//  结构（NSKeyedArchiver）：
//    $top.LastPlayingIndex  = 当前歌曲在队列中的索引
//    $top.PlayingList       → ListData → NS.objects = [UID → 歌曲字典]（整个队列）
//  歌曲字段：
//    songName         = 歌名
//    singerInfo       → name   = 歌手
//    albumInfo        → name/picMid = 专辑名 / 封面缩略 ID
//    song_Duration    = 总时长（秒）
//    songId / song_Mid = 歌曲 ID / 媒体 ID
//  播放状态推断（archive 无进度字段、播放中不持续写入）：
//    1) 首帧：archive 刚刚更新（<15s）→ 视为播放中；否则先以暂停态展示
//    2) 切歌（索引/歌名/歌手变化）→ 播放
//    3) 文件重写但歌不变 → 距上次播放事件 <5s 保持播放（开始播放的二次写入），否则视为暂停
//    4) 应用退出 → 暂停
//  进度：本地 ticker 推进（与酷狗/AppleScript 同一套策略）。
//  封面：picMid → https://y.gtimg.cn/music/photo_new/T002R300x300M000{picMid}.jpg

import AppKit
import Foundation

final class QQMusicArchivePoller {
    static let shared = QQMusicArchivePoller()
    static let bundleId = "com.tencent.QQMusicMac"

    private var state: AppState { AppState.shared }
    private var timer: Timer?
    private var running = false

    private var home: String { FileManager.default.homeDirectoryForCurrentUser.path }
    private var archivePath: String {
        "\(home)/Library/Containers/com.tencent.QQMusicMac/Data/Library/Application Support/QQMusicMac/iTemp/PlayingList.archive"
    }

    // ---- 状态机 ----
    private var lastMtime: Date?
    private var lastSnapshot: Snapshot?   // 最近一次成功解析的快照（文件静止时复用，避免重复解析）
    private var lastIndex = -1
    private var lastTitle = ""
    private var lastArtist = ""
    private var isPlaying = false
    private var hasFirstSnapshot = false
    private var tickerElapsed = -1.0
    private var lastTickerDate = Date()
    private var lastPlayEventAt = Date.distantPast
    private var appliedCoverURL = ""
    /// 已提示过完全磁盘访问（避免每次启动都弹系统设置）
    private var fdaPrompted = false
    /// 仲裁日志节流
    private var lastArbLog = Date.distantPast

    var isRunning: Bool { running }

    private init() {}

    func start() {
        guard !running else { return }
        running = true
        startupLog("QQ 音乐 archive 直连轮询启动")
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

    // MARK: - NSKeyedArchiver 解析

    private struct Snapshot {
        var title: String
        var artist: String
        var album: String
        var picMid: String
        var duration: Double
        var index: Int
        var mtime: Date
    }

    private func uidIdx(_ v: Any) -> Int? {
        let s = String(describing: v)
        guard let r = s.range(of: #"value = (\d+)"#, options: .regularExpression) else { return nil }
        return Int(String(s[r]).replacingOccurrences(of: "value = ", with: "").trimmingCharacters(in: .whitespaces))
    }

    private func deref(_ v: Any, in objs: [Any]) -> Any? {
        guard let idx = uidIdx(v), idx >= 0, idx < objs.count else { return v }
        return objs[idx]
    }

    private func str(_ v: Any, _ objs: [Any]) -> String {
        (deref(v, in: objs) as? String) ?? ""
    }

    private func readSnapshot() -> Snapshot? {
        let url = URL(fileURLWithPath: archivePath)
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let objs = plist["$objects"] as? [Any],
              let top = plist["$top"] as? [String: Any] else { return nil }
        let index = (top["LastPlayingIndex"] as? NSNumber)?.intValue ?? 0
        // PlayingList → ListData → NS.objects（队列）
        guard let playingListUID = top["PlayingList"],
              let plIdx = uidIdx(playingListUID),
              plIdx < objs.count,
              let pl = objs[plIdx] as? [String: Any],
              let listDataUID = pl["ListData"],
              let ldIdx = uidIdx(listDataUID),
              ldIdx < objs.count,
              let ld = objs[ldIdx] as? [String: Any],
              let nsObjects = ld["NS.objects"] as? [Any],
              index >= 0, index < nsObjects.count,
              let sIdx = uidIdx(nsObjects[index]),
              sIdx < objs.count,
              let song = objs[sIdx] as? [String: Any] else { return nil }
        let title = str(song["songName"] ?? "", objs)
        guard !title.isEmpty else { return nil }
        var artist = ""
        if let siUID = song["singerInfo"], let siIdx = uidIdx(siUID), siIdx < objs.count,
           let si = objs[siIdx] as? [String: Any] {
            artist = str(si["name"] ?? "", objs)
        }
        var album = "", picMid = ""
        if let aiUID = song["albumInfo"], let aiIdx = uidIdx(aiUID), aiIdx < objs.count,
           let ai = objs[aiIdx] as? [String: Any] {
            album = str(ai["name"] ?? "", objs)
            picMid = str(ai["picMid"] ?? "", objs)
        }
        let duration = (song["song_Duration"] as? NSNumber)?.doubleValue ?? 0
        let mtime = (try? FileManager.default.attributesOfItem(atPath: archivePath)[.modificationDate]) as? Date
        return Snapshot(title: title, artist: artist, album: album, picMid: picMid,
                        duration: duration, index: index, mtime: mtime ?? Date())
    }

    // MARK: - 轮询

    private func poll() {
        guard running else { return }
        // QQ 音乐未运行：标记暂停（若之前显示在播）
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
        let now = Date()
        // 性能优化：archive 未变化时（播放中 QQ 不写文件、暂停后静止）跳过全量读取+解析，
        // 只按本地 ticker 推进进度——与逐秒全读行为等价，省去每次 25KB+ 的 plist 解析开销。
        // 播放/切歌/暂停等事件都会触发 QQ 重写 archive（mtime 变化），届时才重新解析。
        if hasFirstSnapshot, let lastSnap = lastSnapshot,
           let m = try? (FileManager.default.attributesOfItem(atPath: archivePath)[.modificationDate] as? Date),
           m == lastMtime {
            if isPlaying {
                let elapsed = advanceTicker(playing: true, duration: state.nowPlaying.duration, now: now)
                apply(snap: lastSnap, elapsed: elapsed, playing: true, realAdvance: false)
            }
            return
        }
        guard let snap = readSnapshot() else {
            // 文件存在但读不到 → TCC 限制（容器/磁盘访问）。诊断具体缺失项
            if !fdaPrompted {
                fdaPrompted = true
                let dockOK = (try? Data(contentsOf: URL(fileURLWithPath: "\(home)/Library/Preferences/com.apple.dock.plist"))) != nil
                startupLog("QQ 音乐 archive 读取失败：dock=\(dockOK) —— 需在 系统设置→隐私与安全性→完全磁盘访问 中开启 IsleX 后重启")
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                    NSWorkspace.shared.open(url)
                }
            }
            return
        }
        lastSnapshot = snap

        // ---- 播放状态推断（事件驱动：播放中不写文件，开始/切歌/暂停时更新）----
        var newPlaying = isPlaying
        var realAdvance = false

        if !hasFirstSnapshot {
            // 首次读到：不当作切歌。archive 刚更新（<15s）→ 播放中，否则先暂停态展示
            hasFirstSnapshot = true
            newPlaying = now.timeIntervalSince(snap.mtime) < 15
            lastIndex = snap.index
            lastTitle = snap.title
            lastArtist = snap.artist
            tickerElapsed = 0
            lastTickerDate = now
            if newPlaying {
                lastPlayEventAt = now
                startupLog("QQ 音乐判定：首帧 archive 新鲜 → 播放中")
            }
        } else if snap.index != lastIndex || snap.title != lastTitle || snap.artist != lastArtist {
            // 切歌 = 播放事件
            newPlaying = true
            realAdvance = true
            lastIndex = snap.index
            lastTitle = snap.title
            lastArtist = snap.artist
            tickerElapsed = 0
            lastTickerDate = now
            lastPlayEventAt = now
            if newPlaying != isPlaying { startupLog("QQ 音乐判定：切歌 \(snap.title)") }
        } else if snap.mtime != lastMtime && isPlaying {
            // 文件重写但同歌 = 暂停信号（开始播放后 5 秒内的二次写入忽略）
            if now.timeIntervalSince(lastPlayEventAt) < 5 {
                // 保持播放（ticker 继续推进）
            } else {
                newPlaying = false
                tickerElapsed = 0
                if newPlaying != isPlaying { startupLog("QQ 音乐判定：archive 重写同歌 → 暂停") }
            }
        } else if snap.mtime != lastMtime && !isPlaying && lastMtime != nil {
            // 暂停后同歌重写 = 「继续播放」信号：恢复播放并从当前位置（或头）推进
            newPlaying = true
            lastPlayEventAt = now
            tickerElapsed = 0
            lastTickerDate = now
            startupLog("QQ 音乐判定：archive 重写同歌（暂停态）→ 继续播放")
        }
        // 无事件（文件静止）：保持状态，本地 ticker 推进

        lastMtime = snap.mtime

        // 本地 ticker：播放中按时间推进
        let elapsed = advanceTicker(playing: newPlaying, duration: snap.duration, now: now)

        apply(snap: snap, elapsed: elapsed, playing: newPlaying, realAdvance: realAdvance)
    }

    /// 本地播放 ticker：播放中按真实时间推进，返回当前 elapsed；暂停/播完返回 0
    private func advanceTicker(playing: Bool, duration: Double, now: Date) -> Double {
        if playing {
            let dt = now.timeIntervalSince(lastTickerDate)
            if dt > 0, dt < 5 {
                tickerElapsed += dt
            } else if dt >= 5 {
                // 长时间无推进（挂起/暂停恢复）：重新起算，避免一次性跳变
                tickerElapsed = 0
                lastTickerDate = now
            }
            lastTickerDate = now
            if duration > 0 && tickerElapsed >= duration - 0.5 {
                // 播完本曲：回到静止状态，等待下一次 archive 更新（切歌）
                tickerElapsed = 0
                lastTickerDate = now
            }
            return tickerElapsed
        }
        return 0
    }

    // MARK: - 应用到状态（与其它源同一套多源仲裁）

    private func apply(snap: Snapshot, elapsed: Double, playing: Bool, realAdvance: Bool) {
        state.notePlaying(Self.bundleId, playing)
        let cur = state.nowPlayingApp
        if cur != Self.bundleId {
            if playing {
                if state.nowPlaying.isPlaying && state.startedLater(cur, than: Self.bundleId) { return }
                // 防御：本轮无真实进度信号（仅推断播放）且其它源在播 → 不抢占
                if !realAdvance && state.nowPlaying.isPlaying {
                    arbLog("QQ 音乐仲裁：无真实播放信号，不抢占在播的 \(cur)")
                    return
                }
            } else {
                if state.nowPlaying.isPlaying { return }
                if !state.nowPlayingApp.isEmpty && state.playedNotLaterThan(Self.bundleId, than: cur) { return }
            }
        }
        var np = state.nowPlaying
        let songChanged = snap.title != np.title || snap.artist != np.artist || state.nowPlayingApp != Self.bundleId
        if songChanged {
            arbLog("QQ 音乐仲裁：接管显示（\(playing ? "播放" : "暂停")）")
            np.title = snap.title
            np.artist = snap.artist
            np.album = snap.album
            np.artwork = nil
            state.nowPlayingApp = Self.bundleId
            fetchCoverIfNeeded(picMid: snap.picMid, title: snap.title)
        }
        if snap.duration > 0 { np.duration = snap.duration }
        if elapsed > np.elapsed + 0.3 || (songChanged && elapsed < np.elapsed - 2.0) {
            np.elapsed = elapsed
        }
        np.isPlaying = playing
        np.rate = playing ? 1 : 0
        if songChanged {
            startupLog("QQ 音乐 archive 直连：\(snap.title) - \(snap.artist) 播放=\(playing)")
            state.nowPlaying = np
            state.fetchLyrics()
        } else {
            state.nowPlaying = np
        }
        isPlaying = playing
    }

    // MARK: - 封面（picMid → 官方图片 URL）

    private func fetchCoverIfNeeded(picMid: String, title: String) {
        guard !picMid.isEmpty else { return }
        let full = "https://y.gtimg.cn/music/photo_new/T002R300x300M000\(picMid).jpg"
        guard full != appliedCoverURL else { return }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let imgURL = URL(string: full),
                  let data = try? Data(contentsOf: imgURL, options: [.mappedIfSafe]),
                  let img = NSImage(data: data) else { return }
            self.appliedCoverURL = full
            DispatchQueue.main.async {
                self.state.applyArtwork(img, forTitle: title)
            }
        }
    }

    private func arbLog(_ msg: String) {
        guard Date().timeIntervalSince(lastArbLog) > 3 else { return }
        lastArbLog = Date()
        startupLog(msg)
    }
}
