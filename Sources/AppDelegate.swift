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

// MARK: - 内容视图（点击穿透 + 拖放支持）

/// borderless 窗口默认不能成为 key window，会导致输入控件拿不到键盘焦点。
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
        Updater.checkIfNeeded()
        startupLog("OTA 更新检查已启动")
    }

    // 每 30 秒在主线程写一行，用来看"未响应"是主线程卡死还是渲染压力。
    private func startRuntimeHeartbeat() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            startupLog("心跳正常：运行中")
        }
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

    private func startSuppressStatusPolling() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state.volumeKeySuppressEnabled else { return }
            self.state.refreshVolumeSuppressStatus()
        }
    }

    private func showPermissionGuideIfNeeded() {
        let hasAccessibility = AXIsProcessTrusted()
        guard !hasAccessibility else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            let alert = NSAlert()
            alert.messageText = "灵屿需要系统权限"
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
        window.animationBehavior = .none
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

    func repositionIsland() {
        positionWindow(animated: false)
    }

    func repositionIslandForExpandCollapse() {
        positionWindow(animated: true, duration: 0.52)
    }

    private func setupMonitors() {
        // 全局监控器不支持 leftMouseDragged，用"按下后检测移动"判断是否在拖放。
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard let self = self else { return }
            if self.state.isDragTargeted { return }
            let downPos = NSEvent.mouseLocation
            let work = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.state.isDragTargeted { return }
                let current = NSEvent.mouseLocation
                let dx = abs(current.x - downPos.x)
                let dy = abs(current.y - downPos.y)
                if dx > 6 || dy > 6 { return }
                if self.state.pointerOverIsland {
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
                if !self.state.showReminder {
                    self.state.withExpanded(false)
                }
            } else if self.state.isExpanded, !self.state.showReminder {
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
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollWheel(event)
            return event
        }
        islandRightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self = self, let contentView = self.window.contentView else { return event }
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

        if event.momentumPhase != [] { return }

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
            if swipeHandled { return }
        } else {
            guard Date().timeIntervalSince(lastPageSwitch) > 0.55 else { return }
        }

        let deltaX = event.scrollingDeltaX
        let deltaY = event.scrollingDeltaY
        guard abs(deltaX) > 4, abs(deltaX) > abs(deltaY) * 1.8 else { return }

        let now = Date()
        if now.timeIntervalSince(lastScrollTime) > 0.45 { scrollAccumulator = 0 }
        scrollAccumulator += deltaX
        lastScrollTime = now

        scrollAccumulator = max(-100, min(100, scrollAccumulator))

        let threshold: CGFloat = 48
        if scrollAccumulator > threshold {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                state.currentPage = state.currentPage > 0 ? state.currentPage - 1 : state.visiblePageCount - 1
            }
            scrollAccumulator = 0
            swipeHandled = true
            lastPageSwitch = now
            state.resetAutoCollapseTimer()
        } else if scrollAccumulator < -threshold {
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
            btn.toolTip = "IsleX 灵屿"
            if let appIcon = NSImage(named: "AppIcon") {
                appIcon.size = NSSize(width: 18, height: 18)
                btn.image = appIcon
                btn.image?.isTemplate = false
            } else {
                btn.image = NSImage(systemSymbolName: "infinity", accessibilityDescription: "IsleX 灵屿")
                btn.image?.isTemplate = true
            }
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "IsleX 灵屿", action: nil, keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "展开 / 收起", action: #selector(toggleExpand), keyEquivalent: "o")
        menu.addItem(.separator())

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

        let websiteItem = NSMenuItem(title: "项目主页", action: #selector(openWebsite), keyEquivalent: "w")
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

    @objc private func openWebsite() {
        guard let url = URL(string: "https://github.com/DongWK-CHN/IsleX") else { return }
        NSWorkspace.shared.open(url)
    }

    deinit {
        if let m = globalMouseMonitor { NSEvent.removeMonitor(m) }
        if let m = keyMonitor { NSEvent.removeMonitor(m) }
        if let m = scrollMonitor { NSEvent.removeMonitor(m) }
    }
}
