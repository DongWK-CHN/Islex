import AppKit
import Foundation

// MARK: - OTA 更新推送
// latest.json 放到公网地址后，把 manifestURL 改成它。
// 格式：{"version":"1.0.1","notes":"...","url":"https://.../IsleX.dmg"}

enum Updater {
    static let manifestURL = URL(string: "https://your-host.example.com/islex/latest.json")!
    static let checkInterval: TimeInterval = 6 * 3600

    static func currentVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    static func checkIfNeeded() {
        let last = UserDefaults.standard.double(forKey: "lastUpdateCheckAt")
        if Date().timeIntervalSince1970 - last < checkInterval { return }
        check()
    }

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

    static func openDownload() {
        let urlStr = AppState.shared.updateURL.isEmpty
            ? "https://your-host.example.com/islex"
            : AppState.shared.updateURL
        guard let url = URL(string: urlStr) else { return }
        NSWorkspace.shared.open(url)
    }
}
