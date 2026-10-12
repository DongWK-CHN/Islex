import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers
import ImageIO
import ServiceManagement
import ApplicationServices
import CoreAudio
import IOKit
import Foundation

// MARK: - 界面语言本地化（zh 为基准，en/ja 查表翻译；未收录词条回退中文）

func L(_ zh: String) -> String {
    let lang = AppState.shared.appLanguage
    guard lang != "zh", let e = L10n.table[zh] else { return zh }
    return lang == "ja" ? e.ja : e.en
}

enum L10n {
    static let table: [String: (en: String, ja: String)] = [
        "IsleX 灵屿 设置": ("IsleX Settings", "IsleX 設定"),
        "外观": ("Appearance", "外観"),
        "系统": ("System", "システム"),
        "跑马灯": ("Marquee", "マーキー"),
        "小组件": ("Widgets", "ウィジェット"),
        "形态与风格": ("Shape & Style", "形状とスタイル"),
        "尺寸与位置": ("Size & Position", "サイズと位置"),
        "显示": ("Display", "表示"),
        "自定义背景": ("Custom Background", "カスタム背景"),
        "性能": ("Performance", "パフォーマンス"),
        "语言": ("Language", "言語"),
        "电源": ("Power", "電源"),
        "提示与通知": ("Toasts", "通知"),
        "CPU 温度": ("CPU Temperature", "CPU 温度"),
        "界面语言": ("Interface Language", "界面言語"),
        "恢复默认": ("Reset Defaults", "デフォルトに戻す"),
        "选择图片…": ("Choose Image…", "画像を選択…"),
        "已选择图片": ("Image selected", "画像選択済み"),
        "全部显示": ("Show All", "すべて表示"),
        "灵屿页面显示": ("Island Pages", "島のページ"),
        "固定": ("Fixed", "固定"),
        "动态模糊（Liquid Glass）": ("Dynamic Blur (Liquid Glass)", "動的ブラー（Liquid Glass）"),
        "极光质感（Aurora Texture）": ("Aurora Texture", "オーロラ質感"),
        "自定义背景颜色": ("Custom background color", "カスタム背景色"),
        "自定义背景图片": ("Custom background image", "カスタム背景画像"),
        "合盖不休眠": ("No sleep when lid closed", "蓋を閉じてもスリープしない"),
        "耳机连接提示": ("AirPods connection toast", "イヤホン接続通知"),
        "收起宽度": ("Compact width", "収納幅"),
        "收起高度": ("Compact height", "収納高さ"),
        "展开宽度": ("Expanded width", "展開幅"),
        "展开高度": ("Expanded height", "展開高さ"),
        "水平偏移": ("Horizontal offset", "水平オフセット"),
        "垂直偏移": ("Vertical offset", "垂直オフセット"),
        "展开缩放": ("Expanded scale", "展開スケール"),
        "收起缩放": ("Compact scale", "収納スケール"),
        "字体大小": ("Font size", "フォントサイズ"),
        "模糊强度": ("Blur intensity", "ブラー強度"),
        "玻璃厚度": ("Glass thickness", "ガラス厚"),
        "玻璃边框": ("Glass bezel", "ガラス枠"),
        "折射率": ("Refraction", "折射率"),
        "跑马灯边框": ("Marquee Border", "マーキーボーダー"),
        "启用动态边框": ("Enable dynamic border", "動的ボーダーを有効化"),
        "速度": ("Speed", "速度"),
        "慢": ("Slow", "遅"),
        "中": ("Medium", "中"),
        "快": ("Fast", "速"),
        "很快": ("Faster", "より速く"),
        "极快": ("Fastest", "最速"),
        "CPU 联动": ("CPU linked", "CPU 連動"),
        "仪表盘": ("Dashboard", "ダッシュボード"),
        "媒体": ("Media", "メディア"),
        "番茄钟": ("Pomodoro", "ポモドーロ"),
        "文件中转站": ("File Station", "ファイルステーション"),
        "应用": ("Apps", "アプリ"),
        "格式转换": ("Converter", "形式変換"),
        "硬件状态": ("Hardware", "ハードウェア"),
        "待办事项": ("Todos", "ToDo"),
        "快捷应用": ("Quick Apps", "クイックアプリ"),
        "选择文件": ("Choose File", "ファイルを選択"),
        "支持图片 / 音频 / 文本": ("Images / Audio / Text", "画像 / 音声 / テキスト"),
        "转换为": ("Convert to", "変換先"),
        "开始": ("Start", "開始"),
        "添加待办事项…": ("Add a todo…", "ToDo を追加…"),
        "暂无待办事项": ("No todos", "ToDo なし"),
        "项未完成": ("pending", "件未完了"),
        "电池": ("Battery", "バッテリー"),
        "内存": ("Memory", "メモリ"),
        "CPU 使用率": ("CPU Usage", "CPU 使用率"),
        "正常": ("Normal", "正常"),
        "运行中": ("Running", "実行中"),
        "未运行": ("Not running", "未実行"),
        "打开": ("Open", "開く"),
        "切换": ("Switch", "切替"),
        "专注": ("Focus", "集中"),
        "设置": ("Settings", "設定"),
        "链接": ("Link", "リンク"),
        "转换完成": ("Converted", "変換完了"),
        "个文件": ("files", "個のファイル"),
        "收起": ("Collapse", "折りたたむ"),
        "暂停": ("Pause", "一時停止"),
        "重置": ("Reset", "リセット"),
        "跳过": ("Skip", "スキップ"),
        "上一首": ("Previous Track", "前の曲"),
        "播放/暂停": ("Play / Pause", "再生/一時停止"),
        "网易云直连": ("NetEase Direct Link", "NetEase 直連"),
        "网易云未接通直连，点击重启接通": ("NetEase not linked. Click to relaunch & connect", "NetEase 未接続。クリックで再起動して接続"),
        "下一首": ("Next Track", "次の曲"),
    ]
}

// MARK: - 全局状态

final class AppState: ObservableObject {
    @Published var isExpanded = false
    @Published var isHovering = false
    @Published private(set) var isTransitioning = false
    private var transitionEndWork: DispatchWorkItem?
    @Published var showPageDots = false
    @Published var nowPlaying = NowPlayingInfo()
    @Published var mockMediaEnabled = false
    private var mockMediaIndex = 0
    private var mockMediaTimer: Timer?
    private let mockSongs: [(title: String, artist: String, album: String, duration: Double)] = [
        ("起风了", "买辣椒也用券", "起风了", 320),
        ("孤勇者", "陈奕迅", "孤勇者", 276),
        ("光年之外", "邓紫棋", "光年之外", 242),
        ("稻香", "周杰伦", "魔杰座", 283),
        ("平凡之路", "朴树", "猎户星座", 305),
    ]
    private let mockLyrics: [String: [String]] = [
        "起风了": ["我曾将青春翻涌成她", "指尖弹出盛夏", "心之所动 且就随缘去吧", "这一路上走走停停", "顺着少年漂流的痕迹"],
        "孤勇者": ["爱你孤身走暗巷", "爱你不跪的模样", "爱你对峙过绝望", "不肯哭一场"],
        "光年之外": ["缘分让我们相遇乱世以外", "命运却要我们危难中相爱", "也许未来遥远在光年之外", "我愿守候未知里为你等待"],
        "稻香": ["对这个世界如果你有太多的抱怨", "跌倒了 就不敢继续往前走", "为什么 人要这么的脆弱 堕落", "请你打开电视看看"],
        "平凡之路": ["我曾经跨过山和大海", "也穿过人山人海", "我曾经拥有着一切", "转眼都飘散如烟"],
    ]
    @Published var nowPlayingApp = ""
    @Published var neteaseCDPConnected = false
    @Published var neteaseNeedsRelaunch = false
    @Published var lyricState: LyricState = .idle
    @Published var batteryLevel: Int = 100
    @Published var isCharging: Bool = false
    var date = Date()
    @Published var apps: [AppShortcut] = []
    @Published var editing = false
    @Published var geometry = NotchGeometry.current()

