//  IsleX 灵屿 —— 全局状态 AppState（媒体/番茄钟/文件/设置等）
//  由 main.swift 自动拆分生成，勿手动调整导入。

import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers
import ImageIO
import ServiceManagement
import ApplicationServices
import CoreAudio
import IOKit
#if APPSTORE
import IOKit.ps
#endif
import Foundation

// MARK: - 界面语言本地化（zh 为基准，en/ja 查表翻译；未收录词条回退中文）

func L(_ zh: String) -> String {
    let lang = AppState.shared.appLanguage
    guard lang != "zh", let e = L10n.table[zh] else { return zh }
    return lang == "ja" ? e.ja : e.en
}

enum L10n {
    static let table: [String: (en: String, ja: String)] = [
        // 设置窗口
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
        "AI 回复语言": ("AI Reply Language", "AI 返信言語"),
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
        // 页面名
        "仪表盘": ("Dashboard", "ダッシュボード"),
        "媒体": ("Media", "メディア"),
        "番茄钟": ("Pomodoro", "ポモドーロ"),
        "文件中转站": ("File Station", "ファイルステーション"),
        "应用": ("Apps", "アプリ"),
        "格式转换": ("Converter", "形式変換"),
        "硬件状态": ("Hardware", "ハードウェア"),
        "待办事项": ("Todos", "ToDo"),
        // 页面内常用
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
        // 无障碍标签
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
    /// 展开/收起动画进行中：期间装饰动画降级、后台高频刷新暂停，把主线程完整让给过渡动画
    @Published private(set) var isTransitioning = false
    private var transitionEndWork: DispatchWorkItem?
    @Published var showPageDots = false
    @Published var nowPlaying = NowPlayingInfo()
    // ---- Mock 媒体数据（用于在 MediaRemote 不可用时验证 UI 交互） ----
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
    // 网易云 CDP 直连状态（媒体页显示徽标/重启接通按钮）
    @Published var neteaseCDPConnected = false
    @Published var neteaseNeedsRelaunch = false
    @Published var lyricState: LyricState = .idle
    @Published var batteryLevel: Int = 100
    @Published var isCharging: Bool = false
    /// 当前日期（普通属性，非 @Published：UI 时钟由 RealtimeClockText 组件独立刷新，
    /// 避免每秒更新触发整个灵动岛界面全量重绘导致 CPU 满载）
    var date = Date()
    @Published var apps: [AppShortcut] = []
    @Published var editing = false
    @Published var geometry = NotchGeometry.current()

    // ---- 自定义显示屏幕（0 = 跟随主屏；其它值为目标屏幕的 CGDirectDisplayID） ----
    @Published var screenTarget: CGDirectDisplayID = {
        UInt32(UserDefaults.standard.integer(forKey: "screenTarget"))
    }() {
        didSet {
            UserDefaults.standard.set(Int(screenTarget), forKey: "screenTarget")
            geometry = NotchGeometry.current(on: targetScreen)
            (NSApp.delegate as? AppDelegate)?.repositionIsland()
        }
    }
    /// 用户选中的屏幕（屏已被拔/不存在时返回 nil → 回落到主屏）
    var targetScreen: NSScreen? {
        guard screenTarget != 0 else { return nil }
        return NSScreen.screens.first {
            ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == screenTarget
        }
    }
    /// 灵动岛实际所在屏幕：选中屏优先，未选/失效时跟随主屏
    var hostScreen: NSScreen? { targetScreen ?? NSScreen.main }
    /// 设置界面用的屏幕列表（首项为「跟随主屏」）
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

    // ---- 授权：全部功能免费开放（历史版本曾有试用/激活码机制，已移除）----
    /// Pro 功能是否已解锁：现已完全免费，恒为 true
    var proUnlocked: Bool { true }
    /// 启动时载入授权状态（免费版本无需载入，保留空实现兼容旧调用）
    private func loadProLicense() {}

    // 瞬时提示设置：屏蔽系统提示，统一在灵动岛内部显示
    @Published var volumeToastEnabled = true         // 音量调节在灵动岛显示
    @Published var volumeKeySuppressEnabled = true   // 屏蔽系统音量 HUD（拦截音量键，仅 Pro）
    @Published var airPodsToastEnabled = true        // 耳机连接/断开在灵动岛显示
    // 音量键拦截器运行状态（供设置页展示；Lite 版始终为 false）
    @Published var volumeSuppressPermitted = false   // 辅助功能权限是否已授予
    @Published var volumeSuppressInstalled = false   // tap 是否已创建
    @Published var volumeSuppressEnabled = false     // tap 是否处于启用状态
    @Published var volumeSuppressCount = 0           // 已拦截音量键次数（诊断用）
    @Published var volumeSuppressEvents = 0          // tap 收到事件总数（诊断 tap 是否静默失效）

    // 页面切换（灵动岛本体仅保留功能页；设置页经菜单栏图标打开独立窗口）
    @Published var currentPage = 0

    // ---- 页面顺序自定义（显示位置 → 实际页面） ----
#if APPSTORE
    let pageCount = 10   // 移除了 TraeWork；新增 天气 / 提词器
    @Published var pageOrder: [Int] = Array(0..<10)
    let pageNames = ["仪表盘", "媒体", "番茄钟", "文件中转站", "应用", "格式转换", "硬件状态", "待办事项", "天气", "提词器"]
#else
    let pageCount = 10  // 已移除 AI 助手；页面 7 = 待办事项，8 = 天气，9 = 提词器
    @Published var pageOrder: [Int] = Array(0..<10)
    let pageNames = ["仪表盘", "媒体", "番茄钟", "文件中转站", "应用", "格式转换", "硬件状态", "待办事项", "天气", "提词器"]
#endif
    @Published var hiddenPages: Set<Int> = []
    // 每页布局自定义：页面编号 → 布局配置（风格 / 自定义尺寸 / 隐藏区块）
    @Published var pageLayouts: [Int: PageLayoutConfig] = [:]

    // ---- 天气（Open-Meteo 免费 API：当前 + 未来 7 天 + 空气质量） ----
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

    // ---- 提词器（文本滚动 + 速度控制） ----
    @Published var tpText: String = {
        // 默认示例讲稿足够长，保证任意展开高度下都能演示滚动提词
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
    // 提词器文档库（导入的讲稿文档）
    @Published var tpDocuments: [TeleprompterDoc] = []

    // ---- OTA 更新推送（由 Updater.check 填充） ----
    @Published var updateVersion = ""
    @Published var updateNotes = ""
    @Published var updateURL = ""
    /// 是否有可用更新
    var updateAvailable: Bool { !updateVersion.isEmpty }

    /// 本地化页面名（仅用于显示；逻辑匹配仍用 pageNames 中文基准）
    func displayName(of page: Int) -> String { L(pageNames[page]) }

    /// 可见页面（按顺序过滤隐藏）
    var visiblePages: [Int] { pageOrder.filter { !hiddenPages.contains($0) } }
    /// 可见页面数（至少 1）
    var visiblePageCount: Int { max(visiblePages.count, 1) }

    /// 实际页面索引 → 显示位置
    func displayPosition(of page: Int) -> Int {
        if let i = visiblePages.firstIndex(of: page) { return i }
        return min(page, max(visiblePageCount - 1, 0))
    }

    /// 显示/隐藏小组件（仪表盘为固定项）
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
            // 兼容旧版本（含已移除页面编号）：过滤越界值，去重，缺失页面追加到末尾
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

    /// 应用界面语言（zh / en / ja）
    @Published var appLanguage: String = "zh" {
        didSet { UserDefaults.standard.set(appLanguage, forKey: "appLanguage") }
    }
    // 系统监测
    @Published var cpuTemp: Double = 0
    @Published var cpuLoad: Double = 0
    @Published var thermalLevel: String = "正常"
    @Published var lidNoSleepEnabled = false
    /// 上次 CPU ticks 采样值（用于计算瞬时负载）
    private var lastCPUTicks: (user: Double, system: Double, idle: Double, nice: Double)?

    // 番茄钟
    @Published var pomodoroPhase: PomodoroPhase = .work
    @Published var pomodoroTimeLeft: Int = PomodoroPhase.work.duration
    @Published var pomodoroIsRunning = false
    @Published var pomodoroWorkCount = 0
    @Published var todayFocusMinutes = 0
    @Published var todayPomodoroCount = 0
    @Published var systemUptime: String = ""
    @Published var systemVolume: Float = 0.5
    @Published var systemMuted = false

    // 岛内音量提示（刘海下方瞬时胶囊，替代系统音量 HUD）
    @Published var volumeToastVisible = false
    @Published var volumeToastValue: Float = 0.5
    @Published var volumeToastMuted = false
    private var volumeToastWork: DispatchWorkItem?
    /// 标记：下次系统音量变化回调时抑制 toast（媒体页滑块调节音量时使用）
    private var suppressNextVolumeToast = false

    // 岛内键盘亮度提示（系统无公开读值 API，自维护级数）
    @Published var keyboardToastVisible = false
    @Published var keyboardToastValue: Float = 0.5
    private var keyboardToastWork: DispatchWorkItem?
    private var keyboardLightLevel: Float = 0.5
    /// 音量刷新去抖：合并连按音量键产生的重复刷新请求（每个请求会起两个 osascript 子进程）
    private var volumeRefreshWork: DispatchWorkItem?
    /// 已请求但尚未落地的目标音量 + 请求时刻。
    /// osascript 写入约 240ms 才生效，而音量键连按是 100ms 一次，
    /// 此时读回的值还是旧值；若用它回写内存值，进度条/滑块会被拉回去（表现为「弹来弹去」）
    private var pendingVolumeTarget: Float?
    private var pendingVolumeSince: Date?
    /// 同上，静音状态：写入落地前读回的是旧状态，回写会让静音图标来回翻
    private var pendingMuteTarget: Bool?
    private var pendingMuteSince: Date?
    /// 音量设置请求代号：只有最后一次请求允许读回校准
    private var volumeSetGeneration = 0
    /// 媒体进度节流：计时器计数 + 上次真正推进进度的时间
    private var mediaTick = 0
    private var mediaTickDate = Date()
    private var volumeListenerDevice: AudioObjectID = 0
    private var volumeListenerRegistered = false
    private var volumeMonitorsStarted = false

    // 文件中转站
    @Published var droppedFiles: [FileItem] = []
    // ---- 待办事项 ----
    @Published var todoItems: [TodoItem] = []
    @Published var isDragTargeted = false

    // 格式转换器
    @Published var converterFile: FileItem?
    @Published var converterFormats: [String] = []
    @Published var converterTarget: String = ""
    @Published var converterStatus: String = "请选择要转换的文件"
    @Published var converterWorking = false
    @Published var showConverterDone = false
    @Published var quickMsg: String?
    private var quickMsgWork: DispatchWorkItem?

    // 温度状态色（供收起态指示器与系统页共用）
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

    // TraeWork 监测（TRAE SOLO CN.app = Trae Work 智能工作台）
    @Published var traeRunning = false
    @Published var traeCPU: Double = 0
    @Published var traeMemoryMB: Double = 0
    private var traeTimer: Timer?
    // AI 编码工具监测（Trae Code = Trae CN.app IDE；Trae Work 复用 traeRunning；WorkBuddy 桌面 App；Claude Code / Codex CLI）
    @Published var aiTraeCodeRunning = false
    @Published var aiWorkbuddyInstalled = false
    @Published var aiWorkbuddyRunning = false
    @Published var aiClaudeInstalled = false
    @Published var aiClaudeRunning = false
    @Published var aiCodexInstalled = false
    @Published var aiCodexRunning = false
    /// 各工具资源占用：key = trae / traecode / workbuddy / claude / codex
    @Published var aiUsage: [String: (cpu: Double, ramMB: Double)] = [:]
    /// 各工具 GPU 是否活跃（存在 GPU Helper 进程；系统无公开的每进程 GPU 占用率接口）
    @Published var aiGpuActive: [String: Bool] = [:]
    private var aiToolTimer: Timer?
    private var aiUsageLastAccum: [String: Double] = [:]   // 各工具累计 CPU 秒（采样差求瞬时）
    private var aiUsageLastDate: Date?
    // 瞬时 CPU 采样（两次 ps 累计 CPU 时间差值 / 间隔）
    private var traeCPULastAccum = 0.0
    private var traeCPULastDate: Date?

    // 项目完成提醒（TraeWork 忙碌 → 空闲 判定，以灵动岛展开呈现）
    @Published var projectReminderEnabled = true
    @Published var projectReminderName = "Tree walk"
    @Published var showReminder = false
    private var traeWasBusy = false
    private var traeIdleStart: Date?
    private var traeBusySince: Date?
    private var lastReminderAt: Date = .distantPast
    private var reminderSilenceUntil: Date = .distantPast

    // 跑马灯自定义
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

    // ---- 外观自定义（尺寸/位置/风格/主题，无上限） ----
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
    /// 设置形态（0 自动 / 1 悬浮胶囊），立即重定位
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

    /// 外观变化后重定位窗口（尺寸/偏移即时生效）
    func repositionWindow() {
        (NSApp.delegate as? AppDelegate)?.repositionIsland()
    }

    /// 展开/收起时同步 AppKit 窗口 frame 动画（与 SwiftUI spring 时长对齐）
    func repositionWindowAnimated() {
        (NSApp.delegate as? AppDelegate)?.repositionIslandForExpandCollapse()
    }

    /// 自定义背景色（未启用时为黑色）
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

    /// 选择自定义背景图片
    func pickBackgroundImage() {
        let panel = NSOpenPanel()
        panel.title = "选择背景图片"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.png, .jpeg, .image]
        } else {
            panel.allowedFileTypes = ["png", "jpg", "jpeg", "tiff", "bmp"]
        }
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let img = NSImage(contentsOf: url) {
            backgroundImage = img
            backgroundImageEnabled = true
            // 保存图片路径
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
        appearanceShape = min(d.integer(forKey: "appShape"), 1)  // 兼容旧版 2=刘海形态（已移除）
        appearanceTheme = d.integer(forKey: "appTheme")
        appearanceScale = 1.0  // 强制展开缩放为 1
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

    /// 走马灯实际转速时长：开启随 CPU 后，负载越高转得越快（1x ~ 3.5x）
    var marqueeEffectiveDuration: Double {
        guard marqueeCpuLinked else { return marqueeDuration }
        let factor = 1 + cpuLoad * 2.5
        return marqueeDuration / factor
    }

    // ---- 瞬时提示设置（音量 / 亮度 / 键盘亮度，屏蔽系统提示后在灵动岛显示） ----
    private func loadToastSettings() {
        let d = UserDefaults.standard
        // 恢复灵动岛 HUD：默认启用音量提示与音量键拦截（用户可在设置页关闭）
        d.set(true, forKey: "toastVolume")
        d.set(true, forKey: "toastVolumeSuppress")
        volumeToastEnabled = true
        volumeKeySuppressEnabled = true
        airPodsToastEnabled = d.object(forKey: "toastAirPods") != nil ? d.bool(forKey: "toastAirPods") : true
#if !APPSTORE
        // 启动音量/亮度/键盘亮度键拦截器（需辅助功能权限，未授权时自动弹窗 + 后台重试）
        VolumeKeyInterceptor.shared.start()
        refreshVolumeSuppressStatus()
#endif
    }

    func setVolumeToastEnabled(_ v: Bool) {
        volumeToastEnabled = v
        UserDefaults.standard.set(v, forKey: "toastVolume")
        if !v { hideVolumeToast() }
    }

    func setVolumeKeySuppressEnabled(_ v: Bool) {
        volumeKeySuppressEnabled = v
        UserDefaults.standard.set(v, forKey: "toastVolumeSuppress")
#if !APPSTORE
        if v {
            VolumeKeyInterceptor.shared.start()
        } else {
            VolumeKeyInterceptor.shared.stop()
        }
        refreshVolumeSuppressStatus()
#endif
    }

    /// 强制重新安装音量键拦截器（授权后或异常时手动触发）
    func forceReinstallInterceptor() {
#if !APPSTORE
        VolumeKeyInterceptor.shared.stop()
        VolumeKeyInterceptor.shared.start()
        refreshVolumeSuppressStatus()
#endif
    }

    /// 刷新音量键拦截器状态（拦截器状态变化 / 定时健康检查时调用）
    func refreshVolumeSuppressStatus() {
#if !APPSTORE
        let interceptor = VolumeKeyInterceptor.shared
        // 逐项判断后再赋值：本函数被「每次音量键 + 2s 健康检查 + 3s 授权轮询」调用，
        // 无条件赋值会让界面在什么都没变时也不断重绘
        if volumeSuppressPermitted != interceptor.hasPermission { volumeSuppressPermitted = interceptor.hasPermission }
        if volumeSuppressInstalled != interceptor.isInstalled { volumeSuppressInstalled = interceptor.isInstalled }
        if volumeSuppressEnabled != interceptor.isEnabled { volumeSuppressEnabled = interceptor.isEnabled }
        if volumeSuppressCount != interceptor.interceptCount { volumeSuppressCount = interceptor.interceptCount }
        if volumeSuppressEvents != interceptor.receivedEvents { volumeSuppressEvents = interceptor.receivedEvents }
#endif
    }

    func setAirPodsToastEnabled(_ v: Bool) {
        airPodsToastEnabled = v
        UserDefaults.standard.set(v, forKey: "toastAirPods")
    }

    /// 岛内音量提示：显示 1.2 秒，连续调节时持续刷新
    func showVolumeToast(value: Float, muted: Bool) {
        guard volumeToastEnabled else { return }
        volumeToastWork?.cancel()
        let v = max(0, min(1, value))
        // 先设置数值（无动画，FlowingBar 内部 onChange 自行驱动进度条）
        volumeToastValue = v
        volumeToastMuted = muted
        // 再独立控制可见性动画
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

    /// 岛内键盘亮度提示（自维护级数，系统无公开读值 API）
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
            // 低内存（≤6GB）：首次默认关闭跑马灯，避免流光动画拖慢低配机器（用户可手动开启）
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

    /// 根据主题颜色生成流光渐变 stops（供主界面与预览页共用）
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

#if !APPSTORE
    private var pollTimer: Timer?
#endif
    private var clockTimer: Timer?
    private var uptimeTimer: Timer?
    private var batteryTimer: Timer?
    private var pomodoroTimer: Timer?
#if !APPSTORE
    private var mediaTicker: Timer?
#endif
    private var autoCollapseWork: DispatchWorkItem?
    private var pageDotsHideWork: DispatchWorkItem?
    private var observers: [NSObjectProtocol] = []
    private var tempTimer: Timer?
#if !APPSTORE
    private var lidProcess: Process?
#endif

#if !APPSTORE
    // macOS 15.4+ MediaRemote 限制：非 Apple 签名二进制调用返回空，需通过 /usr/bin/swift 辅助进程读取
    private var helperProcess: Process?
    private var helperInput: Pipe?
    private var helperBuffer = Data()
    private var helperStarted = false
#endif

    static let shared = AppState()

    private init() {
        startupLog("AppState.init 开始")
        loadProLicense()
        startupLog("loadProLicense 完成")
        loadApps()
        startupLog("loadApps 完成")
        loadFiles()
        startupLog("loadFiles 完成")
#if !APPSTORE
        startMediaRemote()
        startupLog("startMediaRemote 完成")
#endif
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

    // ---- 开机自启动 ----
    func checkLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            launchAtLogin = (service.status == .enabled || service.status == .requiresApproval)
        }
    }

    func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            if launchAtLogin {
                try? service.unregister()
            } else {
                try? service.register()
            }
            checkLaunchAtLogin()
        }
    }

