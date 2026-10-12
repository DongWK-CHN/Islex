//  IsleX 灵屿 —— 网易云音乐 CEF 直连（Chrome DevTools Protocol）
//  网易云 Mac 客户端基于 CEF：启动时附加 --remote-debugging-port 后，
//  即可通过本地 WebSocket 直接读取播放信息（歌名/歌手/进度/封面/播放状态）
//  并控制播放（播放/暂停/上一首/下一首），无需截屏、无需任何系统权限。
//  网易云未带参数启动时（端口关闭）提示用户一键重启接通。

#if !APPSTORE
import AppKit
import Foundation

final class NeteaseCDPClient {
    static let shared = NeteaseCDPClient()
    private init() {}

    static let port = 19321
    static let bundleId = "com.netease.163music"

    private var state: AppState { AppState.shared }
    private var timer: Timer?
    private var running = false
    private var connecting = false
    private var wsTask: URLSessionWebSocketTask?
    private var pending: ((String) -> Void)?
    private var msgId = 0
    private var lastGoodInfo = Date.distantPast
    private var coverCache: [String: NSImage] = [:]
    private var lastCoverURL = ""
    private var lastCid = ""
    private var lastTitle = ""
    private var lastArtist = ""
    /// 已为哪个网易云进程自动重启过（每进程实例仅自动重启一次，避免循环）
    private var autoRelaunchPID: pid_t = -1
    private var lastAutoRelaunchAt = Date.distantPast

    /// CDP 通道已建立（WebSocket 连接中）
    private(set) var isConnected = false
    /// 最近一次成功读取播放信息（用于判定直连是否活跃）
    var isActive: Bool { isConnected && Date().timeIntervalSince(lastGoodInfo) < 5 }
    /// 最近一次直连上报的播放状态（源仲裁用）
    private(set) var lastReportedPlaying = false

    // MARK: - 生命周期

    func start() {
        guard !running else { return }
        running = true
        startupLog("网易云 CDP 直连轮询启动（端口 \(Self.port)）")
        tick()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        running = false
        timer?.invalidate()
        timer = nil
        disconnect()
    }