    @Published var screenTarget: CGDirectDisplayID = {
        UInt32(UserDefaults.standard.integer(forKey: "screenTarget"))
    }() {
        didSet {
            UserDefaults.standard.set(Int(screenTarget), forKey: "screenTarget")
            geometry = NotchGeometry.current(on: targetScreen)
            (NSApp.delegate as? AppDelegate)?.repositionIsland()
        }
    }
    var targetScreen: NSScreen? {
        guard screenTarget != 0 else { return nil }
        return NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == screenTarget
        }
    }
    var hostScreen: NSScreen? { targetScreen ?? NSScreen.main }
    var screenChoices: [(id: CGDirectDisplayID, name: String)] {
        [(0, "跟随主屏")] + NSScreen.screens.map { s in
            let id = (s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            let tag = s.frame.equalTo(NSScreen.main?.frame ?? .zero) ? "（主屏）" : ""
            return (id, "\(s.localizedName)\(tag) \(Int(s.frame.width))×\(Int(s.frame.height))")
        }
    }
    func setScreenTarget(_ id: CGDirectDisplayID) {
        guard screenTarget != id else { return }
        screenTarget = id
    }

    @Published var launchAtLogin = false
    @Published var airPodsConnected = false
    @Published var airPodsName: String = ""

    @Published var volumeToastEnabled = true
    @Published var volumeKeySuppressEnabled = true
    @Published var airPodsToastEnabled = true
    @Published var volumeSuppressPermitted = false
    @Published var volumeSuppressInstalled = false
    @Published var volumeSuppressEnabled = false
    @Published var volumeSuppressCount = 0
    @Published var volumeSuppressEvents = 0

    @Published var currentPage = 0

    let pageCount = 10
    @Published var pageOrder: [Int] = Array(0..<10)
    let pageNames = ["仪表盘", "媒体", "番茄钟", "文件中转站", "应用", "格式转换", "硬件状态", "待办事项", "天气", "提词器"]
    @Published var hiddenPages: Set<Int> = []
    @Published var pageLayouts: [Int: PageLayoutConfig] = [:]

    @Published var weatherCity: String = {
        UserDefaults.standard.string(forKey: "weatherCity") ?? "北京"
    }() {
        didSet { UserDefaults.standard.set(weatherCity, forKey: "weatherCity") }
    }
    @Published var weatherData: WeatherData?
    @Published var weatherLoading = false
    @Published var weatherError = ""
    @Published var weatherLastFetch: Date?
    var weatherFetchTask: URLSessionDataTask?

    @Published var tpText: String = {
        UserDefaults.standard.string(forKey: "tpText") ?? """
        欢迎使用提词器！

        在灵动岛中展开提词器页面，
        输入或导入你的讲稿（支持 txt / md / rtf），
        点击 ▶ 即可开始自动滚动提词。

        使用小贴士：
        · 播放中点击滚动区域可暂停 / 继续
        · 左侧滑块控制滚动速度（1-10）
        · A- / A+ 调整显示字号
        · 开启「镜像」可配合提词器玻璃反射摆放
        · 播放结束后点击 ⟲ 回到开头

        开始之前，请把这段示例替换为你自己的讲稿，
        在安静的环境里多排练几遍，
        熟悉语速与停顿节奏之后，
        正式录制或演讲时会更从容自然。

        祝使用愉快！
        """
    }() {
        didSet { UserDefaults.standard.set(tpText, forKey: "tpText") }
    }
    @Published var tpSpeed: Double = {
        let v = UserDefaults.standard.double(forKey: "tpSpeed")
        return v > 0 ? v : 3.0
    }() {
        didSet { UserDefaults.standard.set(tpSpeed, forKey: "tpSpeed") }
    }
    @Published var tpFontSize: CGFloat = {
        let v = UserDefaults.standard.double(forKey: "tpFontSize")
        return v > 0 ? CGFloat(v) : 20
    }() {
        didSet { UserDefaults.standard.set(tpFontSize, forKey: "tpFontSize") }
    }
    @Published var tpMirror = UserDefaults.standard.bool(forKey: "tpMirror") {
        didSet { UserDefaults.standard.set(tpMirror, forKey: "tpMirror") }
    }
    @Published var tpDocuments: [TeleprompterDoc] = []

    @Published var updateVersion = ""
    @Published var updateNotes = ""
    @Published var updateURL = ""
    var updateAvailable: Bool { !updateVersion.isEmpty }

    func displayName(of page: Int) -> String { L(pageNames[page]) }

    var visiblePages: [Int] { pageOrder.filter { !hiddenPages.contains($0) } }
    var visiblePageCount: Int { max(visiblePages.count, 1) }

    func displayPosition(of page: Int) -> Int {
        if let i = visiblePages.firstIndex(of: page) { return i }
        return min(page, max(visiblePageCount - 1, 0))
    }

    func togglePageHidden(_ page: Int) {
        guard page != 0 else { return }
        if hiddenPages.contains(page) {
            hiddenPages.remove(page)
        } else {
            hiddenPages.insert(page)
        }
        if currentPage >= visiblePageCount { currentPage = max(visiblePageCount - 1, 0) }
        savePageOrder()
    }

    func showAllPages() {
        hiddenPages.removeAll()
        savePageOrder()
    }

    func movePageInOrder(_ page: Int, up: Bool) {
        guard let idx = pageOrder.firstIndex(of: page) else { return }
        let target = up ? idx - 1 : idx + 1
        guard target >= 0, target < pageOrder.count else { return }
        pageOrder.swapAt(idx, target)
        savePageOrder()
    }

    func resetPageOrder() {
        pageOrder = Array(0..<pageCount)
        savePageOrder()
    }

    private func loadPageOrder() {
        if let arr = UserDefaults.standard.array(forKey: "pageOrder") as? [Int] {
            var valid = arr.filter { $0 >= 0 && $0 < pageCount }
            var seen = Set<Int>()
            valid.removeAll { !seen.insert($0).inserted }
            for p in 0..<pageCount where !valid.contains(p) {
                valid.append(p)
            }
            if valid.count == pageCount {
                pageOrder = valid
            }
        }
        if let hid = UserDefaults.standard.array(forKey: "hiddenPages") as? [Int] {
            hiddenPages = Set(hid.filter { $0 >= 0 && $0 < pageCount })
        }
    }

    private func savePageOrder() {
        UserDefaults.standard.set(pageOrder, forKey: "pageOrder")
        UserDefaults.standard.set(Array(hiddenPages), forKey: "hiddenPages")
    }

    @Published var appLanguage: String = AppState.systemDefaultLanguage() {
        didSet { UserDefaults.standard.set(appLanguage, forKey: "appLanguage") }
    }

    static func systemDefaultLanguage() -> String {
        let code = (Locale.preferredLanguages.first ?? "en").lowercased()
        if code.hasPrefix("zh") { return "zh" }
        if code.hasPrefix("ja") { return "ja" }
        return "en"
    }

    @Published var cpuTemp: Double = 0
    @Published var cpuLoad: Double = 0
    @Published var thermalLevel: String = "正常"
    @Published var lidNoSleepEnabled = false
    private var lastCPUTicks: (user: Double, system: Double, idle: Double, nice: Double)?

    @Published var pomodoroPhase: PomodoroPhase = .work
    @Published var pomodoroTimeLeft: Int = PomodoroPhase.work.duration
    @Published var pomodoroIsRunning = false
    @Published var pomodoroWorkCount = 0
    @Published var todayFocusMinutes = 0
    @Published var todayPomodoroCount = 0
    @Published var systemUptime: String = ""
    @Published var systemVolume: Float = 0.5
    @Published var systemMuted = false

    @Published var volumeToastVisible = false
    @Published var volumeToastValue: Float = 0.5
    @Published var volumeToastMuted = false
    private var volumeToastWork: DispatchWorkItem?
    private var suppressNextVolumeToast = false

    @Published var keyboardToastVisible = false
    @Published var keyboardToastValue: Float = 0.5
    private var keyboardToastWork: DispatchWorkItem?
    private var keyboardLightLevel: Float = 0.5
    private var volumeRefreshWork: DispatchWorkItem?
    // osascript 写入约 240ms 才生效；连按音量键时读回值仍是旧的，不能直接回写。
    private var pendingVolumeTarget: Float?
    private var pendingVolumeSince: Date?
    private var pendingMuteTarget: Bool?
    private var pendingMuteSince: Date?
    private var volumeSetGeneration = 0
    private var mediaTick = 0
    private var mediaTickDate = Date()
    private var volumeListenerDevice: AudioObjectID = 0
    private var volumeListenerRegistered = false
    private var volumeMonitorsStarted = false

    @Published var droppedFiles: [FileItem] = []
    @Published var todoItems: [TodoItem] = []
    @Published var isDragTargeted = false

    @Published var converterFile: FileItem?
    @Published var converterFormats: [String] = []
    @Published var converterTarget: String = ""
    @Published var converterStatus: String = "请选择要转换的文件"
    @Published var converterWorking = false
    @Published var showConverterDone = false
    @Published var quickMsg: String?
    private var quickMsgWork: DispatchWorkItem?

    var cpuTempIndicatorColor: Color {
        if cpuTemp > 0 {
            if cpuTemp >= 80 { return .red }
            if cpuTemp >= 65 { return .orange }
            return .green
        }
        switch thermalLevel {
        case "适中": return .yellow
        case "偏高": return .orange
        case "过高": return .red
        default: return .green
        }
    }

    private var converterDoneWork: DispatchWorkItem?

    @Published var traeRunning = false
    private var traeTimer: Timer?
    @Published var aiTraeCodeRunning = false
    @Published var aiWorkbuddyInstalled = false
    @Published var aiWorkbuddyRunning = false
    @Published var aiClaudeInstalled = false
    @Published var aiClaudeRunning = false
    @Published var aiCodexInstalled = false
    @Published var aiCodexRunning = false
    @Published var aiUsage: [String: (cpu: Double, ramMB: Double)] = [:]
    @Published var aiGpuActive: [String: Bool] = [:]
    private var aiToolTimer: Timer?
    private var aiUsageLastAccum: [String: Double] = [:]
    private var aiUsageLastDate: Date?
    private var traeCPULastAccum = 0.0
    private var traeCPULastDate: Date?

    @Published var projectReminderEnabled = true
    @Published var projectReminderName = "Tree walk"
    @Published var showReminder = false
    private var traeWasBusy = false
    private var traeIdleStart: Date?
    private var traeBusySince: Date?
    private var lastReminderAt: Date = .distantPast
    private var reminderSilenceUntil: Date = .distantPast

    @Published var marqueeEnabled = true
    @Published var marqueeThemeIndex = 0
    @Published var marqueeSpeedIndex = 1
    @Published var marqueeCpuLinked = false

    struct MarqueeTheme {
        let name: String
        let colors: [Color]
        let core: Color
    }

    static let marqueeThemes: [MarqueeTheme] = [
        MarqueeTheme(name: "黑白", colors: [.white, Color(white: 0.5), .white], core: .white),
        MarqueeTheme(name: "纯白", colors: [.white], core: .white),
        MarqueeTheme(name: "蓝色", colors: [.lgCyan, .blue], core: .lgCyan),
        MarqueeTheme(name: "绿色", colors: [.lgMint, .green], core: .lgMint),
        MarqueeTheme(name: "紫色", colors: [.lgIndigo, .purple], core: .purple),
        MarqueeTheme(name: "橙色", colors: [.yellow, .orange], core: .orange),
        MarqueeTheme(name: "红色", colors: [.pink, .red], core: .red),
        MarqueeTheme(name: "青色", colors: [.lgTeal, .lgCyan], core: .lgTeal),
    ]

    var marqueeTheme: MarqueeTheme {
        let i = min(max(marqueeThemeIndex, 0), Self.marqueeThemes.count - 1)
        return Self.marqueeThemes[i]
    }

    var marqueeDuration: Double {
        switch marqueeSpeedIndex {
        case 0: return 4.5
        case 2: return 1.3
        default: return 2.5
        }
    }

    func setMarqueeEnabled(_ v: Bool) {
        marqueeEnabled = v
        saveMarqueeSettings()
    }

    func setMarqueeTheme(_ i: Int) {
        marqueeThemeIndex = i
        saveMarqueeSettings()
    }

    func setMarqueeSpeed(_ i: Int) {
        marqueeSpeedIndex = i
        saveMarqueeSettings()
    }

    func setMarqueeCpuLinked(_ v: Bool) {
        marqueeCpuLinked = v
        saveMarqueeSettings()
    }

    func setAppearanceCompactWidth(_ v: CGFloat) {
        appearanceCompactWidth = max(1, v)
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAppearanceCompactHeight(_ v: CGFloat) {
        appearanceCompactHeight = max(10, v)
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAppearanceExpandedWidth(_ v: CGFloat) {
        appearanceExpandedWidth = max(50, v)
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAppearanceExpandedHeight(_ v: CGFloat) {
        appearanceExpandedHeight = max(30, v)
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAppearanceOffsetX(_ v: CGFloat) {
        appearanceOffsetX = v
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAppearanceOffsetY(_ v: CGFloat) {
        appearanceOffsetY = v
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAppearanceScale(_ v: CGFloat) {
        appearanceScale = max(0.1, v)
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAppearanceCompactScale(_ v: CGFloat) {
        appearanceCompactScale = max(0.1, v)
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAuroraEnabled(_ v: Bool) {
        auroraEnabled = v
        saveAppearanceSettings()
    }
    func setAppearanceFontSize(_ v: CGFloat) {
        appearanceFontSize = max(9, min(v, 18))
        saveAppearanceSettings()
    }

    func setHudScale(_ v: CGFloat) {
        hudScale = max(0.7, min(v, 1.5))
        saveAppearanceSettings()
    }

    func setAppearanceCornerStyle(_ i: Int) {
        appearanceCornerStyle = i
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAppearanceShape(_ i: Int) {
        appearanceShape = min(max(i, 0), 1)
        saveAppearanceSettings()
        repositionWindow()
    }
    func setAppearanceTheme(_ i: Int) {
        appearanceTheme = i
        saveAppearanceSettings()
    }
    func resetAppearance() {
        appearanceCompactWidth = 0
        appearanceCompactHeight = 0
        appearanceExpandedWidth = 0
        appearanceExpandedHeight = 0
        appearanceOffsetX = 0
        appearanceOffsetY = -4
        appearanceCornerStyle = 0
        appearanceShape = 0
        appearanceTheme = 0
        appearanceScale = 1.0
        appearanceCompactScale = 0.9
        appearanceFontSize = 13
        hudScale = 1.0
        auroraEnabled = true
        backgroundCustomEnabled = false
        backgroundRed = 0
        backgroundGreen = 0
        backgroundBlue = 0
        saveAppearanceSettings()
        repositionWindow()
    }

    func repositionWindow() {
        (NSApp.delegate as? AppDelegate)?.repositionIsland()
    }

    func repositionWindowAnimated() {
        (NSApp.delegate as? AppDelegate)?.repositionIslandForExpandCollapse()
    }

    var islandBackground: Color {
        Color(red: backgroundRed, green: backgroundGreen, blue: backgroundBlue)
    }

    func setBackgroundCustomEnabled(_ v: Bool) {
        backgroundCustomEnabled = v
        saveAppearanceSettings()
    }

    func setBackgroundColor(red: Double, green: Double, blue: Double) {
        backgroundRed = max(0, min(1, red))
        backgroundGreen = max(0, min(1, green))
        backgroundBlue = max(0, min(1, blue))
        saveAppearanceSettings()
    }

    func pickBackgroundImage() {
        let panel = NSOpenPanel()
        panel.title = "选择背景图片"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .image]
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let img = NSImage(contentsOf: url) {
            backgroundImage = img
            backgroundImageEnabled = true
            UserDefaults.standard.set(url.path, forKey: "bgImagePath")
            saveAppearanceSettings()
        }
    }

    func setBackgroundImageEnabled(_ v: Bool) {
        backgroundImageEnabled = v
        saveAppearanceSettings()
    }

    private func loadAppearanceSettings() {
        let d = UserDefaults.standard
        if d.object(forKey: "appCompactW") != nil { appearanceCompactWidth = d.double(forKey: "appCompactW") }
        if d.object(forKey: "appCompactH") != nil { appearanceCompactHeight = d.double(forKey: "appCompactH") }
        if d.object(forKey: "appExpandW") != nil { appearanceExpandedWidth = d.double(forKey: "appExpandW") }
        if d.object(forKey: "appExpandH") != nil { appearanceExpandedHeight = d.double(forKey: "appExpandH") }
        if d.object(forKey: "appOffsetX") != nil { appearanceOffsetX = d.double(forKey: "appOffsetX") }
        if d.object(forKey: "appOffsetY") != nil { appearanceOffsetY = d.double(forKey: "appOffsetY") }
        appearanceCornerStyle = d.integer(forKey: "appCornerStyle")
        appearanceShape = min(d.integer(forKey: "appShape"), 1)
        appearanceTheme = d.integer(forKey: "appTheme")
        appearanceScale = 1.0
        if d.object(forKey: "appCompactScale") != nil { appearanceCompactScale = d.double(forKey: "appCompactScale") }
        if d.object(forKey: "appFontSize") != nil { appearanceFontSize = d.double(forKey: "appFontSize") }
        if d.object(forKey: "appHudScale") != nil { hudScale = d.double(forKey: "appHudScale") }
        if d.object(forKey: "auroraEnabled") != nil { auroraEnabled = d.bool(forKey: "auroraEnabled") }
        if d.object(forKey: "bgCustom") != nil { backgroundCustomEnabled = d.bool(forKey: "bgCustom") }
        if d.object(forKey: "bgR") != nil { backgroundRed = d.double(forKey: "bgR") }
        if d.object(forKey: "bgG") != nil { backgroundGreen = d.double(forKey: "bgG") }
        if d.object(forKey: "bgB") != nil { backgroundBlue = d.double(forKey: "bgB") }
        if d.object(forKey: "bgImgEnabled") != nil { backgroundImageEnabled = d.bool(forKey: "bgImgEnabled") }
        if let path = d.string(forKey: "bgImagePath"), !path.isEmpty {
            backgroundImage = NSImage(contentsOfFile: path)
        }
    }

    private func saveAppearanceSettings() {
        let d = UserDefaults.standard
        d.set(appearanceCompactWidth, forKey: "appCompactW")
        d.set(appearanceCompactHeight, forKey: "appCompactH")
        d.set(appearanceExpandedWidth, forKey: "appExpandW")
        d.set(appearanceExpandedHeight, forKey: "appExpandH")
        d.set(appearanceOffsetX, forKey: "appOffsetX")
        d.set(appearanceOffsetY, forKey: "appOffsetY")
        d.set(appearanceCornerStyle, forKey: "appCornerStyle")
        d.set(appearanceShape, forKey: "appShape")
        d.set(appearanceTheme, forKey: "appTheme")
        d.set(appearanceScale, forKey: "appScale")
        d.set(appearanceCompactScale, forKey: "appCompactScale")
        d.set(appearanceFontSize, forKey: "appFontSize")
        d.set(hudScale, forKey: "appHudScale")
        d.set(auroraEnabled, forKey: "auroraEnabled")
        d.set(backgroundCustomEnabled, forKey: "bgCustom")
        d.set(backgroundRed, forKey: "bgR")
        d.set(backgroundGreen, forKey: "bgG")
        d.set(backgroundBlue, forKey: "bgB")
        d.set(backgroundImageEnabled, forKey: "bgImgEnabled")
    }

    var marqueeEffectiveDuration: Double {
        guard marqueeCpuLinked else { return marqueeDuration }
        let factor = 1 + cpuLoad * 2.5
        return marqueeDuration / factor
    }

    private func loadToastSettings() {
        let d = UserDefaults.standard
        d.set(true, forKey: "toastVolume")
        d.set(true, forKey: "toastVolumeSuppress")
        volumeToastEnabled = true
        volumeKeySuppressEnabled = true
        airPodsToastEnabled = d.object(forKey: "toastAirPods") != nil ? d.bool(forKey: "toastAirPods") : true
        VolumeKeyInterceptor.shared.start()
        refreshVolumeSuppressStatus()
    }

    func setVolumeToastEnabled(_ v: Bool) {
        volumeToastEnabled = v
        UserDefaults.standard.set(v, forKey: "toastVolume")
        if !v { hideVolumeToast() }
    }

    func setVolumeKeySuppressEnabled(_ v: Bool) {
        volumeKeySuppressEnabled = v
        UserDefaults.standard.set(v, forKey: "toastVolumeSuppress")
        if v {
            VolumeKeyInterceptor.shared.start()
        } else {
            VolumeKeyInterceptor.shared.stop()
        }
        refreshVolumeSuppressStatus()
    }

    func forceReinstallInterceptor() {
        VolumeKeyInterceptor.shared.stop()
        VolumeKeyInterceptor.shared.start()
        refreshVolumeSuppressStatus()
    }

    func refreshVolumeSuppressStatus() {
        let interceptor = VolumeKeyInterceptor.shared
        if volumeSuppressPermitted != interceptor.hasPermission { volumeSuppressPermitted = interceptor.hasPermission }
        if volumeSuppressInstalled != interceptor.isInstalled { volumeSuppressInstalled = interceptor.isInstalled }
        if volumeSuppressEnabled != interceptor.isEnabled { volumeSuppressEnabled = interceptor.isEnabled }
        if volumeSuppressCount != interceptor.interceptCount { volumeSuppressCount = interceptor.interceptCount }
        if volumeSuppressEvents != interceptor.receivedEvents { volumeSuppressEvents = interceptor.receivedEvents }
    }

    func setAirPodsToastEnabled(_ v: Bool) {
        airPodsToastEnabled = v
        UserDefaults.standard.set(v, forKey: "toastAirPods")
    }

    func showVolumeToast(value: Float, muted: Bool) {
        guard volumeToastEnabled else { return }
        volumeToastWork?.cancel()
        let v = max(0, min(1, value))
        volumeToastValue = v
        volumeToastMuted = muted
        withAnimation(.easeOut(duration: 0.12)) {
            volumeToastVisible = true
        }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.volumeToastVisible = false }
        }
        volumeToastWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: work)
    }

    func hideVolumeToast() {
        volumeToastWork?.cancel()
        volumeToastWork = nil
        withAnimation(.easeOut(duration: 0.25)) { volumeToastVisible = false }
    }

    func showKeyboardToast(value: Float) {
        keyboardToastWork?.cancel()
        let v = max(0, min(1, value))
        keyboardToastValue = v
        withAnimation(.easeOut(duration: 0.12)) {
            keyboardToastVisible = true
        }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.keyboardToastVisible = false }
        }
        keyboardToastWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: work)
    }

    func hideKeyboardToast() {
        keyboardToastWork?.cancel()
        keyboardToastWork = nil
        withAnimation(.easeOut(duration: 0.25)) { keyboardToastVisible = false }
    }

    private func loadMarqueeSettings() {
        let d = UserDefaults.standard
        if d.object(forKey: "marqueeEnabled") != nil {
            marqueeEnabled = d.bool(forKey: "marqueeEnabled")
        } else if lowMemoryMode {
            marqueeEnabled = false
        }
        marqueeThemeIndex = d.integer(forKey: "marqueeThemeIndex")
        marqueeSpeedIndex = d.integer(forKey: "marqueeSpeedIndex")
        if d.object(forKey: "marqueeCpuLinked") != nil { marqueeCpuLinked = d.bool(forKey: "marqueeCpuLinked") }
    }

    private func saveMarqueeSettings() {
        let d = UserDefaults.standard
        d.set(marqueeEnabled, forKey: "marqueeEnabled")
        d.set(marqueeThemeIndex, forKey: "marqueeThemeIndex")
        d.set(marqueeSpeedIndex, forKey: "marqueeSpeedIndex")
        d.set(marqueeCpuLinked, forKey: "marqueeCpuLinked")
    }

    static func marqueeStops(colors: [Color], highlight: Double, spread: Double) -> [Gradient.Stop] {
        var stops: [Gradient.Stop] = [.init(color: .clear, location: 0)]
        let n = colors.count
        for i in 0..<n {
            let loc = highlight - spread / 2 + spread * Double(i) / Double(max(n - 1, 1))
            stops.append(.init(color: colors[i], location: max(0, min(1, loc))))
        }
        stops.append(.init(color: .clear, location: min(1, highlight + spread / 2 + 0.03)))
        stops.append(.init(color: .clear, location: 1))
        return stops
    }

    private var pollTimer: Timer?
    private var clockTimer: Timer?
    private var uptimeTimer: Timer?
    private var batteryTimer: Timer?
    private var pomodoroTimer: Timer?
    private var mediaTicker: Timer?
    private var autoCollapseWork: DispatchWorkItem?
    private var pageDotsHideWork: DispatchWorkItem?
    private var observers: [NSObjectProtocol] = []
    private var tempTimer: Timer?
    private var lidProcess: Process?

    // macOS 15.4+ MediaRemote 限制：非 Apple 签名二进制调用返回空，需通过 /usr/bin/swift 辅助进程读取
    private var helperProcess: Process?
    private var helperInput: Pipe?
    private var helperBuffer = Data()
    private var helperStarted = false

    static let shared = AppState()

    private init() {
        startupLog("AppState.init 开始")
        loadApps()
        startupLog("loadApps 完成")
        loadFiles()
        startupLog("loadFiles 完成")
        startMediaRemote()
        startupLog("startMediaRemote 完成")
        startClock()
        startupLog("startClock 完成")
        startBattery()
        startupLog("startBattery 完成")
        refreshVolume()
        startupLog("refreshVolume 完成")
        startVolumeMonitor()
        startupLog("startVolumeMonitor 完成")
        checkLaunchAtLogin()
        startupLog("checkLaunchAtLogin 完成")
        startTempMonitor()
        startupLog("startTempMonitor 完成")
        startTraeMonitor()
        startupLog("startTraeMonitor 完成")
        startAIToolMonitor()
        startupLog("startAIToolMonitor 完成")
        startAirPodsMonitor()
        startupLog("startAirPodsMonitor 完成")
        loadMarqueeSettings()
        loadAppearanceSettings()
        loadToastSettings()
        loadPageOrder()
        loadTodos()
        loadTeleprompterDocList()
        loadPageLayouts()
        if let al = UserDefaults.standard.string(forKey: "appLanguage"), !al.isEmpty { appLanguage = al }
        startupLog("设置加载完成")
        if UserDefaults.standard.object(forKey: "projectReminderEnabled") != nil {
            projectReminderEnabled = UserDefaults.standard.bool(forKey: "projectReminderEnabled")
        }
        if let saved = UserDefaults.standard.string(forKey: "projectReminderName"), !saved.isEmpty {
            projectReminderName = saved
        }
    }

    func checkLaunchAtLogin() {
        let service = SMAppService.mainApp
        launchAtLogin = (service.status == .enabled || service.status == .requiresApproval)
    }

    func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        if launchAtLogin {
            try? service.unregister()
        } else {
            try? service.register()
        }
        checkLaunchAtLogin()
    }

    @Published var appearanceCompactWidth: CGFloat = 0
    @Published var appearanceCompactHeight: CGFloat = 0
    @Published var appearanceExpandedWidth: CGFloat = 0
    @Published var appearanceExpandedHeight: CGFloat = 0
    @Published var appearanceOffsetX: CGFloat = 0
    @Published var appearanceOffsetY: CGFloat = -4
    @Published var appearanceCornerStyle: Int = 0
    @Published var appearanceShape: Int = 0
    @Published var appearanceTheme: Int = 0
    @Published var appearanceScale: CGFloat = 1.0
    @Published var appearanceCompactScale: CGFloat = 0.9
    @Published var appearanceFontSize: CGFloat = 13
    @Published var hudScale: CGFloat = 1.0

    @Published var auroraEnabled = true

    @Published var backgroundCustomEnabled = false
    @Published var backgroundRed: Double = 0
    @Published var backgroundGreen: Double = 0
    @Published var backgroundBlue: Double = 0
    @Published var backgroundImageEnabled = false
    @Published var backgroundImage: NSImage?

    var fontScale: CGFloat {
        let base: CGFloat
        let def: CGFloat
        if isExpanded {
            base = expandedWidth
            def = 480
        } else {
            base = compactWidth
            def = max(geometry.notchWidth + 140, 200)
        }
        let r = base / def
        return max(r, 0.85) * (appearanceFontSize / 13)
    }

    var compactContentHeight: CGFloat {
        max(18, appearanceFontSize * 1.2)
    }
    var compactInset: CGFloat {
        max((compactHeight - compactContentHeight) / 2, 6)
    }

    var cornerRadiusMultiplier: CGFloat {
        switch appearanceCornerStyle {
        case 1: return 1.4
        case 2: return 0.55
        default: return 1.0
        }
    }

    var radiusWindow: CGFloat { 26 * cornerRadiusMultiplier }
    var radiusPanel: CGFloat { 18 * cornerRadiusMultiplier }
    var radiusControl: CGFloat { 9 * cornerRadiusMultiplier }
    var radiusItem: CGFloat { 8 * cornerRadiusMultiplier }

    var deviceModel: String {
        if _deviceModel.isEmpty {
            var mib = [CTL_HW, HW_MACHINE]
            var size = 0
            sysctl(&mib, 2, nil, &size, nil, 0)
            var buf = [CChar](repeating: 0, count: size)
            sysctl(&mib, 2, &buf, &size, nil, 0)
            _deviceModel = String(cString: buf)
        }
        return _deviceModel
    }
    private var _deviceModel = ""

    var notchShapeScale: CGFloat {
        let m = deviceModel
        if m.hasPrefix("MacBookAir") { return 0.66 }
        if m.hasPrefix("MacBookPro") { return 0.72 }
        return 0.7
    }

    var compactWidth: CGFloat {
        let auto: CGFloat
        if appearanceShape == 1 {
            auto = 132
        } else {
            auto = max(geometry.notchWidth + 140, 200)
        }
        guard appearanceCompactWidth > 0 else { return auto }
        return max(appearanceCompactWidth, 1)
    }
    var compactHeight: CGFloat {
        let auto: CGFloat
        if appearanceShape == 1 {
            auto = 44
        } else {
            auto = max(geometry.notchHeight, 44)
        }
        guard appearanceCompactHeight > 0 else { return auto }
        return max(appearanceCompactHeight, 10)
    }
    var expandedWidth: CGFloat {
        let base = appearanceExpandedWidth > 0 ? appearanceExpandedWidth : 512
        let cfg = pageLayouts[currentPage] ?? PageLayoutConfig()
        return max(cfg.customSize && cfg.width > 0 ? cfg.width : base, 50)
    }
    var expandedHeight: CGFloat {
        let base = appearanceExpandedHeight > 0 ? appearanceExpandedHeight : 292
        let cfg = pageLayouts[currentPage] ?? PageLayoutConfig()
        return max(cfg.customSize && cfg.height > 0 ? cfg.height : base, 30)
    }
    var currentPageStyleScale: CGFloat {
        switch (pageLayouts[currentPage] ?? PageLayoutConfig()).style {
        case 1: return 0.85
        case 2: return 1.15
        default: return 1.0
        }
    }
    func isBlockHidden(_ id: String) -> Bool {
        let page = visiblePages.indices.contains(currentPage) ? visiblePages[currentPage] : currentPage
        return (pageLayouts[page] ?? PageLayoutConfig()).hiddenBlocks.contains(id)
    }
    var windowWidth: CGFloat {
        return (expandedWidth + 24) * appearanceScale
    }
    var windowHeight: CGFloat { (expandedHeight + max(geometry.notchHeight + 4, 36) + menuBarHeight) * appearanceScale }
    var compactRadius: CGFloat {
        if appearanceShape == 1 { return compactHeight / 2 }
        return max(compactHeight / 2, 14) * cornerRadiusMultiplier
    }
    var expandedRadius: CGFloat { radiusWindow }
    var notchGap: CGFloat {
        if appearanceShape == 1 { return 0 }
        return geometry.notchWidth / appearanceScale
    }
    var pageContentWidth: CGFloat { expandedWidth - 24 }
    var notchPadding: CGFloat {
        if appearanceShape == 1 { return 2 }
        return max(max(geometry.notchHeight, 0) + 2, menuBarHeight + 4)
    }

    var menuBarHeight: CGFloat {
        guard let s = hostScreen ?? NSScreen.main else { return 24 }
        let h = s.frame.maxY - s.visibleFrame.maxY
        return h > 0 ? h : 24
    }

    var lowMemoryMode: Bool {
        ProcessInfo.processInfo.physicalMemory <= 6_442_450_944
    }
    var contentHeight: CGFloat { expandedHeight - 14 - notchPadding }
    var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    var totalFileSize: Int64 { droppedFiles.reduce(0) { $0 + $1.size } }

    func islandRect(expanded: Bool) -> NSRect {
        let w = expanded ? expandedWidth : compactWidth
        let h = expanded ? expandedHeight : compactHeight
        let x = (windowWidth - w) / 2
        let y = windowHeight - h
        return NSRect(x: x, y: y, width: w, height: h)
    }

    private var configDir: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("IsleX", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var configURL: URL { configDir.appendingPathComponent("apps.json") }

    private var fileStationDir: URL {
        let dir = configDir.appendingPathComponent("FileStation", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func startMediaRemote() {
#if NOSMTC
        startupLog("无 SMTC 构建：AppleScript + CDP + plist/archive 直连媒体检测")
        startApplescriptPolling()
        DispatchQueue.main.async {
            KuGouPlistPoller.shared.start()
            QQMusicArchivePoller.shared.start()
            NeteaseCDPClient.shared.start()
        }
#else
        if MRMediaRemoteIsAvailable() {
            startupLog("MR 框架可用，使用 MediaRemote")
            startMediaRemotePolling()
        } else {
            startupLog("MR 框架不可用，使用 AppleScript + 键盘模拟")
            startApplescriptPolling()
        }
#endif
    }

#if !NOSMTC
    private func startMediaRemotePolling() {
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        startupLog("MR 注册通知后")
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: NSNotification.Name(kInfoDidChange), object: nil, queue: .main) { [weak self] _ in
            self?.fetchInfo()
        })
        observers.append(center.addObserver(forName: NSNotification.Name(kAppDidChange), object: nil, queue: .main) { [weak self] _ in
            self?.fetchInfo()
        })
        observers.append(center.addObserver(forName: NSNotification.Name(kPlayingDidChange), object: nil, queue: .main) { [weak self] _ in self?.fetchPlaying() })
        startupLog("MR fetchInfo 前")
        fetchInfo()
        startupLog("MR fetchInfo 后")
        fetchPlaying()
        startupLog("MR fetchPlaying 后")
        startHelperIfNeeded()
        startupLog("MR helper 后")
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isTransitioning else { return }
            self.fetchInfo()
        }
        mediaTicker = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            guard self.nowPlaying.isPlaying, self.nowPlaying.hasMedia else { self.mediaTickDate = now; return }
            guard !self.isTransitioning else { self.mediaTickDate = now; return }
            self.mediaTick &+= 1
            if !self.mediaPageVisible && self.mediaTick % 10 != 0 { return }
            let dt = min(max(now.timeIntervalSince(self.mediaTickDate), 0), 1.2)
            self.mediaTickDate = now
            var np = self.nowPlaying
            np.elapsed += dt
            if np.duration > 0 && np.elapsed > np.duration { np.elapsed = np.duration }
            self.nowPlaying = np
        }
        // macOS 26/27 上 MR 可能静默失效，启动后定期检测并切到 AppleScript。
        checkMRDeadAndFallback()
    }

    private func checkMRDeadAndFallback() {
        if mediaRemoteBroken { return }
        if mrDeliveredAnyData { return }
        guard #available(macOS 26.0, *) else { return }
        guard mediaAppRunning() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.checkMRDeadAndFallback()
            }
            return
        }
        startupLog("MR 在 macOS 26+ 返回空数据，切换到 AppleScript 轮询")
        mediaRemoteBroken = true
        switchToAppleScriptPolling()
    }

    private func mediaAppRunning() -> Bool {
        let ids = ["com.apple.Music", "com.spotify.client", "com.netease.163music",
                   "com.apple.QuickTimePlayerX", "com.apple.iTunes", "com.tencent.QQMusicMac",
                   "com.kugou.kugouMac", "com.kugou.mac.Music", "com.apple.podcasts", "com.apple.tv"]
        return ids.contains { NSRunningApplication.runningApplications(withBundleIdentifier: $0).first != nil }
    }

    private func switchToAppleScriptPolling() {
        pollTimer?.invalidate(); pollTimer = nil
        mediaTicker?.invalidate(); mediaTicker = nil
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        helperInput?.fileHandleForWriting.closeFile()
        helperProcess?.terminate()
        helperProcess = nil
        helperInput = nil
        helperStarted = false
        startApplescriptPolling()
        // 酷狗没有 AppleScript 接口，直接读 plist；这里仍在 AppState.shared 初始化中，
        // 立即访问 KuGouPlistPoller.shared 会递归等待 dispatch_once，所以延后到主循环。
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.mediaRemoteBroken else { return }
            KuGouPlistPoller.shared.start()
            NeteaseCDPClient.shared.start()
        }
    }
