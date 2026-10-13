# IsleX 灵屿

> Turn the macOS notch into a Dynamic Island that actually gets things done.

**English** | [简体中文](README.md)

IsleX 灵屿 is a macOS notch / Dynamic Island enhancement tool. It overlays a borderless, transparent, click-through floating window over the notch at the top of the screen. Once expanded, you can control media, read lyrics, run a Pomodoro timer, stage files, launch apps, convert formats, check hardware status, manage to-dos, view weather, and use a teleprompter — all in one place, without switching windows.

The app runs as an `LSUIElement` (no Dock icon) accessory app, operated through a menu bar item and the island's right-click menu.

- Website / Download: <https://islex.netlify.app>

## Features

The island contains 10 functional pages whose order and visibility are customizable in Settings:

| Page | Description |
| --- | --- |
| Dashboard | Live clock, calendar, and quick controls |
| Media | Playback state, progress, artwork, lyrics, and controls |
| Pomodoro | Focus / short break / long break, with daily statistics |
| File Station | Drag-and-drop file staging |
| App Launcher | Manual grid, preset apps, and custom links |
| Converter | Image / audio / text-encoding conversion |
| Hardware | CPU temperature, load, memory, battery, plus AI coding tool monitoring |
| To-Do | Priority and completion management |
| Weather | Powered by Open-Meteo (free, no API key) |
| Teleprompter | Scrolling text with speed / font-size / mirror plus a document library |

For appearance, IsleX supports both a notch-fitting and a floating-capsule shape, plus size/scale, corner radius, aurora texture, custom backgrounds, and dynamic border themes. A separate Settings window provides four tabs: Appearance, System, Marquee, and Widgets.

## Media Sources

Media control uses a "multi-source parallel + arbitration" architecture that falls back automatically based on availability:

- **Netease Cloud Music** — direct Chrome DevTools Protocol (CDP) connection; reads the DOM and injects controls
- **QQ Music** — parses the current queue index of `PlayingList.archive`, event-driven
- **KuGou Music** — parses `userCurrentPlayList.plist` and `.klog` logs
- **AppleScript channel** — Apple Music, Spotify, QuickTime Player, Apple TV
- **MediaRemote private framework** — reads NowPlaying via an inline helper process (non-sandboxed builds)
- **Fallback** — simulates system media keys when no scripting interface is available

Lyrics are fetched from the Netease API (with fuzzy matching and LRC parsing).

## Tech Stack

- **Language / UI**: Swift + SwiftUI (`ObservableObject` / `@Published`) + AppKit (`NSWindow` / `NSHostingView` / `NSPanel`)
- **State management**: Combine, with a global `AppState.shared` singleton
- **System frameworks**: CoreAudio, IOKit, ServiceManagement, ApplicationServices, ImageIO, UniformTypeIdentifiers, Foundation
- **Private frameworks**: MediaRemote (loaded dynamically via `dlopen`, non-sandboxed builds only)
- **Third-party dependencies**: none. Built entirely on system frameworks — no SPM, no CocoaPods

## Build Variants

The repository contains no Xcode project file; build variants are selected via conditional-compilation flags:

| Flag | Meaning |
| --- | --- |
| `APPSTORE` | App Store sandboxed "Lite" build: disables MediaRemote, direct CDP, `afconvert` transcoding, `ps` process monitoring, etc., replacing them with `NSWorkspace`, native encoding conversion, and other alternatives |
| `NOSMTC` | Non-SMTC build (for macOS 26.5+): when MediaRemote stops working for third parties, routes through AppleScript + CDP + plist/archive channels instead |
| `PERF` | Performance probe, compiled only with `-D PERF` |

**Requirements**: macOS 10.15 (Catalina) or later, with a dedicated compatibility layer, and forward-compatible with macOS 26 Tahoe.

## Permissions

Some features require system permissions. All data is used locally and never uploaded:

- **Accessibility**: global click detection, keyboard shortcuts, and volume-key hints
- **Full Disk Access**: reading playback data from the QQ Music / KuGou Music containers
- A permission guide appears on first launch, and again if reading the containers fails

## Project Structure

The source is split by module (originally a single `main.swift`; file headers note that imports were auto-generated during the split and should not be adjusted manually):

| File | Responsibility |
| --- | --- |
| `main.swift` | Program entry point |
| `AppDelegate.swift` | Window, menu bar, global events, and permission guide |
| `AppState.swift` | Global state (media / Pomodoro / files / settings, etc.) |
| `Models.swift` | Data models and notch geometry |
| `RootViews.swift` | Root views, clock component, island shape, collapsed/expanded states |
| `PageLayouts.swift` | Per-page layout customization |
| `PagesDashboardMedia.swift` | Dashboard / Media / Lyrics / Pomodoro |
| `PagesFilesSystem.swift` | File Station / App Launcher / System |
| `PagesToolsStatus.swift` | Converter / Status / AI tool monitoring |
| `PagesWeather.swift` | Weather |
| `PagesTeleprompter.swift` | Teleprompter |
| `PagesCustomize.swift` | Marquee / Appearance / Widget management |
| `SettingsWindow.swift` | Standalone Settings window |
| `CommonComponents.swift` | Shared components |
| `Compat.swift` | Compatibility layer and utility extensions |
| `MediaRemoteBridge.swift` | MediaRemote private-framework bridge + volume-key interception |
| `NeteaseCDP.swift` | Netease Cloud Music CDP direct connection |
| `QQMusicArchivePoller.swift` | QQ Music archive direct connection |
| `KuGouPlist.swift` | KuGou Music plist direct connection |
| `Updater.swift` | OTA update check |

## Notes

- The full media/lyrics experience requires the Pro (full) build; the App Store sandboxed build is the trimmed-down Lite edition.
- This repository currently contains source files only and no Xcode project; get the official release from the website.
