//  IsleX 灵屿 —— MediaRemote 私有框架桥接 + 音量键拦截
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

#if !APPSTORE
// MARK: - MediaRemote 私有框架

enum MRCommand {
    static let play: Int32 = 0
    static let pause: Int32 = 1
    static let togglePlayPause: Int32 = 2
    static let nextTrack: Int32 = 4
    static let previousTrack: Int32 = 5
}

let kInfoDidChange = "kMRMediaRemoteNowPlayingInfoDidChangeNotification"
let kAppDidChange = "kMRMediaRemoteNowPlayingApplicationDidChangeNotification"
let kPlayingDidChange = "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"

let kTitle = "kMRMediaRemoteNowPlayingInfoTitle"
let kArtist = "kMRMediaRemoteNowPlayingInfoArtist"
let kAlbum = "kMRMediaRemoteNowPlayingInfoAlbum"
let kDuration = "kMRMediaRemoteNowPlayingInfoDuration"
let kElapsed = "kMRMediaRemoteNowPlayingInfoElapsedTime"
let kRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"
let kArtwork = "kMRMediaRemoteNowPlayingInfoArtworkData"

// MARK: - MediaRemote 私有框架函数指针（惰性加载，避免模块初始化时执行）
// 在 macOS 26+ 上 MediaRemote 私有框架已失效（dlopen 成功但查询恒为空），
// 无 SMTC 构建（NOSMTC，macOS 26.5+）直接不编译这些函数，杜绝死代码与崩溃风险。
#if !NOSMTC
private var _mediaRemoteLoaded = false
private var _mediaRemoteHandle: UnsafeMutableRawPointer?
private var _registerNotifications: ((DispatchQueue) -> Void)?
private var _getNowPlayingInfo: ((DispatchQueue, @escaping (NSDictionary) -> Void) -> Void)?
private var _getPlaying: ((DispatchQueue, @escaping (Bool) -> Void) -> Void)?
private var _sendCommand: ((Int32, NSDictionary?) -> Void)?
private var _setElapsedTime: ((Double) -> Void)?

// C 函数指针类型（与 Swift 闭包大小不同，需先转为 @convention(c) 再包装）
private typealias CRegisterNotifications = @convention(c) (DispatchQueue) -> Void
private typealias CGetNowPlayingInfo = @convention(c) (DispatchQueue, @escaping (NSDictionary) -> Void) -> Void
private typealias CGetPlaying = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
private typealias CSendCommand = @convention(c) (Int32, NSDictionary?) -> Void
private typealias CSetElapsedTime = @convention(c) (Double) -> Void

private func ensureMediaRemoteLoaded() {
    guard !_mediaRemoteLoaded else { return }
    _mediaRemoteLoaded = true
    guard let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW) else { return }
    _mediaRemoteHandle = handle
    if let sym = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications") {
        let fn = unsafeBitCast(sym, to: CRegisterNotifications.self)
        _registerNotifications = { fn($0) }
    }
    if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
        let fn = unsafeBitCast(sym, to: CGetNowPlayingInfo.self)
        _getNowPlayingInfo = { fn($0, $1) }
    }
    if let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
        let fn = unsafeBitCast(sym, to: CGetPlaying.self)
        _getPlaying = { fn($0, $1) }
    }
    if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
        let fn = unsafeBitCast(sym, to: CSendCommand.self)
        _sendCommand = { fn($0, $1) }
    }
    if let sym = dlsym(handle, "MRMediaRemoteSetElapsedTime") {
        let fn = unsafeBitCast(sym, to: CSetElapsedTime.self)
        _setElapsedTime = { fn($0) }
    }
}

// MARK: - 安全调用包装（框架不可用时静默跳过）
func MRMediaRemoteIsAvailable() -> Bool {
    ensureMediaRemoteLoaded()
    return _mediaRemoteHandle != nil
}
#endif // !NOSMTC
#endif

#if !APPSTORE
// MARK: - 音量键拦截器（屏蔽系统音量 HUD，改由灵动岛显示）

/// NX 系统按键类型（NSEvent.data1 解码，音量键为 systemDefined 事件）
enum NXKeyType {
    static let soundUp: Int = 0
    static let soundDown: Int = 1
    static let mute: Int = 7
    static let brightnessUp: Int = 2
    static let brightnessDown: Int = 3
    static let keyboardIllumUp: Int = 10
    static let keyboardIllumDown: Int = 11
    static let keyboardIllumToggle: Int = 12
}

final class VolumeKeyInterceptor {
    static let shared = VolumeKeyInterceptor()
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var active = false
    private var healthTimer: Timer?
    private var retryWork: DispatchWorkItem?
    /// 已拦截的音量键次数（供设置页诊断：按音量键看计数是否增加）
    private(set) var interceptCount = 0
    /// tap 收到的所有系统按键事件数（含非音量键，用于诊断 tap 是否静默失效）
    private(set) var receivedEvents = 0

    private init() {}

    /// 辅助功能权限是否已授予（defaultTap 拦截必需）
    var hasPermission: Bool { AXIsProcessTrusted() }

    /// 是否已成功创建 tap
    var isInstalled: Bool { tap != nil }