    private func tick() {
        guard running else { return }
        // 网易云未运行：断开并清除重启提示（下次从灵屿启动会自动带参数）
        guard NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleId).first != nil else {
            setNeedsRelaunch(false)
            disconnect()
            return
        }
        if isConnected {
            pollOnce()
        } else if !connecting {
            connect()
        }
    }

    // MARK: - 连接

    private func connect() {
        connecting = true
        let url = URL(string: "http://127.0.0.1:\(Self.port)/json/list")!
        URLSession.shared.dataTask(with: URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 2)) { [weak self] data, _, _ in
            guard let self = self else { return }
            self.connecting = false
            var wsURL: URL?
            if let data = data,
               let pages = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]],
               let page = pages.first(where: { ($0["type"] as? String) == "page" }),
               let ws = page["webSocketDebuggerUrl"] as? String {
                wsURL = URL(string: ws)
            }
            DispatchQueue.main.async {
                guard let wsURL = wsURL else {
                    // 网易云在运行但调试端口未开：自动重启一次接通（无需手动点徽标）
                    self.setNeedsRelaunch(true)
                    self.maybeAutoRelaunch()
                    return
                }
                self.openSocket(wsURL)
            }
        }.resume()
    }

    /// 网易云在运行但端口未开 → 自动带调试参数重启（每进程实例一次；距上次尝试 >60s）
    private func maybeAutoRelaunch() {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleId).first else { return }
        let pid = app.processIdentifier
        guard pid != autoRelaunchPID, Date().timeIntervalSince(lastAutoRelaunchAt) > 60 else { return }
        autoRelaunchPID = pid
        lastAutoRelaunchAt = Date()
        startupLog("网易云 CDP：调试端口未开，自动重启接通")
        app.terminate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            Self.launchWithPort()
        }
    }

    private func openSocket(_ url: URL) {
        let task = URLSession.shared.webSocketTask(with: url)
        wsTask = task
        task.resume()
        setConnected(true)
        setNeedsRelaunch(false)
        startupLog("网易云 CDP 直连已建立")
        receiveLoop()
        pollOnce()
    }

    private func receiveLoop() {
        wsTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                if case .string(let s) = message { self.handleMessage(s) }
                self.receiveLoop()
            case .failure:
                DispatchQueue.main.async { self.disconnect() }
            }
        }
    }

    private func handleMessage(_ s: String) {
        guard let data = s.data(using: .utf8),
              let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let id = obj["id"] as? Int, id == msgId else { return }
        let value = ((obj["result"] as? [String: Any])?["result"] as? [String: Any])?["value"] as? String ?? ""
        let cb = pending
        pending = nil
        cb?(value)
    }

    private func disconnect() {
        guard isConnected || wsTask != nil else { return }
        setConnected(false)
        wsTask?.cancel(with: .goingAway, reason: nil)
        wsTask = nil
        pending = nil
        startupLog("网易云 CDP 直连断开")
    }

    private func setConnected(_ v: Bool) {
        guard isConnected != v else { return }
        isConnected = v
        DispatchQueue.main.async { self.state.neteaseCDPConnected = v }
    }

    private func setNeedsRelaunch(_ v: Bool) {
        DispatchQueue.main.async {
            guard self.state.neteaseNeedsRelaunch != v else { return }
            self.state.neteaseNeedsRelaunch = v
        }
    }

    // MARK: - 轮询播放信息

    /// 页面同时存在两个 #page_pc_mini_bar（隐藏暂停态 + 可见播放态），必须取可见节点，
    /// 否则播放态下进度/封面读取为空（切歌后进度不复位 → 歌词不同步）
    private static let visibleRootJS = """
        var rs=document.querySelectorAll('#page_pc_mini_bar');var r=null;
        for(var k=0;k<rs.length;k++){if(rs[k].offsetParent!==null){r=rs[k];break;}}
        if(!r&&rs.length)r=rs[0];
        """

    private static let pollJS = """
    (function(){
        \(visibleRootJS)
        if(!r)return '{"ok":0}';
        var q=function(s){return r.querySelector(s)};
        var vinyl=q('.miniVinylWrapper')||q('[class*=vinylImgCls]');
        var range=q('input[type=range]');
        var icon=q('.cmd-icon-play,.cmd-icon-pause');
        var img=vinyl?vinyl.querySelector('img'):null;
        var t=q('.main-title');
        var dl=r.getAttribute('data-log')||'';
        var cm=dl.match(/"s_cid":"(\\d+)"/);
        return JSON.stringify({ok:1,
            title:t?(t.innerText||'').trim():'',
            artist:(q('.author')||{}).innerText||'',
            elapsed:range?parseFloat(range.value):-1,
            duration:range?parseFloat(range.max):-1,
            playing:icon?icon.className.indexOf('cmd-icon-pause')>=0:false,
            cover:img?img.src:'',
            cid:cm?cm[1]:''});
    })()
    """

    private func pollOnce() {
        evaluate(Self.pollJS) { [weak self] s in
            guard let self = self,
                  let data = s.data(using: .utf8),
                  let d = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  (d["ok"] as? Int) == 1 else { return }
            self.lastGoodInfo = Date()
            // 清理音质/会员角标后缀（DOM innerText 会带上 VIP/SQ/HQ 等标签文本与换行）
            var rawTitle = (d["title"] as? String ?? "")
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            for suffix in ["VIP", "SQ", "HQ", "Hi-Res"] {
                if rawTitle.hasSuffix(suffix) {
                    rawTitle = String(rawTitle.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
                }
            }
            let title = rawTitle
            let artist = (d["artist"] as? String ?? "")
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let elapsed = d["elapsed"] as? Double ?? -1
            let duration = d["duration"] as? Double ?? -1
            let playing = d["playing"] as? Bool ?? false
            let cover = d["cover"] as? String ?? ""
            let cid = d["cid"] as? String ?? ""
            DispatchQueue.main.async {
                self.apply(title: title, artist: artist, elapsed: elapsed,
                           duration: duration, playing: playing, cover: cover, cid: cid)
            }
        }
    }

    private func apply(title: String, artist: String, elapsed: Double,
                       duration: Double, playing: Bool, cover: String, cid: String) {
        guard !title.isEmpty else { return }
        let songChanged = title != lastTitle || artist != lastArtist
        // ---- 多源仲裁：同时播放时显示「最晚开启」的源；暂停态显示「最晚播放」的源 ----
        state.notePlaying(Self.bundleId, playing)
        let cur = state.nowPlayingApp
        if cur != Self.bundleId {
            if playing {
                // 当前源也在播放且开启更晚 → 让位
                if state.nowPlaying.isPlaying && state.startedLater(cur, than: Self.bundleId) { return }
            } else {
                // 候选暂停：当前在播 → 不抢占；当前有显示且候选不晚于当前 → 保持；
                // 当前无显示（冷启动/全暂停）→ 候选可直接展示
                if state.nowPlaying.isPlaying { return }
                if !state.nowPlayingApp.isEmpty && state.playedNotLaterThan(Self.bundleId, than: cur) { return }
            }
        }
        lastReportedPlaying = playing
        var np = state.nowPlaying
        if songChanged || state.nowPlayingApp != Self.bundleId {
            np.title = title
            np.artist = artist
            np.album = ""
            np.artwork = nil
            lastTitle = title
            lastArtist = artist
            lastCoverURL = ""
            state.nowPlayingApp = Self.bundleId
        }
        if duration > 0 { np.duration = duration }
        // 进度校正：本地 0.1s 推进为主，仅明显前进或切歌回退时采用直连值
        if elapsed >= 0 {
            if elapsed > np.elapsed + 0.3 || (songChanged && elapsed < np.elapsed - 2.0) {
                np.elapsed = elapsed
            }
        }
        np.isPlaying = playing
        np.rate = playing ? 1 : 0
        if songChanged {
            startupLog("CDP 媒体更新：\(title) - \(artist) 播放=\(playing)")
            state.nowPlaying = np
            state.fetchLyrics()
        } else {
            state.nowPlaying = np
        }
        // 封面：优先 DOM 节点（暂停态迷你条有封面图）；播放态迷你条无封面节点时
        // 用 data-log 中的歌曲 ID 调公开详情接口取专辑封面
        if !cover.isEmpty {
            lastCid = cid
            loadCover(cover, forTitle: title)
        } else if !cid.isEmpty && cid != lastCid {
            lastCid = cid
            fetchCoverViaAPI(cid, forTitle: title)
        }
    }

    /// 通过网易云公开歌曲详情接口取专辑封面（播放态 DOM 无封面节点时兜底）
    private func fetchCoverViaAPI(_ cid: String, forTitle: String) {
        let encoded = "[\(cid)]".addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        guard let url = URL(string: "https://music.163.com/api/song/detail/?id=\(cid)&ids=\(encoded)") else { return }
        var req = URLRequest(url: url)
        req.setValue("https://music.163.com/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let songs = obj["songs"] as? [[String: Any]],
                  let album = songs.first?["album"] as? [String: Any],
                  let pic = album["picUrl"] as? String, !pic.isEmpty else { return }
            DispatchQueue.main.async {
                self.loadCover(pic + "?param=300y300", forTitle: forTitle)
            }
        }.resume()
    }

    /// 封面下载（按 URL 缓存；切歌后丢弃过期结果）
    private func loadCover(_ urlStr: String, forTitle: String) {
        if urlStr == lastCoverURL { return }
        lastCoverURL = urlStr
        if let img = coverCache[urlStr] {
            setArtwork(img, forTitle: forTitle)
            return
        }
        guard let url = URL(string: urlStr) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data, let img = NSImage(data: data) else { return }
            self.coverCache[urlStr] = img
            DispatchQueue.main.async { self.setArtwork(img, forTitle: forTitle) }
        }.resume()
    }

    private func setArtwork(_ img: NSImage, forTitle: String) {
        guard state.nowPlaying.title == forTitle else { return }
        var np = state.nowPlaying
        np.artwork = img
        state.nowPlaying = np
    }

    // MARK: - 播放控制（未连接返回 false，调用方回退 AppleScript/媒体键）

    func sendControl(_ cmd: Int32) -> Bool {
        guard isConnected else { return false }
        let sel: String
        switch cmd {
        case MRCommand.nextTrack: sel = ".cmd-icon-next"
        case MRCommand.previousTrack: sel = ".cmd-icon-pre"
        default: sel = ".cmd-icon-play,.cmd-icon-pause"
        }
        let js = "(function(){" + Self.visibleRootJS + "if(!r)return 0;" +
            "var i=r.querySelector('\(sel)');if(!i)return 0;var b=i.closest('button');" +
            "if(!b)return 0;b.click();return 1;})()"
        evaluate(js) { _ in }
        return true
    }

    /// 跳转播放进度：读取滑轨坐标后用 CDP Input 域派发真实鼠标点击（React 受控组件
    /// 不响应合成 input/change 事件，只有真实指针交互才会触发 seek）
    func seek(to seconds: Double) -> Bool {
        guard isConnected else { return false }
        let js = "(function(){" + Self.visibleRootJS + "if(!r)return '{\"ok\":0}';" +
            "var s=r.querySelector('.slider-default');if(!s)return '{\"ok\":0}';" +
            "var b=s.getBoundingClientRect();var m=r.querySelector('input[type=range]');" +
            "return JSON.stringify({ok:1,x:b.x,y:b.y,w:b.width,h:b.height,max:m?parseFloat(m.max):0});})()"
        evaluate(js) { [weak self] s in
            guard let self = self,
                  let data = s.data(using: .utf8),
                  let d = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  (d["ok"] as? Int) == 1,
                  let maxV = d["max"] as? Double, maxV > 0 else { return }
            let frac = min(Swift.max(seconds / maxV, 0), 1)
            let x = (d["x"] as? Double ?? 0) + (d["w"] as? Double ?? 0) * frac
            let y = (d["y"] as? Double ?? 0) + (d["h"] as? Double ?? 0) / 2
            self.sendRaw("Input.dispatchMouseEvent",
                         ["type": "mousePressed", "x": x, "y": y, "button": "left", "clickCount": 1])
            self.sendRaw("Input.dispatchMouseEvent",
                         ["type": "mouseReleased", "x": x, "y": y, "button": "left", "clickCount": 1])
        }
        return true
    }

    /// 发送无回调的 CDP 命令（Input 域事件）
    private func sendRaw(_ method: String, _ params: [String: Any]) {
        guard let task = wsTask else { return }
        msgId += 1
        let payload: [String: Any] = ["id": msgId, "method": method, "params": params]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }
        task.send(.string(text)) { _ in }
    }

    private func evaluate(_ expr: String, _ cb: @escaping (String) -> Void) {
        guard isConnected, let task = wsTask else { cb(""); return }
        msgId += 1
        pending = cb
        let payload: [String: Any] = [
            "id": msgId,
            "method": "Runtime.evaluate",
            "params": ["expression": expr, "returnByValue": true]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { pending = nil; cb(""); return }
        task.send(.string(text)) { [weak self] err in
            if err != nil {
                DispatchQueue.main.async {
                    self?.disconnect()
                    let cb2 = self?.pending
                    self?.pending = nil
                    cb2?("")
                }
            }
        }
    }

    // MARK: - 启动管理

    /// 一键重启网易云并带调试参数启动（接通直连）
    func relaunchNetease() {
        startupLog("重启网易云以接通 CDP 直连")
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleId).first {
            app.terminate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                Self.launchWithPort()
            }
        } else {
            Self.launchWithPort()
        }
    }

    /// 带调试端口参数启动网易云
    static func launchWithPort() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-b", bundleId, "--args", "--remote-debugging-port=\(port)"]
        try? p.run()
    }

    /// 从灵屿启动网易云时附加调试参数（OpenConfiguration.arguments）
    static func launchArgs(for path: String) -> [String]? {
        path.lowercased().hasSuffix("neteasemusic.app") ? ["--remote-debugging-port=\(port)"] : nil
    }
}
#endif