    // ---- 动态尺寸（缩小高度，支持外观自定义覆盖）----
    // 0 = 自动（跟随机型缺口）
    @Published var appearanceCompactWidth: CGFloat = 0
    @Published var appearanceCompactHeight: CGFloat = 0
    @Published var appearanceExpandedWidth: CGFloat = 0
    @Published var appearanceExpandedHeight: CGFloat = 0
    @Published var appearanceOffsetX: CGFloat = 0
    @Published var appearanceOffsetY: CGFloat = -4
    @Published var appearanceCornerStyle: Int = 0   // 0 默认 1 圆润 2 方正
    @Published var appearanceShape: Int = 0          // 形态：0 自动（贴合硬件刘海；无刘海→悬浮胶囊） 1 悬浮胶囊（药丸，居中）
    @Published var appearanceTheme: Int = 0          // 0 跟随系统 1 深色
    @Published var appearanceScale: CGFloat = 1.0    // 展开态缩放（无上限）
    @Published var appearanceCompactScale: CGFloat = 0.9  // 收起态缩放（默认0.9）
    @Published var appearanceFontSize: CGFloat = 13  // 自定义字体大小（9-18）
    @Published var hudScale: CGFloat = 1.0           // HUD 提示大小倍率（0.7-1.5，默认1.0）

