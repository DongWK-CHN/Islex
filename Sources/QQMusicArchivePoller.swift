// QQ 音乐把播放队列写入 PlayingList.archive（NSKeyedArchiver），状态靠文件重写事件推断。
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

    private var lastMtime: Date?
    private var lastSnapshot: Snapshot?
    private var lastIndex = -1
    private var lastTitle = ""
    private var lastArtist = ""
    private var isPlaying = false
    private var hasFirstSnapshot = false
    private var tickerElapsed = -1.0
    private var lastTickerDate = Date()
    private var lastPlayEventAt = Date.distantPast
    private var appliedCoverURL = ""
    private var fdaPrompted = false
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

        var newPlaying = isPlaying
        var realAdvance = false

        if !hasFirstSnapshot {
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
            if now.timeIntervalSince(lastPlayEventAt) < 5 {
            } else {
                newPlaying = false
                tickerElapsed = 0
                if newPlaying != isPlaying { startupLog("QQ 音乐判定：archive 重写同歌 → 暂停") }
            }
        } else if snap.mtime != lastMtime && !isPlaying && lastMtime != nil {
            newPlaying = true
            lastPlayEventAt = now
            tickerElapsed = 0
            lastTickerDate = now
            startupLog("QQ 音乐判定：archive 重写同歌（暂停态）→ 继续播放")
        }

        lastMtime = snap.mtime

        let elapsed = advanceTicker(playing: newPlaying, duration: snap.duration, now: now)

        apply(snap: snap, elapsed: elapsed, playing: newPlaying, realAdvance: realAdvance)
    }

    private func advanceTicker(playing: Bool, duration: Double, now: Date) -> Double {
        if playing {
            let dt = now.timeIntervalSince(lastTickerDate)
            if dt > 0, dt < 5 {
                tickerElapsed += dt
            } else if dt >= 5 {
                tickerElapsed = 0
                lastTickerDate = now
            }
            lastTickerDate = now
            if duration > 0 && tickerElapsed >= duration - 0.5 {
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
