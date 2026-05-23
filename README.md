<div align="center">
  <img src="FinderForgeIcon.png" width="128" alt="FinderForge icon">
  <h1>FinderForge</h1>
  <p><strong>Right-click superpowers for Finder.</strong></p>
  <p>Create files from templates, move files with Cut/Paste, and open folders in your terminal or editor — all from Finder's context menu.</p>
  <p><strong>English</strong> · <a href="README.th.md">ไทย</a></p>
</div>

---

## Features

- **New File** — create files from the right-click menu (txt, md, html, json, py, sh, swift, rtf…). Toggle each type on/off.
  - Per-template **content** with variables: `{date}` `{time}` `{datetime}` `{user}` `{folder}` `{uuid}` `{cursor}`
  - Per-template **default file name**
- **Cut / Paste (Move)** — Windows-style move via right-click, with a scissors badge on cut items.
- **Open in Terminal** — Terminal, iTerm, Warp, Ghostty, WezTerm, kitty, Alacritty… (pick yours in Settings).
- **Open in Editor** — VS Code, Cursor, Windsurf, Xcode, Sublime Text, Zed, Nova… (only installed ones are shown).
- **Settings app** (SwiftUI) + first-run **onboarding**.
- **Localized** in English and ไทย — follows the system language automatically.

## How it works

Two targets sharing settings through an **App Group**:

```
Finder ──(right-click)──▶ FinderMenuExtension (FIFinderSync, AppKit)
                                  │  reads settings / writes cut state
                                  ▼
                          App Group UserDefaults
                                  ▲
                                  │  writes settings
                          FinderForge (SwiftUI container app)
```

| | |
| --- | --- |
| Container app UI | SwiftUI |
| Extension | AppKit + FinderSync |
| Language | Swift 5 mode |
| Min macOS | 13.0 (Ventura) |
| Project | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) |
| Shared storage | App Group UserDefaults |

## Requirements

- macOS 13+ and **Xcode 15+**
- **XcodeGen** — `brew install xcodegen`
- An Apple Developer team for signing. Set yours in `project.yml` (`DEVELOPMENT_TEAM`) and the bundle prefix if you fork.
  > App Groups work with a **free** Personal Team for local development, but distributing to other Macs / the App Store needs a **paid** Apple Developer Program membership.

## Build & Run

```bash
# 1. Generate the Xcode project from project.yml
xcodegen generate

# 2a. Build + reload the extension + launch (recommended)
./Scripts/run.sh

# 2b. …or open in Xcode and press Cmd+R
open FinderForge.xcodeproj
```

**Enable the extension once:** System Settings → General → *Login Items & Extensions* → **Added Extensions** (or *Finder*) → turn on **FinderForge**. Then right-click any folder in Finder.

> Menu not showing after enabling? `killall Finder`

## Project structure

```
FinderForge/
├── FinderForge/                 ← container app (SwiftUI)
│   ├── FinderForgeApp.swift · SettingsView.swift · OnboardingView.swift
│   ├── Assets.xcassets/ · Info.plist · FinderForge.entitlements
│   └── en.lproj/ · th.lproj/
├── FinderMenuExtension/         ← Finder Sync extension (AppKit)
│   ├── FinderSync.swift · MenuBuilder.swift · FileCreator.swift · CutPasteManager.swift
│   ├── Info.plist · FinderMenuExtension.entitlements
│   └── en.lproj/ · th.lproj/
├── Shared/SharedSettings.swift  ← model + App Group storage (both targets)
├── Scripts/                     ← run.sh, make_app_icon.sh, frame_icon.swift
├── project.yml                  ← XcodeGen spec (edit this, not the .xcodeproj)
└── FinderForgeIcon.png          ← 1024px master app icon
```

The `.xcodeproj` is **generated** — it is git-ignored. Edit `project.yml`, then run `xcodegen generate`.

## Icon

The app icon is generated from `FinderForgeIcon.png`. To change it, replace that file and run:

```bash
./Scripts/make_app_icon.sh        # trims padding, fills the tile, exports all sizes
```

## Localization

UI strings live in `*/en.lproj/Localizable.strings` and `*/th.lproj/Localizable.strings` for each target. Source string literals are English (the lookup keys). To add a language, create `<lang>.lproj/Localizable.strings` in **both** targets with the same keys and run `xcodegen generate`.

## Known limitations

- Finder serializes the extension menu over **XPC**, which strips custom styling — native separators, section headers, and attributed-title font/color don't survive (the menu uses plain items + baked-in colored icons).
- A Finder Sync extension can't intercept global `⌘X`/`⌘V`; Cut/Paste live in the context menu.
- Sandbox limits file access to what Finder vends; `temporary-exception` entitlements are used for dev/direct distribution and must be removed for the App Store.

## Roadmap

Copy Path · New Folder (with selection) · Import/Export templates · Compress to .zip · project detection (`.git`) · iCloud sync · more languages.

## License

_Choose a license (e.g. MIT) and add a `LICENSE` file._