    @Published var auroraEnabled = true              // 极光质感

    // ---- 自定义背景（灵动岛本体背景，颜色或图片） ----
    @Published var backgroundCustomEnabled = false
    @Published var backgroundRed: Double = 0
    @Published var backgroundGreen: Double = 0
    @Published var backgroundBlue: Double = 0
    @Published var backgroundImageEnabled = false
    @Published var backgroundImage: NSImage?

    /// 字体随灵动岛大小等比例缩放：展开/收起态宽度相对默认值的比例
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
        // 下限 0.85：极窄时保持可读，不再继续等比缩小
        // 再乘用户自定义字体大小（默认 13 = 1.0）
        return max(r, 0.85) * (appearanceFontSize / 13)
    }

    /// 收起态内容行高度：单行内最大元素（封面 18pt / 最大正文行高 字号×1.2）
    var compactContentHeight: CGFloat {
        max(18, appearanceFontSize * 1.2)
    }
    /// 收起态四边统一内边距：上/下由内容高度与岛高自适应，左/右取同值，保证与灵动岛边界距离全部一致
    var compactInset: CGFloat {
        max((compactHeight - compactContentHeight) / 2, 6)
    }

    /// 「圆角样式」倍率：1=大圆角 1.4x / 2=小圆角 0.55x / 0=标准 1.0x。
    /// 岛内所有内嵌控件通过 rr() 按同一倍率缩放，保证观感同步。
    var cornerRadiusMultiplier: CGFloat {
        switch appearanceCornerStyle {
        case 1: return 1.4
        case 2: return 0.55
        default: return 1.0
        }
    }

    // macOS 26 (Tahoe) 圆角体系（pt）：窗口 26 / 面板 18 / 控件 8-9
    var radiusWindow: CGFloat { 26 * cornerRadiusMultiplier }   // 灵动岛外框圆角
    var radiusPanel: CGFloat { 18 * cornerRadiusMultiplier }    // 卡片 / 面板
    var radiusControl: CGFloat { 9 * cornerRadiusMultiplier }   // 标准控件
    var radiusItem: CGFloat { 8 * cornerRadiusMultiplier }      // 小控件 / 标签

    /// 设备机型标识（sysctl hw.model，如 "MacBookPro17,3"），惰性缓存
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

    /// 刘海剪影缩放：按设备型号自适应（不同机型刘海宽高比不同，贴合度更高）
    var notchShapeScale: CGFloat {
        let m = deviceModel
        if m.hasPrefix("MacBookAir") { return 0.66 }   // Air 13/15：刘海较窄
        if m.hasPrefix("MacBookPro") { return 0.72 }   // Pro 14/16：刘海较宽
        return 0.7
    }

    var compactWidth: CGFloat {
        let auto: CGFloat
        if appearanceShape == 1 {
            auto = 132   // 悬浮胶囊默认宽度（类 iPhone 灵动岛药丸），可被自定义覆盖
        } else {
            auto = max(geometry.notchWidth + 140, 200)
        }
        guard appearanceCompactWidth > 0 else { return auto }
        return max(appearanceCompactWidth, 1)
    }
    var compactHeight: CGFloat {
        let auto: CGFloat
        if appearanceShape == 1 {
            auto = 44   // 悬浮胶囊默认高度
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
    /// 当前页面布局缩放（1 紧凑 0.85 / 0 标准 1.0 / 2 大卡片 1.15）
    var currentPageStyleScale: CGFloat {
        switch (pageLayouts[currentPage] ?? PageLayoutConfig()).style {
        case 1: return 0.85
        case 2: return 1.15
        default: return 1.0
        }
    }
    /// 当前页面的某个内容区块是否被隐藏（媒体页封面/歌词、天气页轨迹/空气质量等）
    func isBlockHidden(_ id: String) -> Bool {
        let page = visiblePages.indices.contains(currentPage) ? visiblePages[currentPage] : currentPage
        return (pageLayouts[page] ?? PageLayoutConfig()).hiddenBlocks.contains(id)
    }
    var windowWidth: CGFloat {
        return (expandedWidth + 24) * appearanceScale
    }
    // 展开窗口高度 = 展开内容高 + 底部信息区 + 菜单栏高度余量（窗口贴顶时顶部菜单栏区域被系统占用，
    // 增加高度保证内容（含收起按钮/设置图标）完整显示在菜单栏下方，不被遮挡）
    var windowHeight: CGFloat { (expandedHeight + max(geometry.notchHeight + 4, 36) + menuBarHeight) * appearanceScale }
    var compactRadius: CGFloat {
        if appearanceShape == 1 { return compactHeight / 2 }   // 悬浮胶囊：完整药丸
        return max(compactHeight / 2, 14) * cornerRadiusMultiplier
    }
    var expandedRadius: CGFloat { radiusWindow }  // macOS 26+ 窗口圆角 26pt
    var notchGap: CGFloat {
        if appearanceShape == 1 { return 0 }
        return geometry.notchWidth / appearanceScale
    }
    var pageContentWidth: CGFloat { expandedWidth - 24 }
    /// 顶部避让：刘海高度与 macOS 菜单栏高度取较大值，防止展开态控件（收起按钮/设置图标）被菜单栏遮挡
    var notchPadding: CGFloat {
        if appearanceShape == 1 { return 2 }   // 悬浮胶囊已整体下移，无需再避让
        return max(max(geometry.notchHeight, 0) + 2, menuBarHeight + 4)
    }

    /// 目标屏幕顶部菜单栏真实高度（screen 与 visibleFrame 顶部之差；刘海屏=刘海高，Tahoe 更高，10.15=24）
    var menuBarHeight: CGFloat {
        guard let s = hostScreen ?? NSScreen.main else { return 24 }
        let h = s.frame.maxY - s.visibleFrame.maxY
        return h > 0 ? h : 24
    }

    /// 低配模式：物理内存 ≤ 6GB（如 MacBook Air 2015 4GB / 6GB）自动启用——
    /// 强制关闭动态模糊（Liquid Glass 全屏截图+折射在低内存机器上会导致无响应）、后台轮询降频
    var lowMemoryMode: Bool {
        ProcessInfo.processInfo.physicalMemory <= 6_442_450_944
    }
    var contentHeight: CGFloat { expandedHeight - 14 - notchPadding }
    /// Apple HIG：系统开启「减少动效」时禁用动画（连续动画与展开/收起改为瞬时切换）
    var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    var totalFileSize: Int64 { droppedFiles.reduce(0) { $0 + $1.size } }

    func islandRect(expanded: Bool) -> NSRect {
        let w = expanded ? expandedWidth : compactWidth
        let h = expanded ? expandedHeight : compactHeight
        let x = (windowWidth - w) / 2
        let y = windowHeight - h
        return NSRect(x: x, y: y, width: w, height: h)
    }

    // ---- 配置持久化 ----
    private var configDir: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NotchIsland", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var configURL: URL { configDir.appendingPathComponent("apps.json") }

    private var fileStationDir: URL {
        let dir = configDir.appendingPathComponent("FileStation", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

#if !APPSTORE
    // ---- 媒体 ----
    private func startMediaRemote() {
#if NOSMTC
        // 无 SMTC 构建（macOS 26.5+）：MediaRemote 对第三方进程已失效，
        // 使用 AppleScript（Music/Spotify/QuickTime/TV）+ CDP（网易云）+ plist/archive 直连（酷狗/QQ音乐）
        startupLog("无 SMTC 构建：AppleScript + CDP + plist/archive 直连媒体检测")
        startApplescriptPolling()
        DispatchQueue.main.async {
            KuGouPlistPoller.shared.start()
            QQMusicArchivePoller.shared.start()
            NeteaseCDPClient.shared.start()
        }
#else
        // macOS 10.15：MediaRemote 私有框架函数签名与 11+ 不兼容，直接调用会 SIGILL 崩溃。
        // 跳过媒体控制（媒体页显示"未检测到播放"），其余功能不受影响。
        guard #available(macOS 11.0, *) else {
            startupLog("startMediaRemote 已跳过（10.15 签名不兼容）")
            return
        }

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
    /// MediaRemote 轮询
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
        // 启动辅助进程（macOS 15.4+ 需要，用于绕过签名限制）
        startHelperIfNeeded()
        startupLog("MR helper 后")
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isTransitioning else { return }
            self.fetchInfo()
        }
        // 本地推进播放进度（0.1s 精度，实现逐字歌词跟进）
        mediaTicker = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            guard self.nowPlaying.isPlaying, self.nowPlaying.hasMedia else { self.mediaTickDate = now; return }
            // 展开/收起动画期间不推进进度（0.1s 精度损失不可感知），把主线程让给过渡动画
            guard !self.isTransitioning else { self.mediaTickDate = now; return }
            // 逐帧进度只有「展开且停留在媒体页」时才看得见（进度条/歌词）；其余场景降到 1 秒一次。
            // 收起态每秒 10 次全界面重绘，正是音量 HUD、跑马灯动画被拖出卡顿的来源。
            self.mediaTick &+= 1
            if !self.mediaPageVisible && self.mediaTick % 10 != 0 { return }
            // 用真实间隔推进（节流期间会被跳过，因此必须累计补上）
            let dt = min(max(now.timeIntervalSince(self.mediaTickDate), 0), 1.2)
            self.mediaTickDate = now
            var np = self.nowPlaying
            np.elapsed += dt
            if np.duration > 0 && np.elapsed > np.duration { np.elapsed = np.duration }
            self.nowPlaying = np
        }
        // macOS 26/27：MR 私有 API 可能静默失效（dlopen 成功但查询恒为空，媒体无法显示）。
        // 启动后定期检测，确认失效后自动切换到 AppleScript 轮询
        checkMRDeadAndFallback()
    }

    /// 检测 MR 是否实际可用；不可用时切换到 AppleScript 轮询（自身会周期重试）
    private func checkMRDeadAndFallback() {
        if mediaRemoteBroken { return }
        // 已收到过真实媒体数据 → MR 正常，无需回退
        if mrDeliveredAnyData { return }
        // 仅 macOS 26+ 需要此检测（15.4~25 的空字典问题已由辅助进程解决）
        guard #available(macOS 26.0, *) else { return }
        // 无任何已知媒体应用在运行 → 保持 MR 等待，5 秒后再查（覆盖稍后打开播放器）
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

    /// 是否有已知媒体应用在运行
    private func mediaAppRunning() -> Bool {
        let ids = ["com.apple.Music", "com.spotify.client", "com.netease.163music",
                   "com.apple.QuickTimePlayerX", "com.apple.iTunes", "com.tencent.QQMusicMac",
                   "com.kugou.kugouMac", "com.kugou.mac.Music", "com.apple.podcasts", "com.apple.tv"]
        return ids.contains { NSRunningApplication.runningApplications(withBundleIdentifier: $0).first != nil }
    }

    /// 切换到 AppleScript 轮询：停止 MR 轮询与通知（避免空字典清空已显示内容），并终止无用的辅助进程
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
        // 酷狗音乐无 AppleScript 接口：plist 直连读取其播放状态文件（无需任何权限）。
        // 注意：此处仍处于 AppState.shared 的 dispatch_once 初始化中，直接访问 KuGouPlistPoller.shared
        // （其内部会再访问 AppState.shared）会导致 _dispatch_once_wait 递归死锁，故延后到主循环启动。
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.mediaRemoteBroken else { return }
            KuGouPlistPoller.shared.start()
            NeteaseCDPClient.shared.start()
        }
    }
