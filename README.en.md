# IsleX

**Turn your MacBook's notch into a dynamic island.** Free, open source, native Swift.

**[Download](https://github.com/DongWK-CHN/IsleX/releases/latest)** · macOS 14+ · Apple Silicon

Move the cursor up to the notch and it opens; move away and it folds back. Everything lives in that little strip:

- clock, CPU / memory / battery at a glance
- now playing with cover art, lyrics and seek — Apple Music, Spotify, NetEase, QQ Music, Kugou
- pomodoro, to-dos, weather, teleprompter
- drag files onto it to park them for later
- quick launcher, unit converter, hardware info
- size, corners, fonts, glass, marquee — all adjustable, per page too

Build it with `bash build.sh` (macOS 14 + Xcode command line tools; the dmg lands in `build/`). Media control goes through the private MediaRemote framework, and newer macOS falls back to each player's own API. Volume keys want Accessibility permission. No accounts, no telemetry, settings stay on your Mac.

Chinese README: [README.md](README.md) · Performance numbers: [perf/README.md](perf/README.md)

MIT. If it saves you some screen space, a star is all I ask.
