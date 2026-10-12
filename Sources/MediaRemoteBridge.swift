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
// macOS 26+ 上 MediaRemote 已失效（dlopen 成功但查询为空）；NOSMTC 构建不编译这些函数。
#if !NOSMTC
private var _mediaRemoteLoaded = false
private var _mediaRemoteHandle: UnsafeMutableRawPointer?
private var _registerNotifications: ((DispatchQueue) -> Void)?
private var _getNowPlayingInfo: ((DispatchQueue, @escaping (NSDictionary) -> Void) -> Void)?
private var _getPlaying: ((DispatchQueue, @escaping (Bool) -> Void) -> Void)?
private var _sendCommand: ((Int32, NSDictionary?) -> Void)?
private var _setElapsedTime: ((Double) -> Void)?

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

// MARK: - 音量键拦截器（屏蔽系统音量 HUD，改由灵动岛显示）

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
    private(set) var interceptCount = 0
    private(set) var receivedEvents = 0

    private init() {}

    var hasPermission: Bool { AXIsProcessTrusted() }

    var isInstalled: Bool { tap != nil }

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

    private func scheduleRetry() {
        retryWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.active else { return }
            if self.tap == nil { self.install() }
        }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }

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
                    let fine = nsEvent.modifierFlags.contains(.option)
                    DispatchQueue.main.async {
                        AppState.shared.handleVolumeKey(keyCode, fine: fine)
                        AppState.shared.refreshVolumeSuppressStatus()
                    }
                }
                return nil // 吞掉事件：系统不显示 HUD、不调节音量
            }
            if isKeyboardLightKey {
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