#endif // !NOSMTC

    /// AppleScript 轮询（MediaRemote 不可用/无 SMTC 构建时）
    private func startApplescriptPolling() {
        // 立即尝试获取一次
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.appleScriptFetchInfo()
        }
        // 每 0.5 秒轮询一次（无媒体播放时自动降频为每 2 秒，降低 osascript 子进程开销）
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.isTransitioning else { return }
            self.idlePollTick &+= 1
            if !self.nowPlaying.hasMedia && self.idlePollTick % 4 != 0 { return }
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.appleScriptFetchInfo()
            }
        }
        // 本地推进播放进度（0.1s 精度，实现逐字歌词跟进）
        mediaTicker = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            guard self.nowPlaying.isPlaying, self.nowPlaying.hasMedia else { self.mediaTickDate = now; return }
            // 展开/收起动画期间不推进进度（0.1s 精度损失不可感知），把主线程让给过渡动画
            guard !self.isTransitioning else { self.mediaTickDate = now; return }
            // 逐帧进度只有「展开且停留在媒体页」时才看得见（进度条/歌词）；其余场景降到 1 秒一次。
            // 收起态每秒 10 次全界面重绘，正是音量 HUD、跑马灯动画被拖出卡顿的来源。
            self.mediaTick &+= 1
            if !self.mediaPageVisible && self.mediaTick % 10 != 0 { return }
            // 用真实间隔推进（节流期间会被跳过，因此必须累计补上）
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
        guard #available(macOS 11.0, *) else { return }
        // MR 已确认失效：不再查询（避免空字典把 AppleScript 数据清空）
        if mediaRemoteBroken { return }
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] dict in
            guard let self = self, !self.mediaRemoteBroken else { return }
            let d = dict as? [String: Any]
            // macOS 15.4+ 对非 Apple 签名二进制返回空字典 → 启用辅助进程读取
            if d == nil || d!.isEmpty {
                self.startHelperIfNeeded()
            }
            self.handleInfo(d)
        }
    }

    private func handleInfo(_ d: [String: Any]?) {
        guard let d = d else { return }
        // 防抖：100ms 内的重复更新跳过，避免 MediaRemote + 辅助进程同时触发导致跳动
        let now = Date()
        if now.timeIntervalSince(lastNowPlayingUpdate) < 0.1 { return }
        lastNowPlayingUpdate = now
        var np = nowPlaying
        // 歌曲是否变化（仅切歌/换艺术家时允许进度大幅回退，避免系统缓存值回退导致抽搐）
        let newTitle = (d[kTitle] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let newArtist = (d[kArtist] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let songChanged = (newTitle != nil && newTitle != np.title) || (newArtist != nil && newArtist != np.artist)
        // 仅在字段存在时更新，避免信息获取延迟导致已显示内容被清空
        if let t = newTitle { np.title = t }
        if let a = newArtist { np.artist = a }
        if let al = d[kAlbum] as? String, !al.isEmpty { np.album = al }
        if let dur = d[kDuration] as? Double, dur > 0 { np.duration = dur }
        if let el = d[kElapsed] as? Double {
            // 进度校正：本地每秒推进为主。系统值仅「明显前进（>0.3s）」或
            // 「切歌时的大幅回退」才采用，避免系统缓存值回退把进度往回拉（抽搐）
            if el > np.elapsed + 0.3 || (songChanged && el < np.elapsed - 2.0) {
                np.elapsed = el
            }
        }
        if let r = d[kRate] as? Double {
            np.rate = r
            // 兜底：rate>0 即视为播放中，防止 isPlaying 状态未及时更新导致本地进度不推进
            if r > 0 { np.isPlaying = smoothedPlaying(true) }
        }
        if let data = d[kArtwork] as? Data, let img = NSImage(data: data) {
            np.artwork = img
        }
        // 判断是否有正在播放的媒体：标题为空且播放速率/状态都无 → 无媒体
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
        // 歌曲变化时加载歌词
        if np.title != nowPlaying.title || np.artist != nowPlaying.artist {
            nowPlaying = np
            fetchLyrics()
        } else {
            nowPlaying = np
        }
    }
#endif // !NOSMTC

    /// 上次 nowPlaying 更新时间（防抖用，各媒体源共用）
    var lastNowPlayingUpdate = Date.distantPast

    /// 播放状态防抖计数：rate 偶发抖动（上报的 isPlaying 偶尔为 false）时，
    /// 需连续 2 次上报 false 才确认暂停，避免本地进度推进被频繁打断造成抽搐
    private var playingFalseStreak = 0

#if !NOSMTC
    private func smoothedPlaying(_ raw: Bool) -> Bool {
        if raw { playingFalseStreak = 0; return true }
        playingFalseStreak += 1
        return playingFalseStreak < 2
    }

    func fetchPlaying() {
        guard #available(macOS 11.0, *) else { return }
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
    // ---- 辅助进程（macOS 15.4+ MediaRemote 签名限制绕过） ----
    func startHelperIfNeeded() {
        guard !helperStarted else { return }
        helperStarted = true
        // 检查 /usr/bin/swift 和 Xcode Command Line Tools 是否可用（后台执行，避免主线程等待子进程）
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

    /// 在主线程启动辅助进程（管道读写需绑定主线程）
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
        // 防抖：100ms 内的重复更新跳过
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
            // 进度校正（同 handleInfo）：本地推进为主，系统值仅明显前进或切歌回退时采用，
            // 避免辅助进程缓存值回退导致进度条/歌词来回抽搐
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
        // 歌曲变化时加载歌词
        if np.title != nowPlaying.title || np.artist != nowPlaying.artist {
            nowPlaying = np
            fetchLyrics()
        } else {
            nowPlaying = np
        }
    }

#endif // !NOSMTC

    // ---- 歌词（网易云 API） ----
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
                  // 快速切歌竞态防护：搜索返回时歌曲已切换则丢弃，避免旧歌词挂到新歌上
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

    /// 当前歌曲的歌词查询键（标题+歌手），用于异步返回时的竞态校验
    private func currentLyricQuery() -> String {
        "\(nowPlaying.title) \(nowPlaying.artist)".trimmingCharacters(in: .whitespaces)
    }

    /// 从搜索结果中挑选与当前歌曲标题/歌手最匹配的一项（网易云搜索常把不相关结果排第一）
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
                  // 竞态防护：歌词返回时歌曲已切换则丢弃
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

    // 通知驱动的 emit 去抖：1 秒内多次通知只合并为一次（3 秒定时器兜底），
    // 避免高频通知让 emit 反复阻塞主线程等待数据
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
        guard #available(macOS 11.0, *) else { return }
        if mockMediaEnabled { mockSendCommand(cmd); return }
        // 播放/暂停命令在无媒体应用运行时不发送，避免系统自动启动 Apple Music
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
        // 网易云 CDP 直连：当前媒体源为网易云且通道已建立时直接控制（比媒体键更精准）
        if nowPlayingApp == NeteaseCDPClient.bundleId, NeteaseCDPClient.shared.sendControl(cmd) { return }
#if NOSMTC
        // 无 SMTC：直接 AppleScript，失败再用键盘媒体键模拟兜底
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
            // MR 失效（macOS 26/27）或不可用：后台执行 AppleScript（避免阻塞 UI），
            // 失败（无脚本化媒体应用）再用键盘媒体键模拟兜底
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                if !self.appleScriptSendCommand(cmd) {
                    self.simulateMediaKey(cmd)
                }
            }
        }
#endif
    }