#endif // !NOSMTC

    private func startApplescriptPolling() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.appleScriptFetchInfo()
        }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.isTransitioning else { return }
            self.idlePollTick &+= 1
            if !self.nowPlaying.hasMedia && self.idlePollTick % 4 != 0 { return }
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.appleScriptFetchInfo()
            }
        }
        mediaTicker = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            guard self.nowPlaying.isPlaying, self.nowPlaying.hasMedia else { self.mediaTickDate = now; return }
            guard !self.isTransitioning else { self.mediaTickDate = now; return }
            self.mediaTick &+= 1
            if !self.mediaPageVisible && self.mediaTick % 10 != 0 { return }
            let dt = min(max(now.timeIntervalSince(self.mediaTickDate), 0), 1.2)
            self.mediaTickDate = now
            var np = self.nowPlaying
            np.elapsed += dt
            if np.duration > 0 && np.elapsed > np.duration { np.elapsed = np.duration }
            self.nowPlaying = np
        }
    }

#if !NOSMTC
    func fetchInfo() {
        if mediaRemoteBroken { return }
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] dict in
            guard let self = self, !self.mediaRemoteBroken else { return }
            let d = dict as? [String: Any]
            if d == nil || d!.isEmpty {
                self.startHelperIfNeeded()
            }
            self.handleInfo(d)
        }
    }

    private func handleInfo(_ d: [String: Any]?) {
        guard let d = d else { return }
        let now = Date()
        if now.timeIntervalSince(lastNowPlayingUpdate) < 0.1 { return }
        lastNowPlayingUpdate = now
        var np = nowPlaying
        let newTitle = (d[kTitle] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let newArtist = (d[kArtist] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let songChanged = (newTitle != nil && newTitle != np.title) || (newArtist != nil && newArtist != np.artist)
        if let t = newTitle { np.title = t }
        if let a = newArtist { np.artist = a }
        if let al = d[kAlbum] as? String, !al.isEmpty { np.album = al }
        if let dur = d[kDuration] as? Double, dur > 0 { np.duration = dur }
        if let el = d[kElapsed] as? Double {
            if el > np.elapsed + 0.3 || (songChanged && el < np.elapsed - 2.0) {
                np.elapsed = el
            }
        }
        if let r = d[kRate] as? Double {
            np.rate = r
            if r > 0 { np.isPlaying = smoothedPlaying(true) }
        }
        if let data = d[kArtwork] as? Data, let img = NSImage(data: data) {
            np.artwork = img
        }
        let hasAny = (d[kTitle] as? String)?.isEmpty == false
            || (d[kDuration] as? Double ?? 0) > 0
            || (d[kRate] as? Double ?? 0) > 0
        if hasAny { mrDeliveredAnyData = true }
        if !hasAny {
            np.title = ""
            np.artist = ""
            np.album = ""
            np.artwork = nil
            np.duration = 0
            np.rate = 0
        }
        if np.title != nowPlaying.title || np.artist != nowPlaying.artist {
            nowPlaying = np
            fetchLyrics()
        } else {
            nowPlaying = np
        }
    }
#endif // !NOSMTC

    var lastNowPlayingUpdate = Date.distantPast

    private var playingFalseStreak = 0

#if !NOSMTC
    private func smoothedPlaying(_ raw: Bool) -> Bool {
        if raw { playingFalseStreak = 0; return true }
        playingFalseStreak += 1
        return playingFalseStreak < 2
    }

    func fetchPlaying() {
        if mediaRemoteBroken { return }
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { [weak self] playing in
            guard let self = self, !self.mediaRemoteBroken else { return }
            self.handlePlaying(playing)
        }
    }

    private func handlePlaying(_ playing: Bool) {
        let p = smoothedPlaying(playing)
        guard p != nowPlaying.isPlaying else { return }
        var np = nowPlaying
        np.isPlaying = p
        nowPlaying = np
    }
#endif // !NOSMTC

#if !NOSMTC
    func startHelperIfNeeded() {
        guard !helperStarted else { return }
        helperStarted = true
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/swift") else { return }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let xcodeSelect = Process()
            xcodeSelect.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
            xcodeSelect.arguments = ["-p"]
            xcodeSelect.standardOutput = FileHandle.nullDevice
            xcodeSelect.standardError = FileHandle.nullDevice
            do { try xcodeSelect.run() } catch { self?.helperStarted = false; return }
            xcodeSelect.waitUntilExit()
            guard xcodeSelect.terminationStatus == 0 else { self?.helperStarted = false; return }
            DispatchQueue.main.async { [weak self] in
                self?.launchHelperProcess()
            }
        }
    }

    private func launchHelperProcess() {
        guard helperStarted else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
        process.arguments = ["-e", Self.helperSource]
        let output = Pipe()
        let input = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        process.standardInput = input
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.consumeHelperOutput(data)
        }
        process.terminationHandler = { [weak self] _ in
            self?.helperProcess = nil
            self?.helperInput = nil
        }
        do {
            try process.run()
            helperProcess = process
            helperInput = input
        } catch {
            helperStarted = false
        }
    }

    private func consumeHelperOutput(_ data: Data) {
        helperBuffer.append(data)
        while let newline = helperBuffer.firstIndex(of: 10) {
            let line = helperBuffer[helperBuffer.startIndex..<newline]
            helperBuffer.removeSubrange(helperBuffer.startIndex...newline)
            guard let json = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any] else { continue }
            DispatchQueue.main.async { [weak self] in
                self?.applyHelperPayload(json)
            }
        }
    }

    private func applyHelperPayload(_ json: [String: Any]) {
        let now = Date()
        if now.timeIntervalSince(lastNowPlayingUpdate) < 0.1 { return }
        lastNowPlayingUpdate = now
        var np = nowPlaying
        let newTitle = (json["title"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let newArtist = (json["artist"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let songChanged = (newTitle != nil && newTitle != np.title) || (newArtist != nil && newArtist != np.artist)
        if let t = newTitle { np.title = t }
        if let a = newArtist { np.artist = a }
        if let al = json["album"] as? String { np.album = al }
        if let el = json["elapsed"] as? Double {
            if el > np.elapsed + 0.3 || (songChanged && el < np.elapsed - 2.0) {
                np.elapsed = el
            }
        }
        if let dur = json["duration"] as? Double { np.duration = dur }
        if let isPlaying = json["isPlaying"] as? Bool {
            let p = smoothedPlaying(isPlaying)
            np.isPlaying = p
            np.rate = p ? 1 : 0
        }
        if let appName = json["appName"] as? String, !appName.isEmpty { nowPlayingApp = appName }
        if !np.title.isEmpty { mrDeliveredAnyData = true }
        if let b64 = json["artworkBase64"] as? String, let data = Data(base64Encoded: b64), let img = NSImage(data: data) {
            np.artwork = img
        }
        if np.title != nowPlaying.title || np.artist != nowPlaying.artist {
            nowPlaying = np
            fetchLyrics()
        } else {
            nowPlaying = np
        }
    }

#endif // !NOSMTC

    private var lastLyricQuery = ""

    func fetchLyrics() {
        let query = "\(nowPlaying.title) \(nowPlaying.artist)".trimmingCharacters(in: .whitespaces)
        guard !nowPlaying.title.isEmpty, query != lastLyricQuery else { return }
        lastLyricQuery = query
        var np = nowPlaying
        np.lyrics = []
        nowPlaying = np
        lyricState = .loading
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://music.163.com/api/search/get/web?s=\(encoded)&type=1") else {
            lyricState = .notFound
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 8
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self,
                  self.currentLyricQuery() == query,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = json["result"] as? [String: Any],
                  let songs = result["songs"] as? [[String: Any]],
                  let first = Self.bestMatch(songs, title: self.nowPlaying.title, artist: self.nowPlaying.artist),
                  let id = first["id"] as? Int else {
                DispatchQueue.main.async {
                    guard let self = self, self.currentLyricQuery() == query else { return }
                    self.lyricState = .notFound
                }
                return
            }
            self.fetchLyric(id: id, forQuery: query)
        }.resume()
    }

    private func currentLyricQuery() -> String {
        "\(nowPlaying.title) \(nowPlaying.artist)".trimmingCharacters(in: .whitespaces)
    }

    private static func bestMatch(_ songs: [[String: Any]], title: String, artist: String) -> [String: Any]? {
        func score(_ song: [String: Any]) -> Int {
            let name = (song["name"] as? String) ?? ""
            let artists = ((song["artists"] as? [[String: Any]]) ?? []).compactMap { $0["name"] as? String }
            var s = 0
            let t = title.lowercased(), n = name.lowercased()
            if !n.isEmpty {
                if n == t { s += 3 }
                else if n.contains(t) || t.contains(n) { s += 2 }
            }
            let a = artist.lowercased()
            if !a.isEmpty, artists.contains(where: { a.contains($0.lowercased()) || $0.lowercased().contains(a) }) { s += 2 }
            return s
        }
        return songs.max { score($0) < score($1) }
    }

    private func fetchLyric(id: Int, forQuery: String) {
        guard let url = URL(string: "https://music.163.com/api/song/lyric?id=\(id)&lv=1&kv=1&tv=-1") else {
            DispatchQueue.main.async { self.lyricState = .notFound }
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 8
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self,
                  self.currentLyricQuery() == forQuery,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let lrc = json["lrc"] as? [String: Any],
                  let lyric = lrc["lyric"] as? String else { return }
            let parsed = Self.parseLRC(lyric)
            DispatchQueue.main.async {
                guard self.currentLyricQuery() == forQuery else { return }
                if parsed.isEmpty {
                    self.lyricState = .notFound
                } else {
                    var np = self.nowPlaying
                    np.lyrics = parsed
                    self.nowPlaying = np
                    self.lyricState = .loaded
                }
            }
        }.resume()
    }

    static func parseLRC(_ lrc: String) -> [LyricLine] {
        var result: [LyricLine] = []
        let pattern = #"\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]"#
        for line in lrc.components(separatedBy: "\n") {
            var rest = line
            var times: [Double] = []
            while let range = rest.range(of: pattern, options: .regularExpression) {
                let match = String(rest[range])
                let inner = match.dropFirst().dropLast()
                let comps = inner.split(separator: ":")
                if comps.count == 2 {
                    let min = Double(comps[0]) ?? 0
                    let secParts = String(comps[1]).split(separator: ".")
                    let sec = Double(secParts[0]) ?? 0
                    let frac = secParts.count > 1 ? Double("0.\(secParts[1])") ?? 0 : 0
                    times.append(min * 60 + sec + frac)
                }
                rest.removeSubrange(range)
            }
            let text = rest.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                for t in times {
                    result.append(LyricLine(time: t, text: text))
                }
            }
        }
        return result.sorted { $0.time < $1.time }
    }

#if !NOSMTC
    private static let helperSource = #"""
    import AppKit
    import Foundation

    typealias CopyNowPlayingInfo = @convention(c) (DispatchQueue, @escaping (NSDictionary) -> Void) -> Void
    typealias GetNowPlayingApplicationPID = @convention(c) (DispatchQueue, @escaping (Int32) -> Void) -> Void
    typealias RegisterForNotifications = @convention(c) (DispatchQueue) -> Void

    func stringValue(_ info: NSDictionary, _ key: String) -> String {
        if let value = info[key] as? String { return value }
        if let value = info[key] as? NSString { return value as String }
        return ""
    }
    func numberValue(_ info: NSDictionary, _ key: String) -> Double {
        if let value = info[key] as? NSNumber { return value.doubleValue }
        if let value = info[key] as? Double { return value }
        if let value = info[key] as? String, let number = Double(value) { return number }
        return 0
    }

    guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else { exit(2) }
    guard let copySymbol = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else { exit(2) }
    let copyInfo = unsafeBitCast(copySymbol, to: CopyNowPlayingInfo.self)
    let getPIDSymbol = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationPID")
    let getPID: GetNowPlayingApplicationPID? = getPIDSymbol.map { unsafeBitCast($0, to: GetNowPlayingApplicationPID.self) }
    let workQueue = DispatchQueue(label: "islex.helper")

    func emit(includeArtwork: Bool) {
        let group = DispatchGroup()
        var info = NSDictionary()
        var pid: Int32 = 0
        group.enter()
        copyInfo(workQueue) { dictionary in
            info = dictionary
            group.leave()
        }
        if let getPID = getPID {
            group.enter()
            getPID(workQueue) { value in
                pid = value
                group.leave()
            }
        }
        guard group.wait(timeout: .now() + 1) == .success else { return }
        let title = stringValue(info, "kMRMediaRemoteNowPlayingInfoTitle")
        guard !title.isEmpty else { return }
        let rate = numberValue(info, "kMRMediaRemoteNowPlayingInfoPlaybackRate")
        let artwork = includeArtwork
            ? (info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data)?.base64EncodedString() ?? ""
            : ""
        let payload: [String: Any] = [
            "title": title,
            "artist": stringValue(info, "kMRMediaRemoteNowPlayingInfoArtist"),
            "album": stringValue(info, "kMRMediaRemoteNowPlayingInfoAlbum"),
            "artworkBase64": artwork,
            "elapsed": numberValue(info, "kMRMediaRemoteNowPlayingInfoElapsedTime"),
            "duration": numberValue(info, "kMRMediaRemoteNowPlayingInfoDuration"),
            "isPlaying": rate > 0,
            "appName": NSRunningApplication(processIdentifier: pid)?.localizedName ?? ""
        ]
        guard var data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        data.append(10)
        FileHandle.standardOutput.write(data)
    }

    var emitScheduled = false
    func scheduleEmit() {
        guard !emitScheduled else { return }
        emitScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitScheduled = false
            emit(includeArtwork: true)
        }
    }

    DispatchQueue.global().async {
        while !FileHandle.standardInput.availableData.isEmpty {}
        exit(0)
    }

    if let registerSymbol = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
        unsafeBitCast(registerSymbol, to: RegisterForNotifications.self)(DispatchQueue.main)
        let names = [
            "kMRMediaRemoteNowPlayingInfoDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification",
            "kMRMediaRemoteNowPlayingApplicationDidChangeNotification"
        ]
        for name in names {
            NotificationCenter.default.addObserver(
                forName: Notification.Name(name),
                object: nil,
                queue: .main
            ) { _ in
                scheduleEmit()
            }
        }
    }
    scheduleEmit()
    Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
        emit(includeArtwork: false)
    }
    RunLoop.main.run()
    """#
#endif // !NOSMTC

    func sendCommand(_ cmd: Int32) {
        if mockMediaEnabled { mockSendCommand(cmd); return }
        if cmd == MRCommand.togglePlayPause || cmd == MRCommand.play {
            let mediaBundleIds = ["com.apple.Music", "com.spotify.client", "com.netease.163music",
                                  "com.apple.QuickTimePlayerX", "com.apple.iTunes", "com.tencent.QQMusicMac",
                                  "com.kugou.mac.Music", "com.google.android.music",
                                  "com.apple.podcasts", "com.apple.tv"]
            let anyRunning = mediaBundleIds.contains { id in
                NSRunningApplication.runningApplications(withBundleIdentifier: id).first != nil
            }
            guard anyRunning else { return }
        }
        if nowPlayingApp == NeteaseCDPClient.bundleId, NeteaseCDPClient.shared.sendControl(cmd) { return }
#if NOSMTC
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.appleScriptSendCommand(cmd) {
                self.simulateMediaKey(cmd)
            }
        }
#else
        if MRMediaRemoteIsAvailable() && !mediaRemoteBroken {
            MRMediaRemoteSendCommand(cmd, nil)
        } else {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                if !self.appleScriptSendCommand(cmd) {
                    self.simulateMediaKey(cmd)
                }
            }
        }
#endif
    }

    private var mediaRemoteConfirmedUnavailable = false
    private var mediaRemoteBroken = false
    private var mrDeliveredAnyData = false
    private var idlePollTick = 0
    private let mediaQueryLock = NSLock()
    private var mediaQueryInFlight = false
    private var mediaStartedAt: [String: Date] = [:]
    private var mediaWasPlaying: [String: Bool] = [:]
    private var lastAppleArbLog = Date.distantPast

    func notePlaying(_ bundle: String, _ playing: Bool) {
        let was = mediaWasPlaying[bundle] ?? false
        if playing && !was { mediaStartedAt[bundle] = Date() }
        mediaWasPlaying[bundle] = playing
    }

    func startedLater(_ a: String, than b: String) -> Bool {
        (mediaStartedAt[a] ?? .distantPast) > (mediaStartedAt[b] ?? .distantPast)
    }

    func playedNotLaterThan(_ a: String, than b: String) -> Bool {
        (mediaStartedAt[a] ?? .distantPast) <= (mediaStartedAt[b] ?? .distantPast)
    }

    private func appleScriptFetchInfo() {
        guard !mediaRemoteConfirmedUnavailable else { return }
        mediaQueryLock.lock()
        if mediaQueryInFlight { mediaQueryLock.unlock(); return }
        mediaQueryInFlight = true
        mediaQueryLock.unlock()
        defer {
            mediaQueryLock.lock()
            mediaQueryInFlight = false
            mediaQueryLock.unlock()
        }
        let scripts: [(String, String)] = [
            ("com.apple.Music", """
                tell application "Music"
                    if player state is playing or player state is paused then
                        set trackName to name of current track
                        set artistName to artist of current track
                        set albumName to album of current track
                        set trackDuration to duration of current track
                        set playerPos to player position
                        set isPlay to (player state is playing)
                        return trackName & "|" & artistName & "|" & albumName & "|" & trackDuration & "|" & playerPos & "|" & isPlay
                    end if
                end tell
                """),
            ("com.spotify.client", """
                tell application "Spotify"
                    if player state is not stopped then
                        set trackName to name of current track
                        set artistName to artist of current track
                        set albumName to album of current track
                        set trackDuration to (duration of current track) / 1000
                        set playerPos to player position
                        set isPlay to (player state is playing)
                        return trackName & "|" & artistName & "|" & albumName & "|" & trackDuration & "|" & playerPos & "|" & isPlay
                    end if
                end tell
                """),
            ("com.apple.QuickTimePlayerX", """
                tell application "QuickTime Player"
                    if (count of documents) > 0 then
                        set trackName to name of front document
                        set trackDuration to duration of front document
                        set playerPos to current time of front document
                        set isPlay to (playing of front document)
                        return trackName & "|" & "" & "|" & "" & "|" & trackDuration & "|" & playerPos & "|" & isPlay
                    end if
                end tell
                """),
            ("com.apple.tv", """
                tell application "TV"
                    if player state is playing or player state is paused then
                        set trackName to name of current track
                        set artistName to artist of current track
                        set albumName to album of current track
                        set trackDuration to duration of current track
                        set playerPos to player position
                        set isPlay to (player state is playing)
                        return trackName & "|" & artistName & "|" & albumName & "|" & trackDuration & "|" & playerPos & "|" & isPlay
                    end if
                end tell
                """),
        ]
        for (bundleId, script) in scripts {
            guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first != nil else { continue }
            guard let result = runAppleScript(script), !result.isEmpty else { continue }
            let parts = result.components(separatedBy: "|")
            guard parts.count >= 6 else { continue }
            let title = parts[0].trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            let artist = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
            let album = parts.count > 2 ? parts[2].trimmingCharacters(in: .whitespaces) : ""
            let duration = Double(parts[3].trimmingCharacters(in: .whitespaces)) ?? 0
            let elapsed = Double(parts[4].trimmingCharacters(in: .whitespaces)) ?? 0
            let isPlaying = parts[5].trimmingCharacters(in: .whitespaces) == "true"
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let now = Date()
                if now.timeIntervalSince(self.lastNowPlayingUpdate) < 0.1 { return }
                self.lastNowPlayingUpdate = now
                self.notePlaying(bundleId, isPlaying)
                let cur = self.nowPlayingApp
                if cur != bundleId {
                    if isPlaying {
                        if self.nowPlaying.isPlaying && self.startedLater(cur, than: bundleId) {
                            if Date().timeIntervalSince(self.lastAppleArbLog) > 3 {
                                self.lastAppleArbLog = Date()
                                startupLog("AppleScript 仲裁：\(bundleId) 让位（当前 \(cur) 在播且更晚开启）")
                            }
                            return
                        }
                    } else {
                        if self.nowPlaying.isPlaying { return }
                        if !self.nowPlayingApp.isEmpty && self.playedNotLaterThan(bundleId, than: cur) { return }
                    }
                }
                var np = self.nowPlaying
                let songChanged = title != np.title || artist != np.artist
                np.title = title
                np.artist = artist
                np.album = album
                if duration > 0 { np.duration = duration }
                if elapsed > np.elapsed + 0.3 || (songChanged && elapsed < np.elapsed - 2.0) {
                    np.elapsed = elapsed
                }
                np.isPlaying = isPlaying
                np.rate = isPlaying ? 1 : 0
                self.nowPlayingApp = bundleId
                if songChanged {
                    startupLog("AppleScript 媒体更新：\(title) - \(artist)（\(bundleId)）")
                    self.nowPlaying = np
                    self.fetchLyrics()
                    if bundleId == "com.apple.Music" { self.fetchMusicArtwork(forTitle: title) }
                    if bundleId == "com.spotify.client" { self.fetchSpotifyArtwork(forTitle: title) }
                } else {
                    self.nowPlaying = np
                }
            }
            return
        }
    }

    private func fetchMusicArtwork(forTitle: String) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let path = "/tmp/islex_music_artwork.bin"
            try? FileManager.default.removeItem(atPath: path)
            let script = """
                tell application "Music"
                    if player state is playing or player state is paused then
                        set t to current track
                        if (count of artworks of t) > 0 then
                            set d to data of artwork 1 of t
                            set p to POSIX file "\(path)"
                            try
                                set f to open for access p with write permission
                                set eof f to 0
                                write d to f
                                close access f
                                return "OK"
                            on error
                                try
                                    close access p
                                end try
                            end try
                        end if
                    end if
                end tell
                return ""
                """
            guard self.runAppleScript(script) == "OK",
                  let data = FileManager.default.contents(atPath: path),
                  let img = NSImage(data: data) else { return }
            try? FileManager.default.removeItem(atPath: path)
            DispatchQueue.main.async {
                guard self.nowPlaying.title == forTitle else { return }
                var np = self.nowPlaying
                np.artwork = img
                self.nowPlaying = np
            }
        }
    }

    private var spotifyArtCache: [String: NSImage] = [:]
    private func fetchSpotifyArtwork(forTitle: String) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            guard let raw = self.runAppleScript("tell application \"Spotify\" to id of current track"),
                  raw.hasPrefix("spotify:track:") else { return }
            let tid = String(raw.dropFirst("spotify:track:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !tid.isEmpty else { return }
            if let img = self.spotifyArtCache[tid] {
                DispatchQueue.main.async { self.applyArtwork(img, forTitle: forTitle) }
                return
            }
            guard let url = URL(string: "https://open.spotify.com/oembed?url=https://open.spotify.com/track/\(tid)"),
                  let data = try? Data(contentsOf: url),
                  let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let thumb = obj["thumbnail_url"] as? String,
                  let turl = URL(string: thumb),
                  let imgData = try? Data(contentsOf: turl),
                  let img = NSImage(data: imgData) else { return }
            self.spotifyArtCache[tid] = img
            DispatchQueue.main.async { self.applyArtwork(img, forTitle: forTitle) }
        }
    }

    func applyArtwork(_ img: NSImage, forTitle: String) {
        guard nowPlaying.title == forTitle else { return }
        var np = nowPlaying
        np.artwork = img
        nowPlaying = np
    }

    private func appleScriptSendCommand(_ cmd: Int32, appId: String? = nil) -> Bool {
        let bundleId = appId ?? nowPlayingApp
        let action: String
        switch cmd {
        case MRCommand.togglePlayPause: action = "playpause"
        case MRCommand.nextTrack: action = "next track"
        case MRCommand.previousTrack: action = "previous track"
        case MRCommand.play: action = "play"
        case MRCommand.pause: action = "pause"
        default: return false
        }
        if !bundleId.isEmpty {
            let script = """
                tell application id "\(bundleId)"
                    \(action)
                end tell
                """
            if runAppleScript(script) != nil { return true }
        }
        for bid in ["com.apple.Music", "com.spotify.client"] {
            guard NSRunningApplication.runningApplications(withBundleIdentifier: bid).first != nil else { continue }
            let script = """
                tell application id "\(bid)"
                    \(action)
                end tell
                """
            if runAppleScript(script) != nil { return true }
        }
        return false
    }

    private func appleScriptSeekMedia(to seconds: Double, appId: String? = nil) {
        let bundleId = appId ?? nowPlayingApp
        if !bundleId.isEmpty {
            let script = """
                tell application id "\(bundleId)"
                    set player position to \(seconds)
                end tell
                """
            if runAppleScript(script) != nil { return }
        }
        for bid in ["com.apple.Music", "com.spotify.client"] {
            guard NSRunningApplication.runningApplications(withBundleIdentifier: bid).first != nil else { continue }
            let script = """
                tell application id "\(bid)"
                    set player position to \(seconds)
                end tell
                """
            if runAppleScript(script) != nil { return }
        }
    }

    private func runAppleScript(_ source: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error
        do {
            try process.run()
        } catch {
            return nil
        }
        let deadline = Date(timeIntervalSinceNow: 5)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }
        if process.isRunning {
            process.terminate()
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            }
            return nil
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return str?.isEmpty == true ? nil : str
    }

    private func simulateMediaKey(_ keyCode: Int32) {
        let NX_KEYTYPE_PLAY: UInt32 = 16
        let NX_KEYTYPE_NEXT: UInt32 = 17
        let NX_KEYTYPE_PREVIOUS: UInt32 = 18

        let nxKeyEvent: UInt32
        switch keyCode {
        case MRCommand.togglePlayPause: nxKeyEvent = NX_KEYTYPE_PLAY
        case MRCommand.nextTrack: nxKeyEvent = NX_KEYTYPE_NEXT
        case MRCommand.previousTrack: nxKeyEvent = NX_KEYTYPE_PREVIOUS
        default: return
        }

        // data1 格式：keyCode << 16 | keyState << 8 | NX_SUBTYPE
        let subType: Int16 = 0x8
        let keyDown = 0xA
        let keyUp = 0xB

        func postEvent(_ keyState: Int) {
            let data1 = (Int(nxKeyEvent) << 16) | (keyState << 8) | Int(subType)
            let data2 = 0
            guard let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: [],
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: subType,
                data1: data1,
                data2: data2
            ) else { return }
            event.cgEvent?.post(tap: CGEventTapLocation.cghidEventTap)
        }

        postEvent(keyDown)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            postEvent(keyUp)
        }
    }

    func toggleMockMedia() {
        mockMediaEnabled.toggle()
        if mockMediaEnabled {
            startMockMedia()
        } else {
            stopMockMedia()
            nowPlaying = NowPlayingInfo()
            nowPlayingApp = ""
        }
    }

    private func startMockMedia() {
        stopMockMedia()
        loadMockSong(index: mockMediaIndex)
        mockMediaTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.mockMediaEnabled, self.nowPlaying.isPlaying else { return }
            var np = self.nowPlaying
            np.elapsed += 0.1
            if np.duration > 0 && np.elapsed >= np.duration {
                self.loadMockSong(index: (self.mockMediaIndex + 1) % self.mockSongs.count)
            } else {
                self.nowPlaying = np
            }
        }
    }

    private func stopMockMedia() {
        mockMediaTimer?.invalidate()
        mockMediaTimer = nil
    }

    private func loadMockSong(index: Int) {
        let song = mockSongs[index % mockSongs.count]
        mockMediaIndex = index
        var np = NowPlayingInfo()
        np.title = song.title
        np.artist = song.artist
        np.album = song.album
        np.duration = song.duration
        np.elapsed = 0
        np.rate = 1.0
        np.isPlaying = true
        np.artwork = mockAlbumArt()
        if let lines = mockLyrics[song.title] {
            let interval = song.duration / Double(max(lines.count, 1))
            np.lyrics = lines.enumerated().map { LyricLine(time: Double($0.offset) * interval, text: $0.element) }
        }
        nowPlaying = np
        nowPlayingApp = "Mock 播放器"
        lyricState = .loaded
    }

    private func mockAlbumArt() -> NSImage {
        let colors: [NSColor] = [.systemBlue, .systemPink, .systemGreen, .systemOrange, .systemPurple]
        let color = colors[mockMediaIndex % colors.count]
        let img = NSImage(size: NSSize(width: 48, height: 48))
        img.lockFocus()
        color.setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 48, height: 48), xRadius: 8, yRadius: 8).fill()
        let note = "♪" as NSString
        note.draw(at: NSPoint(x: 14, y: 10), withAttributes: [.font: NSFont.systemFont(ofSize: 22), .foregroundColor: NSColor.white])
        img.unlockFocus()
        return img
    }

    func mockSendCommand(_ cmd: Int32) {
        guard mockMediaEnabled else { return }
        switch cmd {
        case MRCommand.togglePlayPause:
            var np = nowPlaying
            np.isPlaying.toggle()
            nowPlaying = np
        case MRCommand.nextTrack:
            loadMockSong(index: (mockMediaIndex + 1) % mockSongs.count)
        case MRCommand.previousTrack:
            loadMockSong(index: (mockMediaIndex - 1 + mockSongs.count) % mockSongs.count)
        default:
            break
        }
    }

    func mockSeekMedia(to seconds: Double) {
        guard mockMediaEnabled else { return }
        var np = nowPlaying
        np.elapsed = min(max(seconds, 0), np.duration)
        nowPlaying = np
    }

    private func startClock() {
        updateUptime()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isTransitioning else { return }
            self.date = Date()
        }
        uptimeTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateUptime()
        }
    }

    private func updateUptime() {
        let sec = Int(ProcessInfo.processInfo.systemUptime)
        let h = sec / 3600
        let m = (sec % 3600) / 60
        systemUptime = h >= 1 ? "\(h)小时\(m)分" : "\(m)分钟"
    }

    private func startBattery() {
        refreshBattery()
        batteryTimer = Timer.scheduledTimer(withTimeInterval: lowMemoryMode ? 60.0 : 45.0, repeats: true) { [weak self] _ in
            self?.refreshBattery()
        }
    }

    private func refreshBattery() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let p = Process()
            let pipe = Pipe()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            p.arguments = ["-g", "batt"]
            p.standardOutput = pipe
            do { try p.run() } catch { return }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            guard let out = String(data: data, encoding: .utf8) else { return }
            var level = 100
            var charging = false
            for line in out.split(separator: "\n") {
                let s = String(line)
                if s.contains("AC Power") { charging = true }
                if s.contains("charging") { charging = true }
                if let r = s.range(of: #"\d+%"#, options: .regularExpression) {
                    let num = String(s[r]).replacingOccurrences(of: "%", with: "")
                    if let v = Int(num) { level = v }
                }
            }
            DispatchQueue.main.async {
                self?.batteryLevel = level
                self?.isCharging = charging
            }
        }
    }

    private func startAirPodsMonitor() {
        checkAirPods()
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &addr, { _, _, _, _ in
            DispatchQueue.main.async { AppState.shared.checkAirPods() }
            return noErr
        }, selfPtr)
    }

    private static let earphoneKeywords: [String] = [
        "airpods", "airpod", "earpods", "beats", "powerbeats",
        "wh-", "wf-", "linkbuds", "sony buds",
        "galaxy buds", "samsung buds",
        "freebuds", "huawei", "honor",
        "redmi buds", "xiaomi buds", "mi buds",
        "enco", "tws", "oneplus buds",
        "nothing ear", "cmf buds", "jbl", "soundcore",
        "sennheiser", "akg", "jabra", "skullcandy", "marshall",
        "ath-", "audio-technica", "bose",
        "buds", "earbuds", "headphones", "earphones", "headset", "耳机"
    ]

    func checkAirPods() {
        var propsize: UInt32 = 0
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &propsize)
        let count = Int(propsize) / MemoryLayout<AudioObjectID>.size
        guard count > 0 else { return }
        var devices = [AudioObjectID](repeating: 0, count: count)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &propsize, &devices)

        var foundName: String?
        for dev in devices {
            var nameAddr = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var nameCF: Unmanaged<CFString>?
            var size: UInt32 = UInt32(MemoryLayout<CFString?>.size)
            if AudioObjectGetPropertyData(dev, &nameAddr, 0, nil, &size, &nameCF) != noErr { continue }
            guard let cfName = nameCF?.takeRetainedValue() else { continue }
            let name = cfName as String
            let lower = name.lowercased()
            if Self.earphoneKeywords.contains(where: { lower.contains($0) }) {
                foundName = name
                break
            }
        }

        if let name = foundName {
            if !airPodsConnected {
                airPodsConnected = true
                airPodsName = name
                if airPodsToastEnabled {
                    flashMessage("\(name) 已连接")
                    withExpanded(true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                        self?.withExpanded(false)
                    }
                }
            }
        } else {
            if airPodsConnected {
                airPodsConnected = false
                let oldName = airPodsName
                airPodsName = ""
                if airPodsToastEnabled {
                    flashMessage("\(oldName) 已断开")
                }
            }
        }
    }

    private func startTempMonitor() {
        refreshTemp()
        tempTimer = Timer.scheduledTimer(withTimeInterval: lowMemoryMode ? 12.0 : 8.0, repeats: true) { [weak self] _ in
            self?.refreshTemp()
        }
    }

    private func refreshTemp() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            var load: Double = 0
            var cpuInfo = host_cpu_load_info()
            var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
            let result = withUnsafeMutablePointer(to: &cpuInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
                }
            }
            if result == KERN_SUCCESS {
                let user = Double(cpuInfo.cpu_ticks.0)
                let system = Double(cpuInfo.cpu_ticks.1)
                let idle = Double(cpuInfo.cpu_ticks.2)
                let nice = Double(cpuInfo.cpu_ticks.3)
                let total = user + system + idle + nice
                if let prev = self.lastCPUTicks {
                    let du = user - prev.user
                    let ds = system - prev.system
                    let di = idle - prev.idle
                    let dn = nice - prev.nice
                    let dTotal = du + ds + di + dn
                    if dTotal > 0 {
                        load = min((du + ds + dn) / dTotal, 1.0)
                    }
                } else {
                    load = total > 0 ? min((user + system + nice) / total, 1.0) : 0
                }
                self.lastCPUTicks = (user, system, idle, nice)
            }

            var temp: Double = 0
            if let smcTemp = readSMCTemperature() {
                temp = smcTemp
            }
            if temp == 0 {
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/usr/bin/powermetrics")
                p.arguments = ["--samplers", "smc", "-n", "1", "-f", "text"]
                let pipe = Pipe()
                p.standardOutput = pipe
                p.standardError = FileHandle.nullDevice
                do { try p.run() } catch {}
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                p.waitUntilExit()
                if let out = String(data: data, encoding: .utf8),
                   let r = out.range(of: #"CPU die temperature: ([\d.]+) C"#, options: .regularExpression) {
                    let sub = String(out[r])
                    let num = sub
                        .replacingOccurrences(of: "CPU die temperature: ", with: "")
                        .replacingOccurrences(of: " C", with: "")
                    temp = Double(num) ?? 0
                }
            }

            let thermal: String
            switch ProcessInfo.processInfo.thermalState {
            case .nominal: thermal = "正常"
            case .fair: thermal = "适中"
            case .serious: thermal = "偏高"
            case .critical: thermal = "过高"
            @unknown default: thermal = "正常"
            }

            DispatchQueue.main.async {
                self.cpuTemp = temp
                self.cpuLoad = load
                self.thermalLevel = thermal
            }
        }
    }

    private func readSMCTemperature() -> Double? {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOPlatformDevice")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        var service: io_object_t = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }
            let nameKey = "IOName" as CFString
            if let name = IORegistryEntryCreateCFProperty(service, nameKey, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
                let lower = name.lowercased()
                if (lower.contains("temp") || lower.contains("die")) && !lower.contains("battery") {
                    let tempKey = "temperature" as CFString
                    if let val = IORegistryEntryCreateCFProperty(service, tempKey, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                        let celsius = Double(val) / 100.0
                        if celsius > 20 && celsius < 150 { return celsius }
                    }
                    if let val = IORegistryEntryCreateCFProperty(service, tempKey, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Double {
                        if val > 20 && val < 150 { return val }
                    }
                }
            }
            let tempKey = "Temperature" as CFString
            if let val = IORegistryEntryCreateCFProperty(service, tempKey, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                let celsius = Double(val) / 100.0
                if celsius > 20 && celsius < 150 {
                    if let name = IORegistryEntryCreateCFProperty(service, nameKey, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
                        if name.lowercased().contains("battery") { service = IOIteratorNext(iterator); continue }
                    }
                    return celsius
                }
            }
            service = IOIteratorNext(iterator)
        }
        return nil
    }

    private func startTraeMonitor() {
        refreshTraeStatus()
        traeTimer = Timer.scheduledTimer(withTimeInterval: lowMemoryMode ? 4.0 : 2.0, repeats: true) { [weak self] _ in
            self?.refreshTraeStatus()
        }
    }

    private func refreshTraeStatus() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/ps")
            p.arguments = ["-axo", "pid=,time=,rss=,command="]
            let pipe = Pipe()
            p.standardOutput = pipe
            p.standardError = FileHandle.nullDevice
            do { try p.run() } catch { return }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            guard let out = String(data: data, encoding: .utf8) else { return }
            var totalTime: Double = 0
            var totalRSS: Double = 0
            var gpuSeen = false
            for line in out.split(separator: "\n") {
                let parts = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
                guard parts.count == 4 else { continue }
                let cmd = String(parts[3])
                if cmd.contains("TRAE SOLO CN") || cmd.contains("TraeWork") {
                    totalTime += Self.parseCPUTime(String(parts[1]))
                    totalRSS += Double(parts[2]) ?? 0
                    if cmd.contains("Helper (GPU)") { gpuSeen = true }
                }
            }
            let now = Date()
            var instantCPU = 0.0
            if let lastDate = self?.traeCPULastDate, let lastAccum = self?.traeCPULastAccum {
                let dt = now.timeIntervalSince(lastDate)
                if dt >= 0.5 {
                    instantCPU = max(0, (totalTime - lastAccum) / dt * 100)
                }
            }
            self?.traeCPULastAccum = totalTime
            self?.traeCPULastDate = now
            let running = totalRSS > 0 || totalTime > 0
            DispatchQueue.main.async {
                self?.traeRunning = running
                self?.aiUsage["trae"] = (instantCPU, totalRSS / 1024.0)
                self?.aiGpuActive["trae"] = gpuSeen
            }
        }
    }

    private static func parseCPUTime(_ s: String) -> Double {
        let comps = s.split(separator: ":").compactMap { Double($0) }
        if comps.count == 2 { return comps[0] * 60 + comps[1] }
        if comps.count == 3 { return comps[0] * 3600 + comps[1] * 60 + comps[2] }
        return 0
    }

    private func startAIToolMonitor() {
        refreshAIToolStatus()
        aiToolTimer = Timer.scheduledTimer(withTimeInterval: lowMemoryMode ? 5.0 : 3.0, repeats: true) { [weak self] _ in
            self?.refreshAIToolStatus()
        }
    }

    private func stopAIToolMonitor() {
        aiToolTimer?.invalidate()
        aiToolTimer = nil
    }

    private func refreshAIToolStatus() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let hasClaude = Self.findExecutableInPATH("claude")
            let hasCodex = Self.findExecutableInPATH("codex")
            let hasWorkbuddy = FileManager.default.fileExists(atPath: "/Applications/WorkBuddy.app")
            var claudeRunning = false
            var codexRunning = false
            var claudeAccum = 0.0, claudeRSS = 0.0
            var codexAccum = 0.0, codexRSS = 0.0
            var wbAccum = 0.0, wbRSS = 0.0
            var traecodeAccum = 0.0, traecodeRSS = 0.0
            var gpuFlags: [String: Bool] = [:]
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/ps")
            p.arguments = ["-axo", "pid=,time=,rss=,command="]
            p.standardOutput = Pipe()
            p.standardError = FileHandle.nullDevice
            do { try p.run() } catch { return }
            let data = (p.standardOutput as! Pipe).fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            if let out = String(data: data, encoding: .utf8) {
                for line in out.split(separator: "\n") {
                    let parts = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
                    guard parts.count == 4 else { continue }
                    let cmd = String(parts[3]).trimmingCharacters(in: .whitespaces)
                    let rss = Double(parts[2]) ?? 0
                    let secs = Self.parseCPUTime(String(parts[1]))
                    let isGPU = cmd.contains("Helper (GPU)")
                    if cmd.hasSuffix("/claude") || cmd == "claude" {
                        claudeRunning = true; claudeAccum += secs; claudeRSS += rss
                        if isGPU { gpuFlags["claude"] = true }
                    } else if cmd.hasSuffix("/codex") || cmd == "codex" {
                        codexRunning = true; codexAccum += secs; codexRSS += rss
                        if isGPU { gpuFlags["codex"] = true }
                    } else if cmd.contains("WorkBuddy.app") {
                        wbAccum += secs; wbRSS += rss
                        if isGPU { gpuFlags["workbuddy"] = true }
                    } else if cmd.contains("Trae CN.app") || cmd.contains("Trae.app") {
                        traecodeAccum += secs; traecodeRSS += rss
                        if isGPU { gpuFlags["traecode"] = true }
                    }
                }
            }
            let wbRunning = NSWorkspace.shared.runningApplications.contains { app in
                let name = app.localizedName ?? ""
                let bid = app.bundleIdentifier ?? ""
                return name.localizedCaseInsensitiveContains("workbuddy") || bid.lowercased().contains("workbuddy")
            }
            let traecodeRunning = (traecodeAccum > 0 || traecodeRSS > 0) ||
                NSWorkspace.shared.runningApplications.contains { app in
                    let name = app.localizedName ?? ""
                    let bid = app.bundleIdentifier ?? ""
                    let n = name.localizedCaseInsensitiveContains("trae") && !name.localizedCaseInsensitiveContains("solo") && !name.localizedCaseInsensitiveContains("work")
                    let b = bid.lowercased().contains("trae") && !bid.lowercased().contains("solo")
                    return n || b
                }
            let now = Date()
            var inst: [String: Double] = [:]
            let items: [(String, Double)] = [("claude", claudeAccum),
                                             ("codex", codexAccum),
                                             ("workbuddy", wbAccum),
                                             ("traecode", traecodeAccum)]
            for (key, acc) in items {
                if let last = self.aiUsageLastAccum[key], let lastDate = self.aiUsageLastDate {
                    let dt = now.timeIntervalSince(lastDate)
                    if dt >= 0.5, dt <= 10 { inst[key] = max(0, (acc - last) / dt * 100) }
                }
                self.aiUsageLastAccum[key] = acc
                inst[key] = inst[key] ?? 0
            }
            self.aiUsageLastDate = now
            DispatchQueue.main.async {
                self.aiClaudeInstalled = hasClaude
                self.aiCodexInstalled = hasCodex
                self.aiWorkbuddyInstalled = hasWorkbuddy
                self.aiClaudeRunning = claudeRunning
                self.aiCodexRunning = codexRunning
                self.aiWorkbuddyRunning = wbRunning
                self.aiTraeCodeRunning = traecodeRunning
                self.aiUsage["claude"] = (inst["claude"] ?? 0, claudeRSS / 1024.0)
                self.aiUsage["codex"] = (inst["codex"] ?? 0, codexRSS / 1024.0)
                self.aiUsage["workbuddy"] = (inst["workbuddy"] ?? 0, wbRSS / 1024.0)
                self.aiUsage["traecode"] = (inst["traecode"] ?? 0, traecodeRSS / 1024.0)
                for k in ["claude", "codex", "workbuddy", "traecode"] {
                    if gpuFlags[k] == true { self.aiGpuActive[k] = true }
                    else { self.aiGpuActive.removeValue(forKey: k) }
                }
            }
        }
    }

    private static func findExecutableInPATH(_ name: String) -> Bool {
        let pathEnv = ProcessInfo.processInfo.environment["PATH"]
            ?? "/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:\(NSHomeDirectory())/.local/bin"
        return pathEnv.split(separator: ":")
            .map { "\($0)/\(name)" }
            .contains { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func traeCodeAppURL() -> URL? {
        for n in ["Trae CN.app", "Trae.app"] {
            let u = URL(fileURLWithPath: "/Applications/\(n)")
            if FileManager.default.fileExists(atPath: u.path) { return u }
        }
        return nil
    }

    private static func traeWorkAppURL() -> URL? {
        let u = URL(fileURLWithPath: "/Applications/TRAE SOLO CN.app")
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }

    func launchAICLI(_ kind: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            _ = self.osascript("tell application \"Terminal\" to do script \"\(kind)\"")
        }
    }

    var pointerOverIsland: Bool {
        if isHovering { return true }
        let m = NSEvent.mouseLocation
        guard geometry.screenFrame != .zero else { return false }
        let frame = geometry.screenFrame
        let w = windowWidth, h = isExpanded ? windowHeight : compactHeight
        let cx: CGFloat
        let yOffset: CGFloat
        if appearanceShape == 1 {
            cx = frame.midX
            yOffset = max(geometry.notchHeight, menuBarHeight)
        } else {
            cx = geometry.hasNotch ? geometry.notchCenterX : frame.midX
            yOffset = 0
        }
        let x0 = cx - w / 2 + appearanceOffsetX
        let y0 = frame.maxY - h + appearanceOffsetY - yOffset
        return m.x >= x0 && m.x <= x0 + w && m.y >= y0 && m.y <= frame.maxY
    }

    var traeCodeInstalled: Bool { Self.traeCodeAppURL() != nil }

    var traeWorkInstalled: Bool { Self.traeWorkAppURL() != nil }

    func openTraeWork() {
        if let url = Self.traeWorkAppURL() {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else if let u = URL(string: "https://www.trae.cn") {
            NSWorkspace.shared.open(u)
        }
    }

    func openTraeCode() {
        if let url = Self.traeCodeAppURL() {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else if let u = URL(string: "https://www.trae.cn") {
            NSWorkspace.shared.open(u)
        }
    }

    func launchWorkBuddy() {
        let app = URL(fileURLWithPath: "/Applications/WorkBuddy.app")
        if FileManager.default.fileExists(atPath: app.path) {
            NSWorkspace.shared.openApplication(at: app, configuration: NSWorkspace.OpenConfiguration())
        } else {
            if let u = URL(string: "https://codebuddy.cn/work") {
                NSWorkspace.shared.open(u)
            }
        }
    }

    func openSettings(tab: Int = 0) {
        SettingsWindowController.shared.show(tab: tab)
    }

    private static var isAppleSilicon: Bool {
        var value: Int = 0
        var size = MemoryLayout<Int>.size
        sysctlbyname("hw.optional.arm64", &value, &size, nil, 0)
        return value == 1
    }

    func toggleLidNoSleep() {
        if lidNoSleepEnabled {
            lidProcess?.terminate()
            lidProcess = nil
            lidNoSleepEnabled = false
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            p.arguments = ["-n", "/usr/bin/pmset", "-a", "disablesleep", "0"]
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
            try? p.run()
        } else {
            let caff = Process()
            caff.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
            caff.arguments = ["-d", "-i", "-s", "-u"]
            caff.standardOutput = FileHandle.nullDevice
            caff.standardError = FileHandle.nullDevice
            caff.terminationHandler = { [weak self] _ in
                DispatchQueue.main.async { self?.lidNoSleepEnabled = false }
            }
            do {
                try caff.run()
                lidProcess = caff
                lidNoSleepEnabled = true
            } catch {
                return
            }
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            p.arguments = ["-n", "/usr/bin/pmset", "-a", "disablesleep", "1"]
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
            try? p.run()
            if Self.isAppleSilicon {
                flashMessage("Apple Silicon 合盖睡眠为系统限制：仅连接外接显示器时可合盖不休眠，已尽力保持唤醒")
            } else {
                flashMessage("合盖不休眠已开启")
            }
        }
    }

    private func defaultOutputDeviceID() -> AudioObjectID? {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID) == noErr else { return nil }
        return deviceID
    }

    private var volumeScalarAddr: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain)
    }

    // VirtualMainVolume 对所有输出设备统一生效；常量已从公开头文件移除，这里用字面量 'volm'。
    private var virtualVolumeAddr: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(0x766F6C6D), // 'volm'
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
    }

    private static let volumeOSQueue = DispatchQueue(label: "islex.volume.osascript")
    private var volumeSetWork: DispatchWorkItem?

    private func osascript(_ script: String) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", script]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do { try p.run() } catch { return nil }
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func refreshVolume() {
        Self.volumeOSQueue.async { [weak self] in
            guard let self = self else { return }
            if let s = self.osascript("output volume of (get volume settings)"), let v = Float(s) {
                let real = max(0, min(1, v / 100))
                DispatchQueue.main.async {
                    if let target = self.pendingVolumeTarget,
                       let since = self.pendingVolumeSince,
                       Date().timeIntervalSince(since) < 3.0,
                       abs(real - target) > 0.001 {
                        return
                    }
                    self.pendingVolumeTarget = nil
                    self.pendingVolumeSince = nil
                    if abs(real - self.systemVolume) > 0.0005 {
                        #if PERF
                        PerfProbe.note("refresh", Double(real))
                        #endif
                        self.systemVolume = real
                    }
                }
            }
            if let s = self.osascript("output muted of (get volume settings)") {
                let muted = s.lowercased() == "true"
                DispatchQueue.main.async {
                    if let target = self.pendingMuteTarget,
                       let since = self.pendingMuteSince,
                       Date().timeIntervalSince(since) < 3.0,
                       muted != target {
                        return
                    }
                    self.pendingMuteTarget = nil
                    self.pendingMuteSince = nil
                    if muted != self.systemMuted { self.systemMuted = muted }
                }
            }
        }
    }

    func currentVolumeSync() -> Float {
        if let s = osascript("output volume of (get volume settings)"), let v = Float(s) {
            return max(0, min(1, v / 100))
        }
        return systemVolume
    }

    func currentMuteSync() -> Bool {
        if let s = osascript("output muted of (get volume settings)") {
            return s.lowercased() == "true"
        }
        return systemMuted
    }

    func setSystemVolume(_ vol: Float) {
        let v = max(0, min(1, vol))
        if abs(v - systemVolume) > 0.0005 { systemVolume = v }
        #if PERF
        PerfProbe.note("set", Double(v))
        #endif
        let percent = Int((v * 100).rounded())
        volumeSetGeneration += 1
        let gen = volumeSetGeneration
        pendingVolumeTarget = v
        pendingVolumeSince = Date()
        volumeSetWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            _ = self.osascript("set volume output volume \(percent)")
            guard gen == self.volumeSetGeneration else { return }
            guard let s = self.osascript("output volume of (get volume settings)"), let rv = Float(s) else {
                DispatchQueue.main.async { self.clearPendingVolume(gen: gen) }
                return
            }
            let real = max(0, min(1, rv / 100))
            DispatchQueue.main.async {
                guard gen == self.volumeSetGeneration else { return }
                if abs(real - v) > 0.001 {
                    #if PERF
                    PerfProbe.note("calib", Double(real))
                    #endif
                    self.systemVolume = real
                }
                self.clearPendingVolume(gen: gen)
            }
        }
        volumeSetWork = work
        Self.volumeOSQueue.async(execute: work)
    }

    private func clearPendingVolume(gen: Int) {
        guard gen == volumeSetGeneration else { return }
        pendingVolumeTarget = nil
        pendingVolumeSince = nil
    }

    func setSystemMute(_ muted: Bool) {
        if systemMuted != muted { systemMuted = muted }
        pendingMuteTarget = muted
        pendingMuteSince = Date()
        Self.volumeOSQueue.async { [weak self] in
            _ = self?.osascript("set volume output muted \(muted)")
        }
    }

    func startVolumeMonitor() {
        guard !volumeMonitorsStarted else { return }
        volumeMonitorsStarted = true
        var devAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &devAddr, { _, _, _, _ in
            DispatchQueue.main.async { AppState.shared.volumeOutputDidChange() }
            return noErr
        }, selfPtr)
        registerVolumeListener()
    }

    private func registerVolumeListener() {
        if volumeListenerRegistered, volumeListenerDevice != 0 {
            var addr = volumeScalarAddr
            AudioObjectRemovePropertyListener(volumeListenerDevice, &addr, volumeChangeCallback, nil)
        }
        guard let dev = defaultOutputDeviceID() else { return }
        volumeListenerDevice = dev
        var addr = volumeScalarAddr
        AudioObjectAddPropertyListener(dev, &addr, volumeChangeCallback, nil)
        volumeListenerRegistered = true
        refreshVolume()
    }

    func volumeOutputDidChange() {
        registerVolumeListener()
    }

    private var mediaPageVisible: Bool {
        isExpanded && currentPage == displayPosition(of: 1)
    }

    func onSystemVolumeChanged() {
        scheduleVolumeRefresh()
        suppressNextVolumeToast = false
    }

    func scheduleVolumeRefresh(after delay: TimeInterval = 0.35) {
        volumeRefreshWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.refreshVolume() }
        volumeRefreshWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func handleVolumeKey(_ nxCode: Int, fine: Bool = false) {
        let cur = systemVolume
        let step: Float = fine ? 0.015625 : 0.0625
        switch nxCode {
        case 0: // NX_KEYTYPE_SOUND_UP
            if systemMuted { setSystemMute(false) }
            let v = min(1, cur + step)
            #if PERF
            PerfProbe.note("key", Double(v))
            #endif
            setSystemVolume(v)
            showVolumeToast(value: v, muted: false)
        case 1: // NX_KEYTYPE_SOUND_DOWN
            if systemMuted { setSystemMute(false) }
            let v = max(0, cur - step)
            #if PERF
            PerfProbe.note("key", Double(v))
            #endif
            setSystemVolume(v)
            showVolumeToast(value: v, muted: false)
        default: // 7 NX_KEYTYPE_MUTE
            let newMute = !systemMuted
            setSystemMute(newMute)
            showVolumeToast(value: cur, muted: newMute)
        }
    }

    func handleKeyboardLightKey(_ nxCode: Int) {
        switch nxCode {
        case 10: // NX_KEYTYPE_ILLUMINATION_UP
            keyboardLightLevel = min(1, keyboardLightLevel + 0.2)
        case 11: // NX_KEYTYPE_ILLUMINATION_DOWN
            keyboardLightLevel = max(0, keyboardLightLevel - 0.2)
        case 12: // NX_KEYTYPE_ILLUMINATION_TOGGLE
            keyboardLightLevel = keyboardLightLevel > 0.01 ? 0 : 0.5
        default: return
        }
        showKeyboardToast(value: keyboardLightLevel)
    }

    var pomodoroProgress: Double {
        guard pomodoroPhase.duration > 0 else { return 0 }
        return 1.0 - Double(pomodoroTimeLeft) / Double(pomodoroPhase.duration)
    }

    var pomodoroTimeDisplay: String {
        let m = pomodoroTimeLeft / 60
        let s = pomodoroTimeLeft % 60
        return String(format: "%02d:%02d", m, s)
    }

    func pomodoroToggle() {
        if pomodoroIsRunning {
            pomodoroTimer?.invalidate()
            pomodoroTimer = nil
            pomodoroIsRunning = false
        } else {
            pomodoroIsRunning = true
            pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                AppState.shared.pomodoroTick()
            }
        }
    }

    func pomodoroReset() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroIsRunning = false
        pomodoroPhase = .work
        pomodoroTimeLeft = PomodoroPhase.work.duration
        pomodoroWorkCount = 0
    }

    func pomodoroSkip() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroIsRunning = false
        nextPomodoroPhase()
    }

    private func pomodoroTick() {
        if pomodoroTimeLeft > 0 {
            pomodoroTimeLeft -= 1
        }
        if pomodoroTimeLeft <= 0 {
            pomodoroTimer?.invalidate()
            pomodoroTimer = nil
            pomodoroIsRunning = false
            NSSound.beep()
            nextPomodoroPhase()
        }
    }

    private func nextPomodoroPhase() {
        switch pomodoroPhase {
        case .work:
            pomodoroWorkCount += 1
            todayPomodoroCount += 1
            todayFocusMinutes += PomodoroPhase.work.duration / 60
            if pomodoroWorkCount % 4 == 0 {
                pomodoroPhase = .longBreak
            } else {
                pomodoroPhase = .shortBreak
            }
        case .shortBreak, .longBreak:
            pomodoroPhase = .work
        }
        pomodoroTimeLeft = pomodoroPhase.duration
    }

    func loadFiles() {
        let dir = fileStationDir
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else {
            droppedFiles = []
            return
        }
        droppedFiles = items.compactMap { url in
            let name = url.lastPathComponent
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 28, height: 28)
            let attrs = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            let size = Int64(attrs?.fileSize ?? 0)
            let date = attrs?.contentModificationDate ?? Date()
            return FileItem(name: name, url: url, icon: icon, size: size, dateAdded: date)
        }.sorted { $0.dateAdded > $1.dateAdded }
    }

    func addFile(_ url: URL) {
        let dest = fileStationDir.appendingPathComponent(url.lastPathComponent)
        var finalDest = dest
        var i = 1
        while FileManager.default.fileExists(atPath: finalDest.path) {
            let name = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            let suffix = ext.isEmpty ? "(\(i))" : "(\(i)).\(ext)"
            finalDest = fileStationDir.appendingPathComponent("\(name) \(suffix)")
            i += 1
        }
        DispatchQueue.global(qos: .userInitiated).async {
            try? FileManager.default.copyItem(at: url, to: finalDest)
            DispatchQueue.main.async {
                AppState.shared.loadFiles()
            }
        }
    }

    func removeFile(_ file: FileItem) {
        try? FileManager.default.removeItem(at: file.url)
        loadFiles()
    }

    func clearAllFiles() {
        for file in droppedFiles {
            try? FileManager.default.removeItem(at: file.url)
        }
        droppedFiles = []
    }

    func openFile(_ file: FileItem) {
        NSWorkspace.shared.open(file.url)
    }

    func addTodo(title: String, priority: TodoPriority = .medium) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = TodoItem(title: trimmed, priority: priority)
        todoItems.insert(item, at: 0)
        saveTodos()
    }

    func toggleTodo(_ id: UUID) {
        guard let idx = todoItems.firstIndex(where: { $0.id == id }) else { return }
        todoItems[idx].isDone.toggle()
        saveTodos()
    }

    func removeTodo(_ id: UUID) {
        todoItems.removeAll { $0.id == id }
        saveTodos()
    }

    func clearDoneTodos() {
        todoItems.removeAll { $0.isDone }
        saveTodos()
    }

    private func loadTodos() {
        guard let data = try? Data(contentsOf: configDir.appendingPathComponent("todos.json")),
              let items = try? JSONDecoder().decode([TodoItem].self, from: data) else { return }
        todoItems = items
    }

    private func saveTodos() {
        guard let data = try? JSONEncoder().encode(todoItems) else { return }
        try? data.write(to: configDir.appendingPathComponent("todos.json"), options: .atomic)
    }

    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    enum ConverterType {
        case image, audio, text, unsupported
    }

    static func converterType(for url: URL) -> ConverterType {
        let ext = url.pathExtension.lowercased()
        let images: Set<String> = ["png", "jpg", "jpeg", "heic", "tiff", "tif", "bmp", "gif", "webp"]
        let audios: Set<String> = ["wav", "aiff", "aif", "m4a", "mp3", "caf", "aac", "flac"]
        let texts: Set<String> = ["txt", "md", "csv", "json", "log", "srt", "xml", "html", "htm",
                                  "yml", "yaml", "ini", "conf"]
        if images.contains(ext) { return .image }
        if audios.contains(ext) { return .audio }
        if texts.contains(ext) { return .text }
        return .unsupported
    }

    static func outputFormats(for url: URL) -> [String] {
        switch converterType(for: url) {
        case .image: return ["png", "jpg", "heic", "tiff", "bmp", "gif", "webp"]
        case .audio: return ["wav", "m4a", "aiff", "caf"]
        case .text: return ["UTF-8", "UTF-16LE", "GB18030", "BIG5"]
        case .unsupported: return []
        }
    }

    func pickConverterFile() {
        let panel = NSOpenPanel()
        panel.title = "选择要转换的文件"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            setConverterFileURL(url)
        }
    }

    func setConverterFileURL(_ url: URL) {
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 28, height: 28)
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        let file = FileItem(name: url.lastPathComponent, url: url, icon: icon,
                            size: Int64(size), dateAdded: Date())
        converterFile = file
        converterFormats = Self.outputFormats(for: url)
        converterTarget = converterFormats.first ?? ""
        converterStatus = converterFormats.isEmpty
            ? "暂不支持该文件类型"
            : "已选择：\(url.lastPathComponent)"
    }

    func convertFile() {
        guard let file = converterFile, !converterTarget.isEmpty, !converterWorking else { return }
        converterWorking = true
        converterStatus = "正在转换…"
        let src = file.url
        let type = Self.converterType(for: src)
        let target = converterTarget
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var outName = src.deletingPathExtension().lastPathComponent
            switch type {
            case .image, .audio:
                outName += ".\(target)"
            case .text:
                outName += ".txt"
            case .unsupported:
                outName += ".out"
            }
            let dest = self.fileStationDir.appendingPathComponent(outName)
            var finalDest = dest
            var i = 1
            while FileManager.default.fileExists(atPath: finalDest.path) {
                let n = finalDest.deletingPathExtension().lastPathComponent
                let e = finalDest.pathExtension
                finalDest = self.fileStationDir.appendingPathComponent("\(n) (\(i)).\(e)")
                i += 1
            }
            var ok = false
            var msg = ""
            switch type {
            case .image:
                ok = Self.convertImage(src, to: finalDest, format: target)
            case .audio:
                ok = Self.convertAudio(src, to: finalDest)
            case .text:
                ok = Self.convertText(src, to: finalDest, encoding: target)
            case .unsupported:
                msg = "暂不支持该文件类型"
            }
            DispatchQueue.main.async {
                self.converterWorking = false
                if ok {
                    self.converterStatus = "转换完成：\(finalDest.lastPathComponent)"
                    self.loadFiles()
                    self.converterDoneWork?.cancel()
                    withAnimation(.easeOut(duration: 0.25)) { self.showConverterDone = true }
                    let work = DispatchWorkItem { [weak self] in
                        withAnimation(.easeOut(duration: 0.35)) { self?.showConverterDone = false }
                    }
                    self.converterDoneWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
                } else {
                    self.converterStatus = msg.isEmpty ? "转换失败" : msg
                }
            }
        }
    }

    private static func convertImage(_ src: URL, to dest: URL, format: String) -> Bool {
        guard let source = CGImageSourceCreateWithURL(src as CFURL, nil),
              let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return false }
        let type: CFString
        switch format {
        case "jpg": type = "public.jpeg" as CFString
        case "heic": type = "public.heic" as CFString
        case "tiff": type = "public.tiff" as CFString
        case "bmp": type = "com.microsoft.bmp" as CFString
        case "gif": type = "com.compuserve.gif" as CFString
        case "webp": type = "org.webmproject.webp" as CFString
        default: type = "public.png" as CFString
        }
        guard let destCG = CGImageDestinationCreateWithURL(dest as CFURL, type, 1, nil) else { return false }
        CGImageDestinationAddImage(destCG, cg, nil)
        return CGImageDestinationFinalize(destCG)
    }

    private static func convertAudio(_ src: URL, to dest: URL) -> Bool {
        let fmt = dest.pathExtension.lowercased()
        let args: [String]
        switch fmt {
        case "wav": args = ["-f", "WAVE", "-d", "LEI16"]
        case "m4a": args = ["-f", "m4af", "-d", "aac"]
        case "aiff": args = ["-f", "AIFF", "-d", "BEI16"]
        case "caf": args = ["-f", "caff", "-d", "LEI16"]
        default: return false
        }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/afconvert")
        p.arguments = args + [src.path, dest.path]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return false }
        p.waitUntilExit()
        return p.terminationStatus == 0
    }

    private static func convertText(_ src: URL, to dest: URL, encoding: String) -> Bool {
        let sourceEnc: String
        if let data = try? Data(contentsOf: src), String(data: data, encoding: .utf8) != nil {
            sourceEnc = "UTF-8"
        } else {
            sourceEnc = "GB18030"
        }
        let targetEnc: String
        switch encoding {
        case "UTF-16LE": targetEnc = "UTF-16LE"
        case "GB18030": targetEnc = "GB18030"
        case "BIG5": targetEnc = "BIG5"
        default: targetEnc = "UTF-8"
        }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/iconv")
        p.arguments = ["-f", sourceEnc, "-t", targetEnc, src.path]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        do { try p.run() } catch { return false }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return false }
        do {
            try data.write(to: dest)
            return true
        } catch { return false }
    }

    private let defaultApps: [(name: String, icon: String, path: String, isWeb: Bool, bundleId: String?)] = [
        ("Safari",     "safari",    "/System/Applications/Safari.app", false, "com.apple.Safari"),
        ("Music",      "music.note","/System/Applications/Music.app", false, "com.apple.Music"),
        ("Mail",       "envelope",  "/System/Applications/Mail.app", false, "com.apple.mail"),
        ("信息",       "message",   "/System/Applications/Messages.app", false, "com.apple.MobileSMS"),
        ("日历",       "calendar",  "/System/Applications/Calendar.app", false, "com.apple.iCal"),
        ("备忘录",     "note.text", "/System/Applications/Notes.app", false, "com.apple.Notes"),
        ("地图",       "map",       "/System/Applications/Maps.app", false, "com.apple.Maps"),
        ("照片",       "photo",     "/System/Applications/Photos.app", false, "com.apple.Photos"),
        ("App Store",  "cart",      "/System/Applications/App Store.app", false, "com.apple.AppStore"),
        ("系统设置",   "gearshape", "/System/Applications/System Settings.app", false, "com.apple.systempreferences"),
        ("终端",       "terminal",  "/System/Applications/Utilities/Terminal.app", false, "com.apple.Terminal"),
        ("Chrome",     "globe",     "/Applications/Google Chrome.app", false, "com.google.Chrome"),
        ("Spotify",    "music.mic", "/Applications/Spotify.app", false, "com.spotify.client"),
        ("VS Code",    "chevron.left.forwardslash.chevron.right", "/Applications/Visual Studio Code.app", false, "com.microsoft.VSCode"),
        ("飞书",       "person.2",  "/Applications/Feishu.app", false, "com.bytedance.lark"),
        ("网易云音乐", "music.note.list", "/Applications/NeteaseMusic.app", false, "com.netease.163music"),
        ("MiniMax",    "sparkles",  "https://chat.minimax.io", true, nil),
        ("Trae Work",  "hammer",    "https://www.trae.cn", true, nil),
    ]

    private func makeShortcut(name: String, icon: String, path: String, isWeb: Bool, bundleId: String? = nil) -> AppShortcut? {
        var p = path
        if p.hasPrefix("file://") {
            p = URL(string: p)?.path ?? p
        }
        if isWeb {
            guard let url = URL(string: p) else { return nil }
            return AppShortcut(name: name, icon: icon, url: url, iconImage: nil, isWebLink: true, bundleId: nil)
        }
        var resolvedPath = p
        var resolvedBundleId = bundleId
        if let bid = bundleId, let u = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
            resolvedPath = u.path
        } else if let bundle = Bundle(url: URL(fileURLWithPath: p)),
                  let bid = bundle.bundleIdentifier,
                  let u = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
            resolvedPath = u.path
            resolvedBundleId = bid
        }
        if resolvedBundleId == nil, !FileManager.default.fileExists(atPath: resolvedPath) { return nil }
        // 旧配置可能存的是 file:// URL，先转成路径。
        if resolvedPath.hasPrefix("file://") {
            resolvedPath = URL(string: resolvedPath)?.path ?? resolvedPath
        }
        let appIcon = NSWorkspace.shared.icon(forFile: resolvedPath)
        appIcon.size = NSSize(width: 40, height: 40)
        let n = (Bundle(url: URL(fileURLWithPath: resolvedPath))?
                .object(forInfoDictionaryKey: "CFBundleName") as? String) ?? name
        return AppShortcut(name: n, icon: icon, url: URL(fileURLWithPath: resolvedPath), iconImage: appIcon, isWebLink: false, bundleId: resolvedBundleId)
    }

    private func loadApps() {
        if let data = try? Data(contentsOf: configURL),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            var result: [AppShortcut] = []
            for e in arr {
                let path = e["path"] as? String ?? ""
                let name = e["name"] as? String
                let isWeb = e["web"] as? Bool ?? (path.hasPrefix("http"))
                let bundleId = e["bundle"] as? String
                if let s = makeShortcut(name: name ?? "", icon: "app", path: path, isWeb: isWeb, bundleId: bundleId) {
                    result.append(s)
                }
            }
            if !result.isEmpty {
                apps = result
                return
            }
        }
        var result: [AppShortcut] = []
        for a in defaultApps {
            if let s = makeShortcut(name: a.name, icon: a.icon, path: a.path, isWeb: a.isWeb, bundleId: a.bundleId) {
                result.append(s)
            }
        }
        if result.isEmpty {
            for a in defaultApps where a.isWeb {
                if let s = makeShortcut(name: a.name, icon: a.icon, path: a.path, isWeb: a.isWeb, bundleId: a.bundleId) {
                    result.append(s)
                }
            }
        }
        apps = result
        saveConfig()
    }

    func saveConfig() {
        let arr = apps.map { ["name": $0.name, "path": $0.isWebLink ? $0.url.absoluteString : $0.url.path, "web": $0.isWebLink, "bundle": $0.bundleId ?? ""] as [String: Any] }
        if let data = try? JSONSerialization.data(withJSONObject: arr, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: configURL, options: .atomic)
        }
    }

    func addApp(name: String, path: String) {
        let isWeb = path.hasPrefix("http")
        var bundleId: String? = nil
        if !isWeb, let bundle = Bundle(url: URL(fileURLWithPath: path)) {
            bundleId = bundle.bundleIdentifier
        }
        guard let s = makeShortcut(name: name, icon: "app", path: path, isWeb: isWeb, bundleId: bundleId) else { return }
        apps.append(s)
        saveConfig()
    }

    struct PresetQuickApp {
        let name: String
        let icon: String
        let scheme: String
        var bundleIds: [String] = []
    }

    let quickPresets: [PresetQuickApp] = [
        .init(name: "微信", icon: "message.fill", scheme: "weixin://", bundleIds: ["com.tencent.xinWeChat"]),
        .init(name: "钉钉", icon: "bubble.left.fill", scheme: "dingtalk://", bundleIds: ["com.alibaba.DingTalkMac", "com.laiwang.DingTalk"]),
        .init(name: "企业微信", icon: "building.2.fill", scheme: "wxwork://", bundleIds: ["com.tencent.WeWorkMac", "com.tencent.wework"]),
        .init(name: "飞书", icon: "person.2.fill", scheme: "feishu://", bundleIds: ["com.electron.lark", "com.bytedance.lark"]),
        .init(name: "QQ", icon: "number.circle.fill", scheme: "tencent://", bundleIds: ["com.tencent.qq"]),
        .init(name: "邮件", icon: "envelope.fill", scheme: "mailto:", bundleIds: []),
        .init(name: "网易云音乐", icon: "music.note", scheme: "orpheus://", bundleIds: ["com.netease.163music"]),
    ]

    func addPresetApp(_ p: PresetQuickApp) {
        if let existing = apps.first(where: { $0.name == p.name }) {
            launch(existing)
            return
        }
        var shortcut: AppShortcut?
        for bid in p.bundleIds {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
                shortcut = makeShortcut(name: p.name, icon: p.icon, path: appURL.path, isWeb: false, bundleId: bid)
                break
            }
        }
        if shortcut == nil {
            shortcut = makeShortcut(name: p.name, icon: p.icon, path: p.scheme, isWeb: true)
        }
        guard let s = shortcut else { return }
        apps.append(s)
        saveConfig()
        flashMessage("已添加「\(p.name)」")
    }

    func addCustomLink(name: String, link: String) {
        var scheme = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if scheme.isEmpty { return }
        if !scheme.contains("://") && !scheme.hasPrefix("mailto:") {
            scheme = "https://" + scheme
        }
        guard let s = makeShortcut(name: name.isEmpty ? scheme : name, icon: "link", path: scheme, isWeb: true) else { return }
        apps.append(s)
        saveConfig()
    }

    func addCustomLinkViaDialog() {
        let alert = NSAlert()
        alert.messageText = "添加自定义链接"
        alert.informativeText = "输入名称与链接（支持网页或应用 Scheme，如 weixin://、dingtalk://）"
        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 22))
        nameField.placeholderString = "名称（可选）"
        let linkField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 22))
        linkField.placeholderString = "https:// 或 weixin:// 等"
        let stack = NSStackView(views: [nameField, linkField])
        stack.orientation = .vertical
        stack.spacing = 6
        alert.accessoryView = stack
        alert.addButton(withTitle: "添加")
        alert.addButton(withTitle: "取消")
        alert.window.initialFirstResponder = nameField
        if alert.runModal() == .alertFirstButtonReturn {
            addCustomLink(name: nameField.stringValue, link: linkField.stringValue)
        }
    }

    func removeApp(_ app: AppShortcut) {
        apps.removeAll { $0.id == app.id }
        saveConfig()
    }

    func addAppViaPanel() {
        let panel = NSOpenPanel()
        panel.title = "选择要添加的应用"
        panel.allowedContentTypes = [.application]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK, let url = panel.url {
            let name = (Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? url.deletingPathExtension().lastPathComponent
            addApp(name: name, path: url.path)
        }
    }

    func launch(_ app: AppShortcut) {
        editing = false
        if app.isWebLink {
            openWebLink(app)
        } else {
            openLocalApp(app)
        }
    }

    private func openLocalApp(_ app: AppShortcut) {
        guard FileManager.default.fileExists(atPath: app.url.path) else {
            launchByName(app)
            return
        }
        let cfg = NSWorkspace.OpenConfiguration()
        if let args = NeteaseCDPClient.launchArgs(for: app.url.path) { cfg.arguments = args }
        NSWorkspace.shared.openApplication(at: app.url, configuration: cfg) { _, error in
            if error != nil {
                DispatchQueue.main.async { self.launchByName(app) }
            }
        }
        withExpanded(false)
    }

    private func openWebLink(_ app: AppShortcut) {
        let scheme = app.url.scheme ?? ""
        if scheme == "http" || scheme == "https" || scheme == "mailto" {
            NSWorkspace.shared.open(app.url)
            withExpanded(false)
            return
        }
        if NSWorkspace.shared.urlForApplication(toOpen: app.url) != nil {
            NSWorkspace.shared.open(app.url)
            withExpanded(false)
            return
        }
        launchByName(app)
    }

    private func launchByName(_ app: AppShortcut) {
        for bid in presetBundleIds(for: app.url.absoluteString) {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
                openAppURL(appURL)
                return
            }
        }
        if let found = findAppURL(named: app.name) {
            openAppURL(found)
            return
        }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        p.arguments = ["-a", app.name]
        p.terminationHandler = { proc in
            DispatchQueue.main.async {
                if proc.terminationStatus == 0 {
                    self.withExpanded(false)
                } else {
                    self.flashMessage("未安装「\(app.name)」，无法打开")
                }
            }
        }
        do { try p.run() } catch {
            flashMessage("无法打开「\(app.name)」")
        }
    }

    private func openAppURL(_ u: URL) {
        let cfg = NSWorkspace.OpenConfiguration()
        if let args = NeteaseCDPClient.launchArgs(for: u.path) { cfg.arguments = args }
        NSWorkspace.shared.openApplication(at: u, configuration: cfg)
        withExpanded(false)
    }

    private func findAppURL(named name: String) -> URL? {
        let dirs = ["/Applications", "/System/Applications", NSHomeDirectory() + "/Applications"]
        for dir in dirs {
            guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for item in items where item.hasSuffix(".app") {
                let base = String(item.dropLast(4))
                let full = dir + "/" + item
                if base == name { return URL(fileURLWithPath: full) }
                if let b = Bundle(url: URL(fileURLWithPath: full)) {
                    let cn = b.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
                    let dn = b.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
                    if cn == name || dn == name { return URL(fileURLWithPath: full) }
                }
            }
        }
        return nil
    }

    private func presetBundleIds(for scheme: String) -> [String] {
        quickPresets.first(where: { $0.scheme == scheme })?.bundleIds ?? []
    }

    func flashMessage(_ text: String) {
        quickMsgWork?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { quickMsg = text }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.35)) { self?.quickMsg = nil }
        }
        quickMsgWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }

    func seekMedia(to seconds: Double) {
        guard seconds >= 0, nowPlaying.duration > 0 else { return }
        let target = min(seconds, nowPlaying.duration)
        if mockMediaEnabled { mockSeekMedia(to: target); return }
        if nowPlayingApp == NeteaseCDPClient.bundleId, NeteaseCDPClient.shared.seek(to: target) {
            var np = nowPlaying
            np.elapsed = target
            nowPlaying = np
            return
        }
#if !NOSMTC
        if MRMediaRemoteIsAvailable() && !mediaRemoteBroken {
            MRMediaRemoteSetElapsedTime(target)
        }
#endif
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.appleScriptSeekMedia(to: target)
        }
        var np = nowPlaying
        np.elapsed = target
        nowPlaying = np
    }

    func withExpanded(_ v: Bool, resetPage: Bool = true) {
        if !v && showReminder { return }
        if !v { editing = false }
        if v {
            if resetPage {
                currentPage = displayPosition(of: 0)
            }
            if let del = NSApp.delegate as? AppDelegate {
                del.scrollAccumulator = 0
                del.lastPageSwitch = Date()
                del.lastScrollTime = Date()
            }
            startAutoCollapseTimer()
        } else {
            stopAutoCollapseTimer()
        }
        if lowMemoryMode || reduceMotion {
            endTransition()
            isExpanded = v
        } else {
            beginTransition()
            withAnimation(.spring(response: 0.52, dampingFraction: 0.58)) {
                isExpanded = v
            } completion: {
                self.endTransition()
            }
        }
        repositionWindowAnimated()
    }

    private func beginTransition() {
        isTransitioning = true
        transitionEndWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.isTransitioning = false }
        transitionEndWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    private func endTransition() {
        transitionEndWork?.cancel()
        transitionEndWork = nil
        if isTransitioning { isTransitioning = false }
    }

    func startAutoCollapseTimer() {
        stopAutoCollapseTimer()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard !(self.nowPlaying.isPlaying && self.currentPage == self.displayPosition(of: 1)),
                  !self.pomodoroIsRunning,
                  !self.isDragTargeted,
                  !self.isHovering,
                  !self.showReminder,
                  self.isExpanded else { return }
            if self.pointerOverIsland {
                self.isHovering = true
                self.startAutoCollapseTimer()
                return
            }
            self.withExpanded(false)
        }
        autoCollapseWork = work
        let delay: TimeInterval = (currentPage == displayPosition(of: 3)) ? 5.0 : 0.75
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func setHovering(_ h: Bool) {
        isHovering = h
        if h {
            stopAutoCollapseTimer()
        } else if isExpanded {
            startAutoCollapseTimer()
        }
    }

    func stopAutoCollapseTimer() {
        autoCollapseWork?.cancel()
        autoCollapseWork = nil
    }

    func resetAutoCollapseTimer() {
        guard isExpanded else { return }
        startAutoCollapseTimer()
    }

    func showPageIndicator() {
        guard !isExpanded else { return }
        pageDotsHideWork?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { showPageDots = true }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.showPageDots = false }
        }
        pageDotsHideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
    }

    func hidePageIndicator() {
        pageDotsHideWork?.cancel()
        pageDotsHideWork = nil
        withAnimation(.easeOut(duration: 0.2)) { showPageDots = false }
    }

    func selectPage(_ index: Int) {
        guard !showReminder, index >= 0, index < visiblePageCount else { return }
        hidePageIndicator()
        withExpanded(true, resetPage: false)
        currentPage = index
    }

    deinit {
        pollTimer?.invalidate()
        mediaTicker?.invalidate()
        clockTimer?.invalidate()
        uptimeTimer?.invalidate()
        batteryTimer?.invalidate()
        pomodoroTimer?.invalidate()
        tempTimer?.invalidate()
        traeTimer?.invalidate()
        stopAIToolMonitor()
        autoCollapseWork?.cancel()
        converterDoneWork?.cancel()
        quickMsgWork?.cancel()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        helperInput?.fileHandleForWriting.closeFile()
        helperProcess?.terminate()
        lidProcess?.terminate()
    }
}
