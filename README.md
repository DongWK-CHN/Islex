# IsleX 灵屿

**把 MacBook 刘海变成灵动岛。免费、开源、原生 Swift。**

[**下载最新版本**](https://github.com/DongWK-CHN/IsleX/releases/latest)（macOS 14+，Apple Silicon）

*演示 GIF 待补*

一个挂在 macOS 刘海上的小工具。鼠标移过去展开，离开自动收起。

## 功能

- 仪表盘：时间、日期、CPU / 内存 / 电量
- 媒体：当前播放、封面、歌词、进度拖拽；支持 Apple Music、Spotify、网易云、QQ 音乐、酷狗
- 番茄钟、待办、天气、提词器
- 文件中转站：文件拖到岛上就能暂存
- 快捷应用、格式转换、硬件状态
- 外观可调：尺寸、圆角、字体、玻璃、跑马灯；每页也能单独设置布局
- 中文 / English / 日本語

## 安装

从 Releases 下载 `IsleX.dmg`，拖进「应用程序」。

首次打开如果提示「无法验证开发者」，去「系统设置 → 隐私与安全性」点「仍要打开」。

## 自己编译

需要 macOS 14 和 Xcode Command Line Tools。

```bash
git clone https://github.com/DongWK-CHN/IsleX.git
cd IsleX
bash build.sh
```

`build.sh` 会生成图标、编译两个版本、打包 dmg。产物在 `build/`。

## 几点说明

- 只支持 Apple Silicon。
- 媒体控制用到了私有框架 MediaRemote。macOS 26.5 之后系统已经停用，新系统会自动改用各播放器自己的接口。
- 音量键拦截需要辅助功能权限，不开也能用其他功能。
- 没有账号、没有遥测，设置和数据都在本地。天气用 Open-Meteo，只发城市名。
- OTA 更新地址现在是占位域名，不会发请求。真要发布的话改 `Sources/Updater.swift` 里的 `manifestURL`。

## 性能

展开动画做过一轮优化，实测数据在 [perf/README.md](perf/README.md)。

## 截图

还没拍，之后补。想帮忙的话看 [docs/screenshots/README.md](docs/screenshots/README.md)。

## 许可证

MIT。

如果这个工具帮到你，点个 Star 就是最大的支持。