#endif

    // ---- MediaRemote 不可用时的回退方案 ----

    /// 标记 MediaRemote 是否已确认不可用（避免重复尝试）
    private var mediaRemoteConfirmedUnavailable = false
    /// MediaRemote 实际失效（macOS 26/27：dlopen 成功但查询恒为空）→ 已切换到 AppleScript 轮询
    private var mediaRemoteBroken = false
    /// 是否收到过非空媒体信息（用于判定 MR 是否可用）
    private var mrDeliveredAnyData = false
    /// AppleScript 轮询空闲降频计数器（无媒体播放时每 4 tick 才查询一次）
    private var idlePollTick = 0
    /// 媒体查询并发防护：上一次 osascript 未返回时不发起新查询（防止子进程堆积）
    private let mediaQueryLock = NSLock()
    private var mediaQueryInFlight = false
    // ---- 多源仲裁：多个媒体同时播放时显示「最晚开启」的源 ----
    /// 每个源最近一次「暂停→播放」边沿时间（开启时间）
    private var mediaStartedAt: [String: Date] = [:]
    private var mediaWasPlaying: [String: Bool] = [:]
    /// AppleScript 源仲裁日志节流
    private var lastAppleArbLog = Date.distantPast

    /// 记录播放边沿：暂停→播放 视为「开启」，记下时间供仲裁比较
    func notePlaying(_ bundle: String, _ playing: Bool) {
        let was = mediaWasPlaying[bundle] ?? false
        if playing && !was { mediaStartedAt[bundle] = Date() }
        mediaWasPlaying[bundle] = playing
    }

    /// a 是否比 b 更晚开启（未知视为最早）
    func startedLater(_ a: String, than b: String) -> Bool {
        (mediaStartedAt[a] ?? .distantPast) > (mediaStartedAt[b] ?? .distantPast)
    }

    /// 源 a 的播放开始时间是否不晚于源 b（用于暂停态仲裁：相等或更早 → 保持当前显示，避免多源乒乓）
    func playedNotLaterThan(_ a: String, than b: String) -> Bool {
        (mediaStartedAt[a] ?? .distantPast) <= (mediaStartedAt[b] ?? .distantPast)
    }

    /// 通过 AppleScript 查询常用媒体应用并更新 nowPlaying
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
                // ---- 多源仲裁：同时播放多个媒体时显示「最晚开启」的源；暂停态显示「最晚播放」的源 ----
                self.notePlaying(bundleId, isPlaying)
                let cur = self.nowPlayingApp
                if cur != bundleId {
                    if isPlaying {
                        // 当前源也在播放且开启更晚 → 让位
                        if self.nowPlaying.isPlaying && self.startedLater(cur, than: bundleId) {
                            if Date().timeIntervalSince(self.lastAppleArbLog) > 3 {
                                self.lastAppleArbLog = Date()
                                startupLog("AppleScript 仲裁：\(bundleId) 让位（当前 \(cur) 在播且更晚开启）")
                            }
                            return
                        }
                    } else {
                        // 候选暂停：当前在播 → 不抢占；当前有显示且候选不晚于当前 → 保持；
                        // 当前无显示（冷启动/全暂停）→ 候选可直接展示
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
                // 仅明显前进或切歌时更新进度，避免跳动
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
                    // Apple Music 优化：切歌时导出专辑封面
                    if bundleId == "com.apple.Music" { self.fetchMusicArtwork(forTitle: title) }
                    // Spotify：切歌时经 oEmbed 取封面
                    if bundleId == "com.spotify.client" { self.fetchSpotifyArtwork(forTitle: title) }
                } else {
                    self.nowPlaying = np
                }
            }
            return
        }
    }

    /// Apple Music 专辑封面导出：AppleScript 只能输出文本，先把图片字节写临时文件再读取为 NSImage
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
                // 期间若已切歌则跳过，避免封面与歌曲错位
                guard self.nowPlaying.title == forTitle else { return }
                var np = self.nowPlaying
                np.artwork = img
                self.nowPlaying = np
            }
        }
    }

    /// Spotify 封面：AppleScript 的 artwork 仅返回占位数据，改用公开 oEmbed 接口按曲目 ID 取缩略图（无需鉴权）
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

    /// 设置封面（期间切歌则丢弃，避免封面与歌曲错位）
    func applyArtwork(_ img: NSImage, forTitle: String) {
        guard nowPlaying.title == forTitle else { return }
        var np = nowPlaying
        np.artwork = img
        nowPlaying = np
    }

    /// 通过 AppleScript 发送媒体控制命令；成功返回 true（失败由调用方走键盘媒体键兜底）
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
        // 先尝试已知 bundleId
        if !bundleId.isEmpty {
            let script = """
                tell application id "\(bundleId)"
                    \(action)
                end tell
                """
            if runAppleScript(script) != nil { return true }
        }
        // 回退：遍历所有已知媒体应用
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

    /// 通过 AppleScript 跳转进度
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

    /// 执行 AppleScript 并返回结果（通过 osascript 子进程，5 秒强制超时杀死，失败返回 nil）
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
        // 强制超时：媒体应用无响应时（如首次启动卡住）避免 osascript 子进程无限堆积
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

    /// 模拟键盘媒体键（CGEvent 方式，通用性强）
    private func simulateMediaKey(_ keyCode: Int32) {
        // NX 系统定义事件类型
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

        // 创建 NX 系统定义事件的 CGEvent
        // data1 格式：keyCode << 16 | keyState << 8 | NX_SUBTYPE
        let subType: Int16 = 0x8
        let keyDown = 0xA
        let keyUp = 0xB

        func postEvent(_ keyState: Int) {
            let data1 = (Int(nxKeyEvent) << 16) | (keyState << 8) | Int(subType)
            let data2 = 0 // 无额外参数
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
        // 短延迟后发送 keyUp
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            postEvent(keyUp)
        }
    }

    // ---- Mock 媒体（MediaRemote 不可用时验证 UI 交互） ----
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
                // 自动切到下一首
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
        // 生成纯色占位封面
        np.artwork = mockAlbumArt()
        // 加载歌词
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
        // 画一个简单的音符图标
        let note = "♪" as NSString
        note.draw(at: NSPoint(x: 14, y: 10), withAttributes: [.font: NSFont.systemFont(ofSize: 22), .foregroundColor: NSColor.white])
        img.unlockFocus()
        return img
    }

    // Mock 发送命令（不依赖 MediaRemote）
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

    // Mock 跳转进度
    func mockSeekMedia(to seconds: Double) {
        guard mockMediaEnabled else { return }
        var np = nowPlaying
        np.elapsed = min(max(seconds, 0), np.duration)
        nowPlaying = np
    }

    // ---- 时钟 ----
    private func startClock() {
        updateUptime()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // 过渡期间跳过：避免展开动画中途触发整窗重绘
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

    // ---- 电量 ----
    private func startBattery() {
        refreshBattery()
        batteryTimer = Timer.scheduledTimer(withTimeInterval: lowMemoryMode ? 60.0 : 45.0, repeats: true) { [weak self] _ in
            self?.refreshBattery()
        }
    }

    private func refreshBattery() {
#if APPSTORE
        // 沙盒环境：使用 IOKit 获取电池信息
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        let sources = snapshot.flatMap { IOPSCopyPowerSourcesList($0)?.takeRetainedValue() as? [CFTypeRef] } ?? []
        for ps in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot!, ps)?.takeUnretainedValue() as? [String: Any] {
                let cur = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 0
                let maxVal = desc[kIOPSMaxCapacityKey as String] as? Int ?? 1
                let state = desc[kIOPSPowerSourceStateKey as String] as? String ?? ""
                let pct: Double = maxVal > 0 ? Double(cur) / Double(maxVal) * 100 : 100
                let level = Int(pct)
                let charging = (state == kIOPSACPowerValue as String)
                DispatchQueue.main.async { [weak self] in
                    self?.batteryLevel = level
                    self?.isCharging = charging
                }
                return
            }
        }
