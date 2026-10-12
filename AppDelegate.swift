//  IsleX 灵屿 —— 内容视图与 AppDelegate
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

// MARK: - 内容视图（点击穿透 + 拖放支持）

/// 灵动岛窗口：borderless 默认不能成为 key window，
/// 会导致 NSTextView 等原生输入控件点击后无法获得键盘焦点。重写允许成为 key。
final class NotchWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class NotchContentView: NSView {
    weak var state: AppState?

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let st = state else { return nil }
        let p = convert(point, from: nil)
        return st.islandRect(expanded: st.isExpanded).contains(p) ? super.hitTest(point) : nil
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var acceptsFirstResponder: Bool { true }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    private let state = AppState.shared
    private var statusItem: NSStatusItem!
    private var globalMouseMonitor: Any?
    private var keyMonitor: Any?
    private var scrollMonitor: Any?
    private var islandRightClickMonitor: Any?
    private var pendingCollapse: DispatchWorkItem?
    var scrollAccumulator: CGFloat = 0
    var lastScrollTime: Date = .distantPast
    var lastPageSwitch: Date = .distantPast
    /// 当前滑动手势是否已切过页（一次滑动只切换一页）
    var swipeHandled = false

    func applicationDidFinishLaunching(_ note: Notification) {
        startupLog("applicationDidFinishLaunching 开始")
        state.geometry = NotchGeometry.current(on: state.targetScreen)
        startupLog("geometry 完成")
        setupWindow()
        startupLog("setupWindow 完成")
        setupStatusItem()
        startupLog("setupStatusItem 完成")
        setupMonitors()
        startupLog("setupMonitors 完成")
        // 多显示器无感切换：显示器接入/移除/主屏切换/分辨率变化时立即刷新几何并瞬时重定位，
        // 避免灵动岛窗口被系统/延迟重排拖着跨屏移动
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.state.geometry = NotchGeometry.current(on: self.state.targetScreen)
            self.positionWindow()
        }
        showPermissionGuideIfNeeded()
        startupLog("启动流程全部完成")
        startSuppressStatusPolling()
        scheduleSelfQuarantineRemoval()
        startRuntimeHeartbeat()
        // OTA 更新检查（首次启动 + 每 6 小时）
        Updater.checkIfNeeded()
        startupLog("OTA 更新检查已启动")
    }

    /// 运行期心跳日志：每 30 秒在主线程写一行。
    /// 作用：区分"未响应"是主线程卡死（心跳停止）还是内存/渲染压力（心跳继续增长）。
    private func startRuntimeHeartbeat() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            startupLog("心跳正常：运行中")
        }
        // 主线程响应探针：从后台队列投递到主队列并测量延迟，
        // 延迟 >0.3s 即记录——若持续记录说明主线程被持续占用/阻塞
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            let start = DispatchTime.now()
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    let d = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
                    if d > 0.3 { startupLog("主线程延迟 \(String(format: "%.2f", d))s") }
                }
            }
        }
    }

    /// 首次运行成功后自动移除自身隔离属性：此后双击直接打开，不再出现
    /// "Apple 无法检查其是否包含恶意软件" / "来自身份不明的开发者" 提示
    private func scheduleSelfQuarantineRemoval() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let path = Bundle.main.bundlePath
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            p.arguments = ["-dr", "com.apple.quarantine", path]
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
            try? p.run()
        }
    }

    /// 音量键拦截授权状态轮询（3 秒）：授权辅助功能后自动生效并刷新界面，无需重启
    private func startSuppressStatusPolling() {
#if !APPSTORE
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state.volumeKeySuppressEnabled else { return }
            self.state.refreshVolumeSuppressStatus()
        }
