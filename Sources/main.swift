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

// MARK: - 入口

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
#if PERF
PerfProbe.install()
#endif
app.run()
