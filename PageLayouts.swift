//  IsleX 灵屿 —— 每页布局自定义（风格 / 尺寸 / 区块开关）

import Foundation

/// 单页布局配置
struct PageLayoutConfig: Codable, Equatable {
    var style: Int = 0            // 0 标准 / 1 紧凑 / 2 大卡片
    var customSize = false        // 启用自定义展开尺寸
    var width: CGFloat = 0        // 0 = 使用全局默认展开宽度
    var height: CGFloat = 0       // 0 = 使用全局默认展开高度
    var hiddenBlocks: [String] = []   // 隐藏的内容区块 id

    /// 各页面可隐藏的区块（页面编号 → 区块列表；8/9 分别为 Lite/Pro 的天气页）
    static let pageBlocks: [Int: [(id: String, name: String)]] = [
        1: [("artwork", "封面"), ("lyrics", "歌词")],
        8: [("daily", "7 天轨迹"), ("air", "空气质量")],
        9: [("daily", "7 天轨迹"), ("air", "空气质量")],
    ]
}

extension AppState {
    /// 读取某页布局配置
    func pageLayout(for page: Int) -> PageLayoutConfig {
        pageLayouts[page] ?? PageLayoutConfig()
    }

    /// 设置页面布局风格（0 标准 / 1 紧凑 / 2 大卡片）
    func setPageLayoutStyle(_ page: Int, _ style: Int) {
        var cfg = pageLayout(for: page)
        cfg.style = min(max(style, 0), 2)
        pageLayouts[page] = cfg
        savePageLayouts()
        repositionWindow()
    }

    /// 启用/关闭该页自定义展开尺寸（启用时以当前全局尺寸为默认值）
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

    /// 切换某页某区块的隐藏状态
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

    /// 取消隐藏某页的某区块
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