#else
        // 电量查询通过子进程（pmset）实现：放到后台线程执行，避免阻塞主线程导致"未响应"
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
#endif
    }

    // ---- AirPods 连接检测（Core Audio 监听音频设备变化） ----
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

    /// 常见耳机/耳麦名称关键词（大小写不敏感），用于灵动岛连接提示
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

    // ---- 温度监测（CPU 温度 + 负载 + 热压力，powermetrics 需要 sudo 缓存，失败时显示热状态） ----
    private func startTempMonitor() {
        refreshTemp()
        tempTimer = Timer.scheduledTimer(withTimeInterval: lowMemoryMode ? 12.0 : 8.0, repeats: true) { [weak self] _ in
            self?.refreshTemp()
        }
    }

    private func refreshTemp() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            // 1) CPU 瞬时负载（host_cpu_load_info 返回累计值，需计算两次采样差值）
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

            // 2) CPU 温度：通过 IOKit 读取 SMC 传感器（无需 root）
            var temp: Double = 0
            // 尝试 Apple Silicon 的 IOService 温度传感器
            if let smcTemp = readSMCTemperature() {
                temp = smcTemp
            }
            // 如果 IOKit 方式失败，尝试 powermetrics（不需 sudo 的情况）
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

            // 3) 热压力状态
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

    /// 通过 IOKit 读取 CPU 温度传感器（Apple Silicon / Intel 均适用，无需 root）
    private func readSMCTemperature() -> Double? {
        // 遍历 IOService 树查找 CPU 温度传感器
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOPlatformDevice")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        var service: io_object_t = IOIteratorNext(iterator)
        while service != 0 {
            defer { IOObjectRelease(service) }
            // 检查名称是否包含 CPU 温度相关关键词
            let nameKey = "IOName" as CFString
            if let name = IORegistryEntryCreateCFProperty(service, nameKey, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
                let lower = name.lowercased()
                // 只匹配 CPU 相关的温度传感器，避免读到电池温度
                if (lower.contains("temp") || lower.contains("die")) && !lower.contains("battery") {
                    // 尝试读取 temperature 属性
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
            // 也尝试直接读取 "Temperature" 属性（不限制名称，但检查合理范围）
            let tempKey = "Temperature" as CFString
            if let val = IORegistryEntryCreateCFProperty(service, tempKey, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                let celsius = Double(val) / 100.0
                if celsius > 20 && celsius < 150 {
                    // 排除电池服务
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

    // ---- TraeWork 监测（进程运行状态 + CPU + 内存） ----
    private func startTraeMonitor() {
        refreshTraeStatus()
        traeTimer = Timer.scheduledTimer(withTimeInterval: lowMemoryMode ? 4.0 : 2.0, repeats: true) { [weak self] _ in
            self?.refreshTraeStatus()
        }
    }

    private func refreshTraeStatus() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
#if !APPSTORE
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
            var totalTime: Double = 0   // 累计 CPU 秒（HH:MM:SS / MM:SS）
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
            // 瞬时 CPU = 两次采样累计 CPU 时间差值 / 采样间隔（ps 的 pcpu 为生命周期平均，不可用于忙碌判定）
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
                self?.traeCPU = instantCPU
                self?.traeMemoryMB = totalRSS / 1024.0
                self?.aiUsage["trae"] = (instantCPU, totalRSS / 1024.0)
                self?.aiGpuActive["trae"] = gpuSeen
            }
#else
            // 沙盒环境：无法使用 ps 命令，通过 NSWorkspace 检测 TraeWork 运行状态
            let running = NSWorkspace.shared.runningApplications.contains { app in
                app.localizedName?.contains("Trae") == true || app.bundleIdentifier?.contains("trae") == true
            }
            DispatchQueue.main.async {
                self?.traeRunning = running
                self?.traeCPU = 0
                self?.traeMemoryMB = 0
            }
#endif
        }
    }

    /// 解析 ps time 列（HH:MM:SS 或 MM:SS）为秒
    private static func parseCPUTime(_ s: String) -> Double {
        let comps = s.split(separator: ":").compactMap { Double($0) }
        if comps.count == 2 { return comps[0] * 60 + comps[1] }
        if comps.count == 3 { return comps[0] * 3600 + comps[1] * 60 + comps[2] }
        return 0
    }

    // ---- AI 编码工具监测（Claude Code / Codex CLI） ----

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
            // 采样：一次性读取进程时间/RSS/完整命令，按工具归类（Trae Work 由 refreshTraeStatus 统计；Trae Code 安装态走 traeCodeInstalled 实时判断）
            var claudeRunning = false
            var codexRunning = false
            var claudeAccum = 0.0, claudeRSS = 0.0
            var codexAccum = 0.0, codexRSS = 0.0
            var wbAccum = 0.0, wbRSS = 0.0
            var traecodeAccum = 0.0, traecodeRSS = 0.0
            var gpuFlags: [String: Bool] = [:]   // 存在 GPU Helper 进程视为 GPU 活跃
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
            // WorkBuddy / Trae Code 为桌面 App：按运行中的应用兜底检测
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
            // 瞬时 CPU（两次采样累计差 / 间隔）
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

    /// 在 PATH 中查找可执行文件（不 spawn 进程）
    private static func findExecutableInPATH(_ name: String) -> Bool {
        let pathEnv = ProcessInfo.processInfo.environment["PATH"]
            ?? "/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:\(NSHomeDirectory())/.local/bin"
        return pathEnv.split(separator: ":")
            .map { "\($0)/\(name)" }
            .contains { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// 找到已安装的 Trae Code（AI 编程 IDE：Trae CN.app / Trae.app）
    private static func traeCodeAppURL() -> URL? {
        for n in ["Trae CN.app", "Trae.app"] {
            let u = URL(fileURLWithPath: "/Applications/\(n)")
            if FileManager.default.fileExists(atPath: u.path) { return u }
        }
        return nil
    }

    /// 找到已安装的 Trae Work（智能工作台，原 TRAE SOLO：TRAE SOLO CN.app）
    private static func traeWorkAppURL() -> URL? {
        let u = URL(fileURLWithPath: "/Applications/TRAE SOLO CN.app")
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }

    /// 在终端中启动 CLI 编码工具（claude / codex）
    func launchAICLI(_ kind: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            _ = self.osascript("tell application \"Terminal\" to do script \"\(kind)\"")
        }
    }

    /// 指针是否位于灵动岛区域（悬停状态 + 屏幕坐标兜底检测）
    var pointerOverIsland: Bool {
        if isHovering { return true }
        let m = NSEvent.mouseLocation
        guard geometry.screenFrame != .zero else { return false }
        let frame = geometry.screenFrame   // 目标屏幕帧（跟随所选显示屏幕）
        let w = windowWidth, h = isExpanded ? windowHeight : compactHeight
        // 与 positionWindow 保持一致：计入水平/垂直偏移
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

    /// Trae Code（AI 编程 IDE）是否已安装
    var traeCodeInstalled: Bool { Self.traeCodeAppURL() != nil }

    /// Trae Work（智能工作台）是否已安装
    var traeWorkInstalled: Bool { Self.traeWorkAppURL() != nil }

    /// 启动 / 切换到 Trae Work（原 TRAE SOLO 智能工作台，未安装则打开官网下载页）
    func openTraeWork() {
        if let url = Self.traeWorkAppURL() {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else if let u = URL(string: "https://www.trae.cn") {
            NSWorkspace.shared.open(u)
        }
    }

    /// 启动 / 切换到 Trae Code（AI 编程 IDE，未安装则打开官网下载页）
    func openTraeCode() {
        if let url = Self.traeCodeAppURL() {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else if let u = URL(string: "https://www.trae.cn") {
            NSWorkspace.shared.open(u)
        }
    }

    /// 打开腾讯 WorkBuddy 桌面应用（未安装则打开官网下载页）
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

    /// 打开独立设置窗口（菜单栏图标「设置」入口；0 外观 / 1 系统 / 2 跑马灯 / 3 小组件）
    func openSettings(tab: Int = 0) {
        SettingsWindowController.shared.show(tab: tab)
    }

    // ---- 合盖不休眠（caffeinate 保持唤醒 + pmset disablesleep 最佳尝试） ----
    /// 是否 Apple Silicon：M 系列合盖睡眠为系统/硬件级行为，软件无法完全阻止（仅外接显示器时可合盖不休眠）
    private static var isAppleSilicon: Bool {
        var value: Int = 0
        var size = MemoryLayout<Int>.size
        sysctlbyname("hw.optional.arm64", &value, &size, nil, 0)
        return value == 1
    }

    func toggleLidNoSleep() {
#if APPSTORE
        flashMessage("App Store 版不支持合盖不休眠")
#else
        if lidNoSleepEnabled {
            lidProcess?.terminate()
            lidProcess = nil
            lidNoSleepEnabled = false
            // 恢复默认：全部电源方式恢复系统默认睡眠行为（sudo 免密不可用则静默失败，caffeinate 已停止）
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            p.arguments = ["-n", "/usr/bin/pmset", "-a", "disablesleep", "0"]
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
            try? p.run()
        } else {
            // caffeinate -d -i -s -u：阻止显示器/空闲/系统睡眠并保持用户活跃（无需 root，Intel 上合盖不休眠有效）
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
            // 最佳尝试：sudo 可用时强制所有电源方式下禁用合盖休眠（Intel 有效；Apple Silicon 无此能力）
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
#endif
    }

    // ---- 系统音量（Core Audio 公开 API，沙盒兼容） ----
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

    /// 系统音量服务「虚拟主音量」：系统音量 UI 使用的通道，对所有输出设备
    /// （内置 / 蓝牙耳机 / HDMI / USB 声卡等）统一生效，是程序化控制系统音量的推荐方式。
    /// kAudioHardwareServiceDeviceProperty_VirtualMainVolume 已从公共头移除，用字面量 'volm'
    private var virtualVolumeAddr: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(0x766F6C6D), // 'volm'
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
    }

    /// 串行执行 osascript 音量命令（进程启动约 120ms：串行保证顺序与不堆积）
    private static let volumeOSQueue = DispatchQueue(label: "islex.volume.osascript")
    /// 最近一次待执行的音量设置任务（用于合并连续设置，防止队列积压旧值）
    private var volumeSetWork: DispatchWorkItem?

    /// 执行 osascript 并返回标准输出（失败返回 nil）
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
                    // 有「刚请求、尚未落地」的目标时，读到的多半还是旧值：直接忽略，
                    // 等最后一次设置读回校准即可（否则进度条会被旧值拉回去）
                    if let target = self.pendingVolumeTarget,
                       let since = self.pendingVolumeSince,
                       Date().timeIntervalSince(since) < 3.0,
                       abs(real - target) > 0.001 {
                        return
                    }
                    self.pendingVolumeTarget = nil
                    self.pendingVolumeSince = nil
                    // 仅在真正变化时赋值，避免「读回的值与内存值相同」也触发全界面重绘
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
                    // 静音刚请求、尚未落地时读到的仍是旧状态：忽略（否则图标会来回翻）
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

    /// 同步读取当前音量（0-1；osascript 系统音量通道，约 120ms，勿在主线程调用）
    func currentVolumeSync() -> Float {
        if let s = osascript("output volume of (get volume settings)"), let v = Float(s) {
            return max(0, min(1, v / 100))
        }
        return systemVolume
    }

    /// 同步读取当前静音状态
    func currentMuteSync() -> Bool {
        if let s = osascript("output muted of (get volume settings)") {
            return s.lowercased() == "true"
        }
        return systemMuted
    }

    func setSystemVolume(_ vol: Float) {
        let v = max(0, min(1, vol))
        // 立即更新内存值：HUD / 滑块即时响应，后台 osascript 实际设置。
        // 仅在真正变化时赋值：@Published 每次赋值都会让整个界面重绘，而音量键连按会走到这里十几次/秒
        if abs(v - systemVolume) > 0.0005 { systemVolume = v }
        #if PERF
        PerfProbe.note("set", Double(v))
        #endif
        let percent = Int((v * 100).rounded())
        // 合并连续设置：取消上一个尚未执行的任务，串行队列里只保留最新音量值，
        // 避免快速连续调节时积压大量 osascript 进程（每个约 240ms）导致音量滞后与 UI 卡顿
        volumeSetGeneration += 1
        let gen = volumeSetGeneration
        // 记录目标值：落地之前任何读回值都不可信
        pendingVolumeTarget = v
        pendingVolumeSince = Date()
        volumeSetWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            _ = self.osascript("set volume output volume \(percent)")
            // 只有「最后一次请求」才允许读回校准：更早的请求读到的是中间态，
            // 用它回写会把用户刚按出来的值拉回去
            guard gen == self.volumeSetGeneration else { return }
            guard let s = self.osascript("output volume of (get volume settings)"), let rv = Float(s) else {
                DispatchQueue.main.async { self.clearPendingVolume(gen: gen) }
                return
            }
            let real = max(0, min(1, rv / 100))
            DispatchQueue.main.async {
                guard gen == self.volumeSetGeneration else { return }
                // 校准：系统可能限制上限，以真实值为准（此时队列已排空，读到的是最终值）
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

    /// 队列排空后清理「待落地目标」（仅最后一次请求有效）
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

    // ---- 音量变化监听：外部改音量时同步 UI，并在灵动岛显示提示 ----
    func startVolumeMonitor() {
        guard !volumeMonitorsStarted else { return }
        volumeMonitorsStarted = true
        // 默认输出设备变化（切换输出 / 插拔耳机）时重挂监听
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
        // 先移除旧设备上的监听，再挂到当前默认输出设备
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

    /// 媒体页是否正在显示：逐帧进度 / 逐字歌词只在此时需要 0.1s 精度
    private var mediaPageVisible: Bool {
        isExpanded && currentPage == displayPosition(of: 1)
    }

    /// 音量值变化回调：系统外部调节 / 灵动岛自身调节都会触发
    func onSystemVolumeChanged() {
        // 去抖合并：音量键连按会连续触发系统回调，每次都起两个 osascript 子进程
        // 会积压（每个约 240ms）并拖慢整机响应，看起来就是动画卡顿
        scheduleVolumeRefresh()
        suppressNextVolumeToast = false
    }

    /// 合并短时间内的重复音量刷新请求
    func scheduleVolumeRefresh(after delay: TimeInterval = 0.35) {
        volumeRefreshWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.refreshVolume() }
        volumeRefreshWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

#if !APPSTORE
    /// 音量键被拦截后由 VolumeKeyInterceptor 调用：手动调音量并显示岛内提示
    func handleVolumeKey(_ nxCode: Int, fine: Bool = false) {
        // 基于内存值步进（后台 osascript 持续校准真实音量，避免在主线程同步调用阻塞）
        let cur = systemVolume
        // 常规步进 1/16（6.25%）；Option 微调为 1/64（1.5625%），与系统 Option+音量键行为一致
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

    /// 键盘亮度键处理（系统无公开读值 API：放行原生调节，灵动岛同步显示自维护级数）
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
#endif

    // ---- 番茄钟 ----
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

    // ---- 文件中转站 ----
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

    // ---- 待办事项 CRUD ----
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

    // ---- 格式转换器 ----
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
                    // 收起态岛上闪烁"转换完成"提示（软件 ↔ 灵动岛互联）
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
#if APPSTORE
        return false
#else
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
#endif
    }

    private static func convertText(_ src: URL, to dest: URL, encoding: String) -> Bool {
        // 源编码自动检测：优先 UTF-8，否则按 GB18030
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
#if APPSTORE
        // 沙盒环境：使用 Swift String 编码转换替代 iconv
        guard let data = try? Data(contentsOf: src) else { return false }
        let srcEncoding: String.Encoding
        switch sourceEnc {
        case "GB18030": srcEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x0631)))
        default: srcEncoding = .utf8
        }
        guard let str = String(data: data, encoding: srcEncoding) else { return false }
        let dstEncoding: String.Encoding
        switch targetEnc {
        case "UTF-16LE": dstEncoding = .utf16LittleEndian
        case "GB18030": dstEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x0631)))
        case "BIG5": dstEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x0604)))
        default: dstEncoding = .utf8
        }
        guard let outData = str.data(using: dstEncoding) else { return false }
        do {
            try outData.write(to: dest)
            return true
        } catch { return false }
#else
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
#endif
    }

    // ---- 应用快捷启动 ----
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
        // 兼容历史配置：旧版存的是 URL 字符串（file:///...），归一化为本地路径，避免 10.15 上
        // NSWorkspace.icon(forFile:) 收到非路径字符串导致段错误
        var p = path
        if p.hasPrefix("file://") {
            p = URL(string: p)?.path ?? p
        }
        if isWeb {
            guard let url = URL(string: p) else { return nil }
            return AppShortcut(name: name, icon: icon, url: url, iconImage: nil, isWebLink: true, bundleId: nil)
        }
        // 优先用 LaunchServices 按 bundle id 定位（沙盒环境下无法直接读取 /Applications 下的文件）
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
        // 存在性检查：沙盒下文件系统不可读时以 bundle id 解析结果为准
        if resolvedBundleId == nil, !FileManager.default.fileExists(atPath: resolvedPath) { return nil }
        // 最后兜底：确保传给 icon(forFile:) 的是完整路径而非 URL 字符串（10.15 段错误防护）
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
        // 配置为空或不存在：加载默认应用
        var result: [AppShortcut] = []
        for a in defaultApps {
            if let s = makeShortcut(name: a.name, icon: a.icon, path: a.path, isWeb: a.isWeb, bundleId: a.bundleId) {
                result.append(s)
            }
        }
        // 确保至少有网页快捷方式（MiniMax、Trae Work）
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
        // 本地应用存真实路径（/Applications/...），网页应用存 URL，避免 10.15 上非路径字符串崩溃
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

    // ---- 快速小组件预设（钉钉/微信等，本地应用优先，失败回退 URL Scheme） ----
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

    /// 一键添加预设小组件（已存在则直接启动；本地已安装优先）
    func addPresetApp(_ p: PresetQuickApp) {
        if let existing = apps.first(where: { $0.name == p.name }) {
            launch(existing)
            return
        }
        // 优先用已安装的本地应用（按 bundle id 定位），启动更稳、带真实图标
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

    /// 添加自定义链接（网页或应用 Scheme）
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

    /// 弹窗添加自定义链接
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
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.application]
        } else {
            panel.allowedFileTypes = ["app"]
        }
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
        // 立即退出编辑模式，避免点图标无响应
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
#if !APPSTORE
        // 网易云：附加调试端口参数启动，接通 CDP 直连
        if let args = NeteaseCDPClient.launchArgs(for: app.url.path) { cfg.arguments = args }