#endif
    }

    /// 新电脑首次运行：检测系统权限，未授权时弹出说明弹窗并引导到系统设置
    private func showPermissionGuideIfNeeded() {
        let hasAccessibility = AXIsProcessTrusted()
        guard !hasAccessibility else { return }

        // 等窗口与菜单栏就绪后再弹（0.8 秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            let alert = NSAlert()
            alert.messageText = "灵屿需要系统权限"
#if APPSTORE
            alert.informativeText = """
            为在电脑上正常工作，灵屿需要以下权限（仅本机使用，不上传任何数据）：

            · 辅助功能：用于全局点击检测、键盘快捷操作（收起/切页）与音量调节提示（音量变化时在灵屿显示）

            ────────────────────────
            免责声明：
            1. 本应用为独立开发工具，与 Apple Inc. 无任何关联，亦不构成对苹果产品、灵动岛或相关商标的认可或授权。
            2. 本应用核心功能完全在本机本地运行，所获取的权限数据（含鼠标位置、音量等）仅用于灵屿的交互与视觉呈现，不会上传、存储或分享给任何第三方。
            3. 因使用本应用导致的任何直接或间接损失，开发者不承担法律责任。
            4. 继续使用即视为已阅读并同意上述条款。

            小贴士：想要媒体控制、歌词、动态模糊等完整体验，可在浏览器搜索「IsleX 灵屿 官网」免费下载完整版。
            """
#else
            alert.informativeText = """
            为在电脑上正常工作，灵屿需要以下权限（仅本机使用，不上传任何数据）：

            · 辅助功能：用于全局点击检测、键盘快捷操作（收起/切页）与音量键拦截（屏蔽系统音量动画，可在系统页关闭）

            ────────────────────────
            免责声明：
            1. 本应用为独立开发工具，与 Apple Inc. 无任何关联，亦不构成对苹果产品、灵动岛或相关商标的认可或授权。
            2. 本应用核心功能完全在本机本地运行，所获取的权限数据（含鼠标位置、音量键事件等）仅用于灵屿的交互与视觉呈现，不会上传、存储或分享给任何第三方。
            3. 因使用本应用导致的任何直接或间接损失（包括但不限于系统设置变更、软件冲突、性能影响等），开发者不承担法律责任。
            4. 继续使用即视为已阅读并同意上述条款。
            """
#endif
            var actions: [String] = []
            if !hasAccessibility { actions.append("打开辅助功能设置") }
            actions.append("稍后")
            let buttons = actions.map { alert.addButton(withTitle: $0) }
            alert.alertStyle = .warning
            if let win = self.window { alert.beginSheetModal(for: win) { resp in
                self.handlePermissionChoice(resp: resp, buttons: buttons, hasAX: hasAccessibility)
            } } else {
                let resp = alert.runModal()
                self.handlePermissionChoice(resp: resp, buttons: buttons, hasAX: hasAccessibility)
            }
        }
    }

    private func handlePermissionChoice(resp: NSApplication.ModalResponse, buttons: [NSButton], hasAX: Bool) {
        let idx = buttons.firstIndex { $0.tag == resp.rawValue } ?? -1
        if !hasAX, idx == 0 {
            openSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        }
    }

    private func openSettings(_ scheme: String) {
        if let url = URL(string: scheme) {
            NSWorkspace.shared.open(url)
        }
    }

    private func setupWindow() {
        let s = CGSize(width: state.windowWidth, height: state.windowHeight)
        window = NotchWindow(contentRect: NSRect(x: 0, y: 0, width: s.width, height: s.height),
                             styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isMovable = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.level = .statusBar
        window.animationBehavior = .none   // 禁用窗口移动/缩放动画：显示器切换时瞬时无感定位
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isExcludedFromWindowsMenu = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let container = NotchContentView()
        container.state = state
        container.translatesAutoresizingMaskIntoConstraints = false
        let host = NSHostingView(rootView: NotchRootView(state: state))
        host.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.topAnchor.constraint(equalTo: container.topAnchor),
            host.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        window.contentView = container

        positionWindow()
        window.orderFrontRegardless()
    }

    private func positionWindow(animated: Bool = false, duration: TimeInterval = 0.5) {
        guard let screen = state.hostScreen ?? NSScreen.main else { return }
        let frame = screen.frame
        let w = state.windowWidth, h = state.windowHeight
        window.level = .statusBar
        // 形态定位：自动形态贴合硬件刘海；悬浮胶囊屏幕居中、菜单栏下方
        let cx: CGFloat
        let yOffset: CGFloat
        if state.appearanceShape == 1 {
            cx = frame.midX
            yOffset = max(state.geometry.notchHeight, state.menuBarHeight)
        } else {
            cx = state.geometry.hasNotch ? state.geometry.notchCenterX : frame.midX
            yOffset = 0
        }
        let x = cx - w / 2 + state.appearanceOffsetX
        let y = frame.maxY - h + state.appearanceOffsetY - yOffset
        let target = NSRect(x: x, y: y, width: w, height: h)
        // 目标 frame 未变：直接返回。展开/收起与切页都会调用到这里，
        // 无变化时 setFrame(display: true) 会白白整窗重绘一次
        if window.frame == target { return }
        if animated && !state.lowMemoryMode && !state.reduceMotion {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = duration
                window.animator().setFrame(target, display: true)
            }
        } else {
            window.setFrame(target, display: true)
        }
    }

    /// 供外观设置调用：尺寸/偏移变化后重新定位窗口（瞬时生效，避免滑块拖动时动画堆积）
    func repositionIsland() {
        positionWindow(animated: false)
    }

    /// 展开/收起时同步窗口 frame 动画（略短于 SwiftUI spring，让窗口先动、内容跟进更自然）
    func repositionIslandForExpandCollapse() {
        positionWindow(animated: true, duration: 0.52)
    }

    private func setupMonitors() {
        // 全局鼠标点击：点击岛外区域收起。但拖放文件到中转站时不收起
        // 注意：全局监控器不支持 leftMouseDragged，改用"按下后检测鼠标移动"判断拖放
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard let self = self else { return }
            // 正在拖放文件到中转站，不收起
            if self.state.isDragTargeted { return }
            // 记录按下位置，延迟后检测鼠标是否移动（移动 = 拖放操作）
            let downPos = NSEvent.mouseLocation
            let work = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.state.isDragTargeted { return }
                // 检查鼠标是否发生移动：移动说明是拖放，不收起
                let current = NSEvent.mouseLocation
                let dx = abs(current.x - downPos.x)
                let dy = abs(current.y - downPos.y)
                if dx > 6 || dy > 6 { return }
                // 点击位置若位于灵动岛区域内（如点击岛本身展开/操作岛内控件），不收起
                if self.state.pointerOverIsland {
                    // 收起态点击岛区域（窗口可能被系统菜单栏遮挡收不到点击）→ 经全局监听展开
                    if !self.state.isExpanded {
                        self.state.withExpanded(true)
                    }
                    return
                }
                self.state.withExpanded(false)
            }
            self.pendingCollapse?.cancel()
            self.pendingCollapse = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if event.keyCode == 53 {
                // 提醒未确认时不允许用 Esc 收起
                if !self.state.showReminder {
                    self.state.withExpanded(false)
                }
            } else if self.state.isExpanded, !self.state.showReminder {
                // 左右方向键快速切换页面（首页/末页回绕）
                if event.keyCode == 123 {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.66)) {
                        self.state.currentPage = self.state.currentPage > 0
                            ? self.state.currentPage - 1
                            : self.state.visiblePageCount - 1
                    }
                    self.state.resetAutoCollapseTimer()
                } else if event.keyCode == 124 {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.66)) {
                        self.state.currentPage = self.state.currentPage < self.state.visiblePageCount - 1
                            ? self.state.currentPage + 1
                            : 0
                    }
                    self.state.resetAutoCollapseTimer()
                }
            }
            return event
        }
        // 两指横扫切换页面（trackpad scrollWheel 水平分量）
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollWheel(event)
            return event
        }
        // 灵动岛右键菜单（含 Command+Q 退出；LSUIElement 应用无 Dock 图标，菜单栏菜单不易发现）
        islandRightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self = self, let contentView = self.window.contentView else { return event }
            // 点击点位于灵动岛窗口内才响应
            if self.window.frame.contains(NSEvent.mouseLocation) {
                NSMenu.popUpContextMenu(self.buildIslandMenu(), with: event, for: contentView)
                return nil
            }
            return event
        }
    }

    private func handleScrollWheel(_ event: NSEvent) {
        if state.isExpanded {
            handleTwoFingerSwipe(event)
        }
    }

    private func handleTwoFingerSwipe(_ event: NSEvent) {
        guard state.isExpanded, !state.showReminder else { return }

        // 惯性滚动阶段一律忽略（部分系统惯性事件的 phase 为空，必须先拦截），
        // 防止同一次快速滑动松手后的滑行继续累积而多翻页
        if event.momentumPhase != [] { return }

        // 触控板滑动手势（带 phase）：一次滑动只切换一页
        if event.phase != [] {
            switch event.phase {
            case .began:
                scrollAccumulator = 0
                swipeHandled = false
            case .ended, .cancelled:
                scrollAccumulator = 0
                return
            default:
                break
            }
            // 本手势已经切过页，忽略剩余输入
            if swipeHandled { return }
        } else {
            // 鼠标滚轮（无 phase）：沿用冷却时间，防止快速连翻
            guard Date().timeIntervalSince(lastPageSwitch) > 0.55 else { return }
        }

        let deltaX = event.scrollingDeltaX
        let deltaY = event.scrollingDeltaY
        // 仅响应水平占主导的两指滑动，过滤微小抖动
        guard abs(deltaX) > 4, abs(deltaX) > abs(deltaY) * 1.8 else { return }

        let now = Date()
        if now.timeIntervalSince(lastScrollTime) > 0.45 { scrollAccumulator = 0 }
        scrollAccumulator += deltaX
        lastScrollTime = now

        // 防止累积值过大导致连续翻页
        scrollAccumulator = max(-100, min(100, scrollAccumulator))

        let threshold: CGFloat = 48
        if scrollAccumulator > threshold {
            // 向右滑：上一页；首页时回绕到最后一页
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                state.currentPage = state.currentPage > 0 ? state.currentPage - 1 : state.visiblePageCount - 1
            }
            scrollAccumulator = 0
            swipeHandled = true
            lastPageSwitch = now
            state.resetAutoCollapseTimer()
        } else if scrollAccumulator < -threshold {
            // 向左滑：下一页；末页时回绕到首页
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                state.currentPage = state.currentPage < state.visiblePageCount - 1 ? state.currentPage + 1 : 0
            }
            scrollAccumulator = 0
            swipeHandled = true
            lastPageSwitch = now
            state.resetAutoCollapseTimer()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            btn.toolTip = "IsleX 灵屿" // HIG：菜单栏图标需提供提示
            // 菜单栏图标与应用图标保持一致（彩色 app 图标，非模板图）
            if let appIcon = NSImage(named: "AppIcon") {
                appIcon.size = NSSize(width: 18, height: 18)
                btn.image = appIcon
                btn.image?.isTemplate = false
            } else if #available(macOS 11.0, *) {
                btn.image = NSImage(systemSymbolName: "infinity", accessibilityDescription: "IsleX 灵屿")
                btn.image?.isTemplate = true
            } else {
                btn.image = NSImage(named: "NSActionTemplate")
            }
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "IsleX 灵屿", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "展开 / 收起", action: #selector(toggleExpand), keyEquivalent: "o")
        menu.addItem(.separator())

        // 所有设置集中于此：打开独立设置窗口（不占用灵动岛本体页面）
        let settingsItem = NSMenuItem(title: "设置", action: nil, keyEquivalent: "")
        let settingsMenu = NSMenu()
        settingsMenu.addItem(makeSettingsItem("外观", tab: 0))
        settingsMenu.addItem(makeSettingsItem("系统", tab: 1))
        settingsMenu.addItem(makeSettingsItem("跑马灯", tab: 2))
        settingsMenu.addItem(makeSettingsItem("小组件", tab: 3))
        settingsItem.submenu = settingsMenu
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        let launchItem = NSMenuItem(title: "开机自启动", action: #selector(toggleLaunchAtLogin), keyEquivalent: "s")
        launchItem.target = self
        launchItem.state = state.launchAtLogin ? .on : .off
        menu.addItem(launchItem)

        let websiteItem = NSMenuItem(title: "在 islex.netlify.app 下载 Pro 版", action: #selector(openWebsite), keyEquivalent: "w")
        websiteItem.target = self
        menu.addItem(websiteItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 IsleX 灵屿", action: #selector(quit), keyEquivalent: "q")
        statusItem.menu = menu
    }

    private func makeSettingsItem(_ title: String, tab: Int) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(openSettingsWindow(_:)), keyEquivalent: "")
        item.target = self
        item.tag = tab
        return item
    }

    @objc private func openSettingsWindow(_ sender: NSMenuItem) {
        state.openSettings(tab: sender.tag)
    }

    @objc private func toggleExpand() { state.withExpanded(!state.isExpanded) }

    /// 灵动岛右键菜单（含 Command+Q 退出）
    private func buildIslandMenu() -> NSMenu {
        let menu = NSMenu()
        let titleItem = NSMenuItem(title: "IsleX 灵屿", action: nil, keyEquivalent: "")
        menu.addItem(titleItem)
        menu.addItem(.separator())
        let expand = NSMenuItem(title: state.isExpanded ? "收起" : "展开 / 收起", action: #selector(toggleExpand), keyEquivalent: "o")
        expand.target = self
        menu.addItem(expand)
        let settingsItem = NSMenuItem(title: "设置", action: nil, keyEquivalent: "")
        let settingsMenu = NSMenu()
        settingsMenu.addItem(makeSettingsItem("外观", tab: 0))
        settingsMenu.addItem(makeSettingsItem("系统", tab: 1))
        settingsMenu.addItem(makeSettingsItem("跑马灯", tab: 2))
        settingsMenu.addItem(makeSettingsItem("小组件", tab: 3))
        settingsItem.submenu = settingsMenu
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let launchItem = NSMenuItem(title: "开机自启动", action: #selector(toggleLaunchAtLogin), keyEquivalent: "s")
        launchItem.target = self
        launchItem.state = state.launchAtLogin ? .on : .off
        menu.addItem(launchItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出 IsleX 灵屿", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }

    @objc private func toggleLaunchAtLogin() {
        state.toggleLaunchAtLogin()
        if let menu = statusItem.menu {
            for item in menu.items where item.action == #selector(toggleLaunchAtLogin as () -> Void) {
                item.state = state.launchAtLogin ? .on : .off
            }
        }
    }
    @objc private func quit() { NSApp.terminate(nil) }

    /// 打开官网（下载 Pro 完整版）
    @objc private func openWebsite() {
        guard let url = URL(string: "https://islex.netlify.app") else { return }
        NSWorkspace.shared.open(url)
    }

    deinit {
        if let m = globalMouseMonitor { NSEvent.removeMonitor(m) }
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        if let m = scrollMonitor { NSEvent.removeMonitor(m) }
    }
}