    /// tap 当前是否处于启用状态
    var isEnabled: Bool {
        guard let tap = tap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }

    func start() {
        guard !active else { return }
        active = true
        install()
        startHealthTimer()
    }

    func stop() {
        active = false
        retryWork?.cancel()
        retryWork = nil
        healthTimer?.invalidate()
        healthTimer = nil
        remove()
    }

    private func install() {
        remove()
        guard active else { return }
        // 检查辅助功能权限，未授权时弹系统对话框提示用户授权
        if !AXIsProcessTrusted() {
            let opts: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(opts)
        }
        guard let port = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1) << 14, // NX_SYSDEFINED（音量/亮度/媒体键）
            callback: { _, type, event, _ in
                VolumeKeyInterceptor.handle(type: type, event: event)
            },
            userInfo: nil
        ) else {
            // 创建失败（通常为辅助功能未授权）：自动重试，授权后无需重启应用
            startupLog("音量键拦截器安装失败：AXTrusted=\(AXIsProcessTrusted())，1s 后自动重试")
            scheduleRetry()
            notifyStatusChange()
            return
        }
        tap = port
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        if let src = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        }
        CGEvent.tapEnable(tap: port, enable: true)
        startupLog("音量/亮度/键盘亮度键拦截器已安装")
        notifyStatusChange()
    }

    /// 授权后自动安装：每 1 秒重试一次（tap 为空时）
    private func scheduleRetry() {
        retryWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.active else { return }
            if self.tap == nil { self.install() }
        }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

    /// 定时健康检查：tap 被系统禁用时恢复；tap 丢失时重装
    private func startHealthTimer() {
        healthTimer?.invalidate()
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.healthCheck()
        }
        RunLoop.main.add(timer, forMode: .common)
        healthTimer = timer
    }

    private func healthCheck() {
        guard active else { return }
        if let tap = tap {
            if !CGEvent.tapIsEnabled(tap: tap) {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        } else {
            install()
        }
        notifyStatusChange()
    }

    private func remove() {
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        tap = nil
        runLoopSource = nil
    }

    private func notifyStatusChange() {
        DispatchQueue.main.async {
            AppState.shared.refreshVolumeSuppressStatus()
        }
    }

    private static func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // tap 被系统超时/用户操作禁用：立即恢复
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port = shared.tap {
                CGEvent.tapEnable(tap: port, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        // 通道：NX_SYSDEFINED（音量/亮度/媒体键标准事件，Tahoe 亦适用）
        if type == CGEventType(rawValue: 14) {
            shared.receivedEvents += 1
            guard let nsEvent = NSEvent(cgEvent: event) else { return Unmanaged.passUnretained(event) }
            let data1 = nsEvent.data1
            let keyCode = Int((data1 & 0xFFFF0000) >> 16)
            let keyState = Int((data1 & 0x0000FF00) >> 8) // 0xA 按下，0xB 抬起
            // 诊断：收到未识别键码时记录（正常只应出现音量/亮度/键盘亮度 0,1,2,3,7,10,11,12）
            if keyState == 0xA,
               ![NXKeyType.soundUp, NXKeyType.soundDown, NXKeyType.mute,
                 NXKeyType.brightnessUp, NXKeyType.brightnessDown,
                 NXKeyType.keyboardIllumUp, NXKeyType.keyboardIllumDown, NXKeyType.keyboardIllumToggle]
                   .contains(keyCode) {
                startupLog("音量/亮度键诊断：未识别媒体键码 keyCode=\(keyCode) data1=\(data1)")
            }
            let isVolumeKey = keyCode == NXKeyType.soundUp
                || keyCode == NXKeyType.soundDown
                || keyCode == NXKeyType.mute
            let isKeyboardLightKey = keyCode == NXKeyType.keyboardIllumUp
                || keyCode == NXKeyType.keyboardIllumDown
                || keyCode == NXKeyType.keyboardIllumToggle
            if isVolumeKey {
                if keyState == 0xA {
                    shared.interceptCount += 1
                    // Option+音量键 = 微调（1/4 步进，与系统行为一致）
                    let fine = nsEvent.modifierFlags.contains(.option)
                    DispatchQueue.main.async {
                        AppState.shared.handleVolumeKey(keyCode, fine: fine)
                        AppState.shared.refreshVolumeSuppressStatus()
                    }
                }
                return nil // 吞掉事件：系统不显示 HUD、不调节音量
            }
            // 亮度键（2/3）不再处理：调节与系统 HUD 由系统底层直接执行，第三方无法接管，原样放行
            if isKeyboardLightKey {
                // 键盘背光无公开 API 读值：放行系统原生调节，灵动岛同步显示提示
                if keyState == 0xA {
                    DispatchQueue.main.async {
                        AppState.shared.handleKeyboardLightKey(keyCode)
                    }
                }
                return Unmanaged.passUnretained(event)
            }
            return Unmanaged.passUnretained(event)
        }
        return Unmanaged.passUnretained(event)
    }
}
#endif

/// 全局字体缩放：基础字号 × (外观字体大小/13)，供所有 .system(size:) 调用使用