#endif
        NSWorkspace.shared.openApplication(at: app.url, configuration: cfg) { _, error in
            if error != nil {
                DispatchQueue.main.async { self.launchByName(app) }
            }
        }
        withExpanded(false)
    }

    private func openWebLink(_ app: AppShortcut) {
        let scheme = app.url.scheme ?? ""
        // 网页/邮件：直接打开并收起，不等待回调
        if scheme == "http" || scheme == "https" || scheme == "mailto" {
            NSWorkspace.shared.open(app.url)
            withExpanded(false)
            return
        }
        // 应用 Scheme：有对应处理程序则直接打开（同步判定，无回调依赖）
        if NSWorkspace.shared.urlForApplication(toOpen: app.url) != nil {
            NSWorkspace.shared.open(app.url)
            withExpanded(false)
            return
        }
        // 兜底：bundle id → open -a 应用名
        launchByName(app)
    }

    /// 多重兜底：预设 bundle id → 磁盘扫描应用名 → open -a
    private func launchByName(_ app: AppShortcut) {
        // 1) 预设 bundle id 定位本地应用
        for bid in presetBundleIds(for: app.url.absoluteString) {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
                openAppURL(appURL)
                return
            }
        }
        // 2) 磁盘扫描：按应用名定位（兼容中文显示名/包名，不依赖 open -a 的命名规则）
        if let found = findAppURL(named: app.name) {
            openAppURL(found)
            return
        }
        // 3) 最终兜底
