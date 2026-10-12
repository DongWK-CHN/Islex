import Foundation

struct PageLayoutConfig: Codable, Equatable {
    var style: Int = 0
    var customSize = false
    var width: CGFloat = 0
    var height: CGFloat = 0
    var hiddenBlocks: [String] = []

    static let pageBlocks: [Int: [(id: String, name: String)]] = [
        1: [("artwork", "封面"), ("lyrics", "歌词")],
        8: [("daily", "7 天轨迹"), ("air", "空气质量")],
        9: [("daily", "7 天轨迹"), ("air", "空气质量")],
    ]
}

extension AppState {
    func pageLayout(for page: Int) -> PageLayoutConfig {
        pageLayouts[page] ?? PageLayoutConfig()
    }

    func setPageLayoutStyle(_ page: Int, _ style: Int) {
        var cfg = pageLayout(for: page)
        cfg.style = min(max(style, 0), 2)
        pageLayouts[page] = cfg
        savePageLayouts()
        repositionWindow()
    }

    func setPageLayoutCustomSize(_ page: Int, _ on: Bool) {
        var cfg = pageLayout(for: page)
        cfg.customSize = on
        if on {
            if cfg.width <= 0 { cfg.width = appearanceExpandedWidth > 0 ? appearanceExpandedWidth : 512 }
            if cfg.height <= 0 { cfg.height = appearanceExpandedHeight > 0 ? appearanceExpandedHeight : 292 }
        }
        pageLayouts[page] = cfg
        savePageLayouts()
        repositionWindow()
    }

    func setPageLayoutWidth(_ page: Int, _ w: CGFloat) {
        var cfg = pageLayout(for: page)
        cfg.width = max(w, 50)
        cfg.customSize = true
        pageLayouts[page] = cfg
        savePageLayouts()
        repositionWindow()
    }

    func setPageLayoutHeight(_ page: Int, _ h: CGFloat) {
        var cfg = pageLayout(for: page)
        cfg.height = max(h, 30)
        cfg.customSize = true
        pageLayouts[page] = cfg
        savePageLayouts()
        repositionWindow()
    }

    func togglePageBlock(_ page: Int, _ block: String) {
        var cfg = pageLayout(for: page)
        if let i = cfg.hiddenBlocks.firstIndex(of: block) {
            cfg.hiddenBlocks.remove(at: i)
        } else {
            cfg.hiddenBlocks.append(block)
        }
        pageLayouts[page] = cfg
        savePageLayouts()
    }

    func showPageBlock(_ page: Int, _ block: String) {
        var cfg = pageLayout(for: page)
        cfg.hiddenBlocks.removeAll { $0 == block }
        pageLayouts[page] = cfg
        savePageLayouts()
    }

    func loadPageLayouts() {
        guard let data = UserDefaults.standard.data(forKey: "pageLayouts"),
              let dict = try? JSONDecoder().decode([Int: PageLayoutConfig].self, from: data) else { return }
        pageLayouts = dict
    }

    private func savePageLayouts() {
        if let data = try? JSONEncoder().encode(pageLayouts) {
            UserDefaults.standard.set(data, forKey: "pageLayouts")
        }
    }
}
