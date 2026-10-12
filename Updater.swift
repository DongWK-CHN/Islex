//  IsleX 灵屿 —— OTA 更新检查
//  由 main.swift 自动拆分生成，勿手动调整导入。

import AppKit
import Foundation

// MARK: - OTA 更新推送
// 部署方式：把 latest.json 放到可公网访问的地址（GitHub Releases / 自有服务器），
// 然后把 manifestURL 改成你的地址。manifest 格式：
//   { "version": "1.0.1", "notes": "修复 xxx", "url": "https://.../IsleX.dmg" }

enum Updater {
    /// ⚠️ 部署时改为你的 manifest 地址
    static let manifestURL = URL(string: "https://your-host.example.com/islex/latest.json")!
    /// 两次检查的最小间隔（秒），避免每次启动都请求
    static let checkInterval: TimeInterval = 6 * 3600

    static func currentVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    /// 启动时调用：距上次检查超过间隔才请求
    static func checkIfNeeded() {
        let last = UserDefaults.standard.double(forKey: "lastUpdateCheckAt")
        if Date().timeIntervalSince1970 - last < checkInterval { return }
        check()
    }

    /// 强制检查（忽略间隔）
    static func check() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUpdateCheckAt")
        var req = URLRequest(url: manifestURL)
        req.timeoutInterval = 8
        URLSession.shared.dataTask(with: req) { data, _, err in
            guard err == nil, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ver = json["version"] as? String,
                  let urlStr = json["url"] as? String,
                  isNewer(ver, than: currentVersion()) else { return }
            DispatchQueue.main.async {
                AppState.shared.updateVersion = ver
                AppState.shared.updateNotes = (json["notes"] as? String) ?? ""
                AppState.shared.updateURL = urlStr
            }
        }.resume()
    }

    /// 语义版本比较：1.2.3 > 1.2.0
    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").compactMap { Int($0) }
        let pb = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    /// 打开下载地址（默认浏览器）
    static func openDownload() {
        let urlStr = AppState.shared.updateURL.isEmpty
            ? "https://your-host.example.com/islex"
            : AppState.shared.updateURL
        guard let url = URL(string: urlStr) else { return }
        NSWorkspace.shared.open(url)
    }
}
