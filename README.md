# IsleX 灵屿

> 把 macOS 的刘海，变成一个真正能干活的「灵动岛」。

[English](README.en.md) | **简体中文**

IsleX 灵屿 是一款 macOS 桌面灵动岛（刘海）增强工具。它在屏幕顶部的刘海处叠加一个无边框、透明、可点击穿透的浮层窗口，展开后即可在同一处完成媒体控制、歌词、番茄钟、文件中转、快捷启动、格式转换、硬件状态、待办、天气、提词等操作，无需切换窗口。

应用采用 `LSUIElement`（无 Dock 图标）形态，通过菜单栏图标和岛体右键菜单进行操作。

- 官网 / 下载：<https://islex.netlify.app>

## 功能一览

岛内共 10 个功能页，可在设置中自定义顺序与开关：

| 页面 | 说明 |
| --- | --- |
| 仪表盘 | 实时时钟、日历与快捷控制 |
| 媒体 | 播放状态、进度、封面、歌词与控制 |
| 番茄钟 | 专注 / 短休 / 长休，含当日统计 |
| 文件中转站 | 拖放暂存文件 |
| 应用启动 | 手动网格、预设应用与自定义链接 |
| 格式转换 | 图片 / 音频 / 文本编码转换 |
| 硬件状态 | CPU 温度、负载、内存、电池，并监控 AI 编码工具运行态 |
| 待办 | 优先级与完成状态管理 |
| 天气 | 基于 Open-Meteo（免费、无需 Key） |
| 提词器 | 文本滚动 + 速度 / 字号 / 镜像 + 文档库 |

外观方面支持贴合刘海 / 悬浮胶囊两种形态、尺寸与缩放、圆角、极光质感、自定义背景与动态边框主题，并提供独立的设置窗口（外观 / 系统 / 跑马灯 / 小组件四个分页）。

## 媒体来源

媒体控制采用「多源并行 + 仲裁」架构，按可用性自动回退：

- **网易云音乐** —— Chrome DevTools Protocol 直连，读取 DOM 并注入控制
- **QQ 音乐** —— 解析 `PlayingList.archive` 的当前队列索引，事件驱动
- **酷狗音乐** —— 解析 `userCurrentPlayList.plist` 与 `.klog` 日志
- **AppleScript 通道** —— Apple Music、Spotify、QuickTime Player、Apple TV
- **MediaRemote 私有框架** —— 通过内联辅助进程读取 NowPlaying（非沙盒版）
- **兜底** —— 无脚本接口时模拟系统媒体键

歌词取自网易云接口（含模糊匹配与 LRC 解析）。

## 技术栈

- **语言 / UI**：Swift + SwiftUI（`ObservableObject` / `@Published`）+ AppKit（`NSWindow` / `NSHostingView` / `NSPanel`）
- **状态管理**：Combine，全局单例 `AppState.shared`
- **系统框架**：CoreAudio、IOKit、ServiceManagement、ApplicationServices、ImageIO、UniformTypeIdentifiers、Foundation
- **私有框架**：MediaRemote（`dlopen` 动态加载，仅非沙盒版）
- **第三方依赖**：无。纯系统框架自研实现，无 SPM / CocoaPods

## 构建变体

仓库不含 Xcode 工程文件，构建变体通过条件编译宏区分：

| 宏 | 含义 |
| --- | --- |
| `APPSTORE` | App Store 沙盒「Lite」版：禁用 MediaRemote、CDP 直连、`afconvert` 转码、`ps` 进程监控等，改用 `NSWorkspace`、原生编码转换等替代方案 |
| `NOSMTC` | 无 SMTC 构建（macOS 26.5+ 使用）：MediaRemote 对第三方失效时改走 AppleScript + CDP + plist / archive 通道 |
| `PERF` | 性能实测探针，仅在 `-D PERF` 编译时存在 |

**系统要求**：macOS 10.15 (Catalina) 及以上（含专门兼容层），并前瞻适配 macOS 26 Tahoe。

## 权限说明

部分功能需要系统权限，所有数据仅在本机使用，不会上传：

- **辅助功能**：全局点击检测、键盘快捷操作、音量键提示
- **完全磁盘访问**：读取 QQ 音乐 / 酷狗音乐容器内的播放数据
- 首次运行会弹出权限引导；读取容器失败时也会提示前往开启

## 目录结构

源码按模块拆分（原为单一 `main.swift`，现拆分生成，文件头注释提示勿手动调整导入）：

| 文件 | 职责 |
| --- | --- |
| `main.swift` | 程序入口 |
| `AppDelegate.swift` | 窗口、菜单栏、全局事件与权限引导 |
| `AppState.swift` | 全局状态（媒体 / 番茄钟 / 文件 / 设置等） |
| `Models.swift` | 数据模型与刘海几何 |
| `RootViews.swift` | 根视图、时钟组件、岛形状、收起 / 展开态 |
| `PageLayouts.swift` | 每页布局自定义 |
| `PagesDashboardMedia.swift` | 仪表盘 / 媒体 / 歌词 / 番茄钟 |
| `PagesFilesSystem.swift` | 文件中转站 / 快捷应用 / 系统 |
| `PagesToolsStatus.swift` | 格式转换器 / 状态 / AI 工具监控 |
| `PagesWeather.swift` | 天气 |
| `PagesTeleprompter.swift` | 提词器 |
| `PagesCustomize.swift` | 跑马灯 / 外观 / 小组件管理 |
| `SettingsWindow.swift` | 独立设置窗口 |
| `CommonComponents.swift` | 通用组件 |
| `Compat.swift` | 兼容层与工具扩展 |
| `MediaRemoteBridge.swift` | MediaRemote 私有框架桥接 + 音量键拦截 |
| `NeteaseCDP.swift` | 网易云音乐 CDP 直连 |
| `QQMusicArchivePoller.swift` | QQ 音乐 archive 直连 |
| `KuGouPlist.swift` | 酷狗音乐 plist 直连 |
| `Updater.swift` | OTA 更新检查 |

## 说明

- 媒体控制、歌词等完整体验需使用完整版（Pro）；App Store 沙盒版为精简的 Lite 版。
- 本仓库当前仅包含源码文件，不含 Xcode 工程；请通过官网获取正式发行版本。
