//  IsleX 灵屿 —— 数据模型与刘海几何
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

// MARK: - 数据模型

struct NowPlayingInfo {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artwork: NSImage?
    var duration: Double = 0
    var elapsed: Double = 0
    var rate: Double = 0
    var isPlaying: Bool = false
    // 歌词
    var lyrics: [LyricLine] = []
    var currentLyricLine: Int {
        let elapsed = self.elapsed
        return lyrics.lastIndex { $0.time <= elapsed } ?? -1
    }
    var hasMedia: Bool { !title.isEmpty || rate > 0 || isPlaying }
}

struct LyricLine: Identifiable, Hashable {
    let id = UUID()
    let time: Double
    let text: String
}

enum LyricState {
    case idle
    case loading
    case loaded
    case notFound
}

struct AppShortcut: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let url: URL
    let iconImage: NSImage?
    let isWebLink: Bool
    let bundleId: String?   // 沙盒兼容：优先用 LaunchServices 按 bundle id 解析路径与图标
}

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let icon: NSImage?
    let size: Int64
    let dateAdded: Date
}

// MARK: - 待办事项

struct TodoItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var isDone = false
    var createdAt = Date()
    var priority: TodoPriority = .medium
}

enum TodoPriority: String, Codable, CaseIterable {
    case low = "低"
    case medium = "中"
    case high = "高"

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "exclamationmark.circle"
        }
    }
}

enum PomodoroPhase: String {
    case work = "专注"
    case shortBreak = "休息"
    case longBreak = "长休息"

    var duration: Int {
        switch self {
        case .work: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }

    var color: Color {
        switch self {
        case .work: return .orange
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    var icon: String {
        switch self {
        case .work: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak: return "leaf"
        }
    }
}

// MARK: - 刘海几何

struct NotchGeometry {
    let screenFrame: CGRect
    let notchWidth: CGFloat
    let notchHeight: CGFloat
    let notchCenterX: CGFloat
    let hasNotch: Bool

    /// 计算目标屏幕的刘海几何；screen 为 nil 时使用当前主屏（NSScreen.main）
    static func current(on screen: NSScreen? = nil) -> NotchGeometry {
        guard let sc = screen ?? NSScreen.main else {
            return NotchGeometry(screenFrame: .zero, notchWidth: 0, notchHeight: 24, notchCenterX: 0, hasNotch: false)
        }
        let f = sc.frame
        if #available(macOS 12.0, *),
           let l = sc.auxiliaryTopLeftArea, let r = sc.auxiliaryTopRightArea {
            let h = max(l.height, sc.safeAreaInsets.top)
            let minX = l.maxX
            let maxX = r.minX
            let w = max(maxX - minX, 0)
            return NotchGeometry(screenFrame: f, notchWidth: w, notchHeight: h,
                                 notchCenterX: (minX + maxX) / 2, hasNotch: w > 0)
        }
        return NotchGeometry(screenFrame: f, notchWidth: 0, notchHeight: 24, notchCenterX: f.midX, hasNotch: false)
    }
}

