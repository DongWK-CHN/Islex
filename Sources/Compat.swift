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

func tfs(_ base: CGFloat) -> CGFloat {
    max(base, 8) * (AppState.shared.fontScale * 1.04)
}

func rr(_ base: CGFloat) -> CGFloat {
    base * AppState.shared.cornerRadiusMultiplier
}

let volumeChangeCallback: AudioObjectPropertyListenerProc = { _, _, _, _ in
    DispatchQueue.main.async { AppState.shared.onSystemVolumeChanged() }
    return noErr
}

// MARK: - 颜色扩展
extension Color {
    static let lgCyan = Color(red: 0.25, green: 0.85, blue: 0.95)
    static let lgMint = Color(red: 0.40, green: 0.90, blue: 0.75)
    static let lgTeal = Color(red: 0.20, green: 0.75, blue: 0.80)
    static let lgIndigo = Color(red: 0.42, green: 0.45, blue: 0.95)
}

// MARK: - 工具

func startupLog(_ msg: String) {
    let fm = FileManager.default
    guard let dir = fm.urls(for: .libraryDirectory, in: .userDomainMask).first?
        .appendingPathComponent("Logs/IsleX", isDirectory: true) else { return }
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent("startup.log")
    let line = "[\(Int(Date().timeIntervalSince1970 * 1000))] \(msg)\n"
    if let data = line.data(using: .utf8) {
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }
}

func sysImage(_ name: String) -> some View {
    Image(systemName: name)
}

extension View {
    func onValueChange<Value: Equatable>(of value: Value, perform action: @escaping (Value) -> Void) -> some View {
        onChange(of: value) { _, newValue in action(newValue) }
    }

    func helpAny(_ text: String) -> some View {
        help(text)
    }

    func fileDrop(targeted: Binding<Bool>, action: @escaping ([NSItemProvider]) -> Bool) -> some View {
        onDrop(of: [.fileURL], isTargeted: targeted) { action($0) }
    }
}