#if APPSTORE
        // 沙盒环境：无法使用 Process()，尝试直接打开 URL Scheme 或网页链接
        NSWorkspace.shared.open(app.url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            DispatchQueue.main.async {
                if error == nil {
                    self.withExpanded(false)
                } else {
                    self.flashMessage("未安装「\(app.name)」，无法打开")
                }
            }
        }
#else
        // 非沙盒：open -a 应用名
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
#endif
    }

    private func openAppURL(_ u: URL) {
        let cfg = NSWorkspace.OpenConfiguration()
#if !APPSTORE
        if let args = NeteaseCDPClient.launchArgs(for: u.path) { cfg.arguments = args }
#endif
        NSWorkspace.shared.openApplication(at: u, configuration: cfg)
        withExpanded(false)
    }

    /// 按应用名在常见安装目录中扫描定位 .app（文件名、包名、显示名三种匹配）
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

    /// 岛上瞬时提示（2 秒后消失）
    func flashMessage(_ text: String) {
        quickMsgWork?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { quickMsg = text }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.35)) { self?.quickMsg = nil }
        }
        quickMsgWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }

    /// 媒体跳转：设置当前播放进度（秒），并立即本地更新进度条，消除等待系统回执的延迟
#if !APPSTORE
    func seekMedia(to seconds: Double) {
        guard #available(macOS 11.0, *) else { return }
        guard seconds >= 0, nowPlaying.duration > 0 else { return }
        let target = min(seconds, nowPlaying.duration)
        if mockMediaEnabled { mockSeekMedia(to: target); return }
#if !APPSTORE
        // 网易云直连：CDP 直接跳转进度
        if nowPlayingApp == NeteaseCDPClient.bundleId, NeteaseCDPClient.shared.seek(to: target) {
            var np = nowPlaying
            np.elapsed = target
            nowPlaying = np
            return
        }
#endif
#if !NOSMTC
        if MRMediaRemoteIsAvailable() && !mediaRemoteBroken {
            MRMediaRemoteSetElapsedTime(target)
        }
#endif
        // AppleScript 回退（MediaRemote 不可用时）
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.appleScriptSeekMedia(to: target)
        }
        var np = nowPlaying
        np.elapsed = target
        nowPlaying = np
    }
#endif

    func withExpanded(_ v: Bool, resetPage: Bool = true) {
        // 提醒未确认时禁止收起（保持停留于灵动岛区域）
        if !v && showReminder { return }
        // 收起时退出编辑模式：否则应用页点图标不响应
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
        // 低配机器（≤6GB/10.15 核显）或系统开启「减少动效」：展开/收起直接切换
        if lowMemoryMode || reduceMotion {
            endTransition()
            isExpanded = v
        } else {
            // 过渡期静默：走马灯只保留内层描边、极光不渲染、媒体进度与时钟暂停刷新，
            // 避免与展开动画抢主线程（展开掉帧的主因之一）
            beginTransition()
            withAnimation(.spring(response: 0.52, dampingFraction: 0.58)) {
                isExpanded = v
            } completion: {
                self.endTransition()
            }
        }
        // 展开/收起后刷新窗口位置：展开态窗口整体下移到菜单栏下方，收起态回到顶部/悬浮位置
        // 使用与 SwiftUI spring 同步的 AppKit 窗口动画，消除 frame 瞬间跳变与内容动画的视觉撕裂
        repositionWindowAnimated()
    }

    /// 进入展开/收起过渡期（装饰动画降级 + 后台刷新暂停）
    private func beginTransition() {
        isTransitioning = true
        // 兜底：动画被打断/回调异常时也要恢复装饰动画
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

    // ---- 自动收起：鼠标悬停时保持展开；离开后默认 0.75 秒收起，文件中转站页延长为 5 秒 ----
    func startAutoCollapseTimer() {
        stopAutoCollapseTimer()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // 仅当「正在播放 且 当前停留在媒体页」时才保持展开（方便操作音乐）；
            // 其他页面即使播放中也正常自动收起
            guard !(self.nowPlaying.isPlaying && self.currentPage == self.displayPosition(of: 1)),
                  !self.pomodoroIsRunning,
                  !self.isDragTargeted,
                  !self.isHovering,
                  !self.showReminder,
                  self.isExpanded else { return }
            // 兜底：直接检测鼠标屏幕坐标。窗口展开/重绘时 onHover 可能漏触发 true 或误报退出，
            // 导致 isHovering 为 false。若指针实际仍在岛上，则视为悬停：不收起并重新计时，
            // 直到指针真正离开岛上区域
            if self.pointerOverIsland {
                self.isHovering = true
                self.startAutoCollapseTimer()
                return
            }
            self.withExpanded(false)
        }
        autoCollapseWork = work
        // 文件中转站页（逻辑页 3）：鼠标离开后等待 5 秒再收起，方便拖放/整理文件；其他页 0.75 秒
        let delay: TimeInterval = (currentPage == displayPosition(of: 3)) ? 5.0 : 0.75
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// 更新悬停状态：悬停时暂停自动收起，离开后恢复自动收起计时（默认 0.75 秒，文件中转站页 5 秒）
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

    // ---- 页面指示点（收起态上滑显示） ----
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
#if !APPSTORE
        pollTimer?.invalidate()
        mediaTicker?.invalidate()
#endif
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
#if !APPSTORE
        // 终止辅助进程（关闭 stdin pipe 会让辅助进程自行退出）
        helperInput?.fileHandleForWriting.closeFile()
        helperProcess?.terminate()
#endif
#if !APPSTORE
        // 停止合盖不休眠
        lidProcess?.terminate()
#endif
    }
}

