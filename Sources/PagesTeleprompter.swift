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

// MARK: - 提词器页面

struct TeleprompterPageView: View {
    @ObservedObject var state: AppState
    @State private var isPlaying = false
    @State private var offset: CGFloat = 0
    @State private var timer: Timer?
    @State private var contentHeight: CGFloat = 0
    @State private var containerHeight: CGFloat = 0
    @State private var editing = false
    @State private var showingDocs = false
    @State private var hintText = ""
    @State private var hintWork: DispatchWorkItem?

    private var maxOffset: CGFloat { max(0, contentHeight - containerHeight) }
    private var progress: CGFloat { maxOffset > 0 ? min(max(offset / maxOffset, 0), 1) : 0 }

    var body: some View {
        VStack(spacing: 6) {
            header
            if showingDocs {
                docList
            } else if editing {
                editor
            } else {
                scrollArea
            }
            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            stop()
            hintWork?.cancel()
            hintText = ""
        }
    }

    // MARK: 头部：标题 + 文档 + 编辑 + 重置 + 播放
    private var header: some View {
        HStack(spacing: 8) {
            sysImage("character.cursor.ibeam")
                .font(.system(size: tfs(10)))
                .foregroundColor(.white.opacity(0.5))
            Text("提词器")
                .font(.system(size: tfs(10), weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            Button {
                showingDocs.toggle()
                if showingDocs { editing = false; stop() }
            } label: {
                HStack(spacing: 3) {
                    sysImage("folder.fill")
                        .font(.system(size: tfs(9)))
                    if !state.tpDocuments.isEmpty {
                        Text("\(state.tpDocuments.count)")
                            .font(.system(size: tfs(8), weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .foregroundColor(showingDocs ? .cyan : .white.opacity(0.6))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(showingDocs ? 0.14 : 0.06)))
            }
            .buttonStyle(PressBtn())
            if showingDocs {
                Button {
                    state.importTeleprompterDoc()
                } label: {
                    HStack(spacing: 3) {
                        sysImage("arrow.down.doc").font(.system(size: tfs(9)))
                        Text("导入").font(.system(size: tfs(8.5), weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(PressBtn())
            } else {
                Button { editing = true; stop(); reset() } label: {
                    sysImage("square.and.pencil")
                        .font(.system(size: tfs(11)))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(PressBtn())
                Button { reset() } label: {
                    sysImage("arrow.counterclockwise")
                        .font(.system(size: tfs(11)))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(PressBtn())
                Button {
                    if isPlaying { stop() } else { start() }
                } label: {
                    sysImage(isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: tfs(20)))
                        .foregroundColor(isPlaying ? .yellow : .green)
                        .shadow(color: isPlaying ? .yellow.opacity(0.4) : .green.opacity(0.4), radius: 4)
                }
                .buttonStyle(PressBtn())
            }
        }
    }

    // MARK: 文档库
    private var docList: some View {
        Group {
            if state.tpDocuments.isEmpty {
                VStack(spacing: 8) {
                    sysImage("doc.text")
                        .font(.system(size: tfs(24)))
                        .foregroundColor(.white.opacity(0.3))
                    Text("暂无文档\n点击右上角「导入」上传讲稿\n（支持 txt / md / rtf / docx）")
                        .font(.system(size: tfs(9)))
                        .foregroundColor(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                    Button { state.importTeleprompterDoc() } label: {
                        Text("上传文档").font(.system(size: tfs(9), weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PressBtn())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 5) {
                        ForEach(state.tpDocuments) { doc in
                            HStack(spacing: 6) {
                                sysImage("doc.text.fill")
                                    .font(.system(size: tfs(10)))
                                    .foregroundColor(.white.opacity(0.45))
                                Text(doc.name)
                                    .font(.system(size: tfs(9), weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button {
                                    state.openTeleprompterDoc(doc)
                                    showingDocs = false
                                    reset()
                                } label: {
                                    sysImage("text.cursor")
                                        .font(.system(size: tfs(10)))
                                        .foregroundColor(.cyan)
                                }
                                .buttonStyle(PressBtn())
                                Button {
                                    state.deleteTeleprompterDoc(doc)
                                } label: {
                                    sysImage("trash")
                                        .font(.system(size: tfs(9)))
                                        .foregroundColor(.red.opacity(0.75))
                                }
                                .buttonStyle(PressBtn())
                            }
                            .padding(.horizontal, 8).padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: rr(8)).fill(Color.white.opacity(0.06)))
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: 编辑区（讲稿输入）
    private var editor: some View {
        TextEditor(text: $state.tpText)
            .font(.system(size: 13))
            .foregroundColor(.white)
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: rr(10))
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: rr(10))
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.horizontal, 2)
    }

    // MARK: 滚动区
    private var scrollArea: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Text(state.tpText.isEmpty ? "（点击右上角编辑输入讲稿）" : state.tpText)
                    .font(.system(size: state.tpFontSize, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineSpacing(state.tpFontSize * 0.42)
                    .frame(width: geo.size.width - 20, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        GeometryReader { tgeo in
                            // preference 偶尔收不到，onAppear/onChange 再兜一次，避免高度恒为 0。
                            Color.clear
                                .preference(key: TpHeightKey.self, value: tgeo.size.height)
                                .onAppear { contentHeight = tgeo.size.height }
                                .onValueChange(of: tgeo.size.height) { contentHeight = $0 }
                        }
                    )
                    .offset(y: -offset)
                    .scaleEffect(x: state.tpMirror ? -1 : 1, y: 1)
                    .animation(.easeInOut(duration: 0.25), value: state.tpMirror)
                    .animation(.easeInOut(duration: 0.25), value: state.tpFontSize)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .clipped()
            .background(
                RoundedRectangle(cornerRadius: rr(10))
                    .fill(Color.black.opacity(0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: rr(10))
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            )
            .overlay(alignment: .trailing) {
                if maxOffset > 1 {
                    VStack {
                        Spacer(minLength: 0)
                        Capsule()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 2.5, height: max(4, geo.size.height * 0.85 * progress))
                            .shadow(color: .white.opacity(0.5), radius: 2)
                            .animation(.linear(duration: 0.1), value: progress)
                        Spacer(minLength: 0)
                    }
                    .frame(height: geo.size.height)
                    .padding(.trailing, 4)
                    .allowsHitTesting(false)
                }
            }
            .onAppear { containerHeight = geo.size.height }
            .onValueChange(of: geo.size.height) { containerHeight = $0 }
            .onPreferenceChange(TpHeightKey.self) { contentHeight = $0 }
            .onTapGesture {
                if isPlaying { stop() } else { start() }
            }
            .overlay {
                if !hintText.isEmpty {
                    Text(hintText)
                        .font(.system(size: tfs(9), weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color.black.opacity(0.55)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 控制栏：速度 / 字号 / 镜像
    private var controls: some View {
        HStack(spacing: 8) {
            sysImage("speedometer")
                .font(.system(size: tfs(10)))
                .foregroundColor(.white.opacity(0.5))
            Slider(value: $state.tpSpeed, in: 1...10, step: 1)
                .controlSize(.mini)
                .frame(width: 110)
            Text("\(Int(state.tpSpeed))")
                .font(.system(size: tfs(9), weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 14)
            Divider().frame(height: 12).overlay(Color.white.opacity(0.15))
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    state.tpFontSize = max(12, min(state.tpFontSize - 2, 44))
                }
            } label: {
                sysImage("textformat.size.smaller")
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(PressBtn())
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    state.tpFontSize = max(12, min(state.tpFontSize + 2, 44))
                }
            } label: {
                sysImage("textformat.size.larger")
                    .font(.system(size: tfs(10)))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(PressBtn())
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    state.tpMirror.toggle()
                }
            } label: {
                HStack(spacing: 3) {
                    sysImage(state.tpMirror ? "arrow.left.and.right.square.fill" : "arrow.left.and.right.square")
                        .font(.system(size: tfs(9)))
                    Text("镜像")
                        .font(.system(size: tfs(8.5), weight: .medium))
                }
                .foregroundColor(state.tpMirror ? .cyan : .white.opacity(0.45))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(state.tpMirror ? 0.14 : 0.06)))
            }
            .buttonStyle(PressBtn())
        }
        .padding(.horizontal, 2)
    }

    // MARK: 滚动控制
    private func start() {
        stop()
        guard !state.tpText.isEmpty else { return }
        guard maxOffset > 0.5 else {
            flashHint("内容不足一屏，无需滚动")
            return
        }
        isPlaying = true
        startupLog("提词器播放开始：contentH=\(Int(contentHeight)) containerH=\(Int(containerHeight)) offset=\(Int(offset))")
        let interval: TimeInterval = 1.0 / 60.0
        var last = Date()
        let t = Timer(timeInterval: interval, repeats: true) { _ in
            let now = Date()
            let dt = min(max(now.timeIntervalSince(last), 0), 0.1)
            last = now
            let limit = self.maxOffset
            guard limit > 0.5 else { return }
            let delta = CGFloat(self.state.tpSpeed) * 14.0 * CGFloat(dt)
            let next = min(self.offset + delta, limit)
            if next >= limit {
                self.offset = limit
                self.stop()
                self.flashHint("已滚动到结尾")
                return
            }
            self.offset = next
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        if isPlaying { startupLog("提词器停止：offset=\(Int(offset)) max=\(Int(maxOffset))") }
        isPlaying = false
    }

    private func reset() {
        stop()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = 0
        }
    }

    private func flashHint(_ s: String) {
        hintWork?.cancel()
        withAnimation(.easeOut(duration: 0.15)) { hintText = s }
        let w = DispatchWorkItem { [self] in
            withAnimation(.easeIn(duration: 0.3)) { self.hintText = "" }
        }
        hintWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: w)
    }
}

private struct TpHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - 提词器文档库（上传 / 打开 / 删除）

struct TeleprompterDoc: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var filename: String
}

extension AppState {
    var teleprompterDocsDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("IsleX/teleprompter", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func loadTeleprompterDocList() {
        guard let data = UserDefaults.standard.data(forKey: "tpDocuments"),
              let docs = try? JSONDecoder().decode([TeleprompterDoc].self, from: data) else { return }
        let fm = FileManager.default
        tpDocuments = docs.filter {
            fm.fileExists(atPath: teleprompterDocsDir.appendingPathComponent($0.filename).path)
        }
    }

    private func saveTeleprompterDocList() {
        if let data = try? JSONEncoder().encode(tpDocuments) {
            UserDefaults.standard.set(data, forKey: "tpDocuments")
        }
    }

    func importTeleprompterDoc() {
        let panel = NSOpenPanel()
        panel.title = "导入讲稿文档"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedFileTypes = ["txt", "md", "markdown", "rtf", "rtfd", "docx"]
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }
        let fm = FileManager.default
        for url in panel.urls {
            let ext = url.pathExtension.lowercased()
            let content = ext == "docx" ? Self.readDocxText(url) : Self.readTextFile(url)
            guard !content.isEmpty else { continue }
            let filename = "\(UUID().uuidString).\(ext.isEmpty ? "txt" : ext)"
            let dest = teleprompterDocsDir.appendingPathComponent(filename)
            try? fm.copyItem(at: url, to: dest)
            let doc = TeleprompterDoc(
                id: UUID().uuidString,
                name: url.deletingPathExtension().lastPathComponent,
                filename: filename
            )
            tpDocuments.insert(doc, at: 0)
            tpText = content
        }
        saveTeleprompterDocList()
    }

    func openTeleprompterDoc(_ doc: TeleprompterDoc) {
        let url = teleprompterDocsDir.appendingPathComponent(doc.filename)
        let ext = doc.filename.lowercased().hasSuffix(".docx")
        let content = ext ? Self.readDocxText(url) : Self.readTextFile(url)
        if !content.isEmpty { tpText = content }
    }

    func deleteTeleprompterDoc(_ doc: TeleprompterDoc) {
        let url = teleprompterDocsDir.appendingPathComponent(doc.filename)
        try? FileManager.default.removeItem(at: url)
        tpDocuments.removeAll { $0.id == doc.id }
        saveTeleprompterDocList()
    }

    private static func readTextFile(_ url: URL) -> String {
        if let s = try? String(contentsOf: url, encoding: .utf8) { return s }
        if let s = try? String(contentsOf: url, encoding: .utf16) { return s }
        if let s = try? String(contentsOf: url, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) { return s }
        return ""
    }

    private static func readDocxText(_ url: URL) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/textutil")
        p.arguments = ["-convert", "txt", "-stdout", url.path]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        do { try p.run() } catch { return "" }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
