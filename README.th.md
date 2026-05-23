<div align="center">
  <img src="FinderForgeIcon.png" width="128" alt="FinderForge icon">
  <h1>FinderForge</h1>
  <p><strong>เพิ่มพลังให้เมนูคลิกขวาของ Finder</strong></p>
  <p>สร้างไฟล์จาก template, ย้ายไฟล์ด้วย Cut/Paste, และเปิดโฟลเดอร์ใน terminal หรือ editor — ทั้งหมดจากเมนูคลิกขวาของ Finder</p>
  <p><a href="README.md">English</a> · <strong>ไทย</strong></p>
</div>

---

## ฟีเจอร์

- **New File** — สร้างไฟล์จากเมนูคลิกขวา (txt, md, html, json, py, sh, swift, rtf…) เปิด/ปิดแต่ละชนิดได้
  - กำหนด **เนื้อหา template** ต่อชนิดได้ พร้อมตัวแปร: `{date}` `{time}` `{datetime}` `{user}` `{folder}` `{uuid}` `{cursor}`
  - กำหนด **ชื่อไฟล์เริ่มต้น** ต่อ template
- **Cut / Paste (Move)** — ย้ายไฟล์แบบ Windows ผ่านคลิกขวา พร้อม badge รูปกรรไกรบนไฟล์ที่ตัด
- **Open in Terminal** — Terminal, iTerm, Warp, Ghostty, WezTerm, kitty, Alacritty… (เลือกได้ใน Settings)
- **Open in Editor** — VS Code, Cursor, Windsurf, Xcode, Sublime Text, Zed, Nova… (แสดงเฉพาะตัวที่ติดตั้งไว้)
- **แอป Settings** (SwiftUI) + **onboarding** ตอนเปิดครั้งแรก
- **รองรับ 2 ภาษา** อังกฤษ และ ไทย — สลับตามภาษาของระบบอัตโนมัติ

## หลักการทำงาน

2 target ที่แชร์การตั้งค่ากันผ่าน **App Group**:

```
Finder ──(คลิกขวา)──▶ FinderMenuExtension (FIFinderSync, AppKit)
                              │  อ่าน settings / เขียนสถานะ cut
                              ▼
                      App Group UserDefaults
                              ▲
                              │  เขียน settings
                      FinderForge (แอปหลัก SwiftUI)
```

| | |
| --- | --- |
| UI แอปหลัก | SwiftUI |
| Extension | AppKit + FinderSync |
| ภาษา | Swift 5 mode |
| macOS ขั้นต่ำ | 13.0 (Ventura) |
| โปรเจกต์ | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) |
| Storage ที่แชร์ | App Group UserDefaults |

## ความต้องการ

- macOS 13+ และ **Xcode 15+**
- **XcodeGen** — `brew install xcodegen`
- Apple Developer team สำหรับเซ็นชื่อ ตั้งค่าของคุณใน `project.yml` (`DEVELOPMENT_TEAM`) และเปลี่ยน bundle prefix ถ้า fork ไปใช้
  > App Group ใช้ได้กับ **Personal Team แบบฟรี** สำหรับ dev บนเครื่องตัวเอง แต่ถ้าจะแจกจ่ายไปเครื่องอื่น / ขึ้น App Store ต้องใช้ **Apple Developer Program แบบเสียเงิน**

## Build & Run

```bash
# 1. สร้าง Xcode project จาก project.yml
xcodegen generate

# 2a. build + reload extension + เปิดแอป (แนะนำ)
./Scripts/run.sh

# 2b. …หรือเปิดใน Xcode แล้วกด Cmd+R
open FinderForge.xcodeproj
```

**เปิด extension ครั้งเดียว:** System Settings → General → *Login Items & Extensions* → **Added Extensions** (หรือ *Finder*) → ติ๊กเปิด **FinderForge** จากนั้นคลิกขวาในโฟลเดอร์ใดก็ได้ใน Finder

> เมนูไม่ขึ้นหลังเปิด extension? `killall Finder`

## โครงสร้างโปรเจกต์

```
FinderForge/
├── FinderForge/                 ← แอปหลัก (SwiftUI)
│   ├── FinderForgeApp.swift · SettingsView.swift · OnboardingView.swift
│   ├── Assets.xcassets/ · Info.plist · FinderForge.entitlements
│   └── en.lproj/ · th.lproj/
├── FinderMenuExtension/         ← Finder Sync extension (AppKit)
│   ├── FinderSync.swift · MenuBuilder.swift · FileCreator.swift · CutPasteManager.swift
│   ├── Info.plist · FinderMenuExtension.entitlements
│   └── en.lproj/ · th.lproj/
├── Shared/SharedSettings.swift  ← model + App Group storage (อยู่ในทั้ง 2 target)
├── Scripts/                     ← run.sh, make_app_icon.sh, frame_icon.swift
├── project.yml                  ← สเปก XcodeGen (แก้ที่นี่ ไม่ใช่ .xcodeproj)
└── FinderForgeIcon.png          ← ไอคอนต้นฉบับ 1024px
```

`.xcodeproj` ถูก **generate** ขึ้นมา (ไม่เก็บใน git) ให้แก้ `project.yml` แล้วรัน `xcodegen generate`

## ไอคอน

ไอคอนแอปสร้างจาก `FinderForgeIcon.png` ถ้าจะเปลี่ยน ให้แทนไฟล์นั้นแล้วรัน:

```bash
./Scripts/make_app_icon.sh        # trim ขอบ, ขยายให้เต็มกรอบ, export ครบทุกขนาด
```

## การแปลภาษา (Localization)

ข้อความ UI อยู่ใน `*/en.lproj/Localizable.strings` และ `*/th.lproj/Localizable.strings` ของแต่ละ target โดย string literal ในโค้ดเป็นภาษาอังกฤษ (ใช้เป็น key) ถ้าจะเพิ่มภาษา ให้สร้าง `<lang>.lproj/Localizable.strings` ใน **ทั้ง 2 target** ด้วย key เดียวกัน แล้วรัน `xcodegen generate`

## ข้อจำกัดที่ควรรู้

- Finder ส่งเมนูของ extension ผ่าน **XPC** ซึ่ง strip สไตล์พิเศษทิ้ง — เส้น separator, section header, และสี/ขนาดฟอนต์ของ attributedTitle จะหาย (เมนูเลยใช้ item ธรรมดา + ไอคอนสีที่ bake มาแล้ว)
- Finder Sync extension ดักจับ `⌘X`/`⌘V` ระดับ global ไม่ได้ Cut/Paste จึงอยู่ในเมนูคลิกขวา
- Sandbox จำกัดการเข้าถึงไฟล์เท่าที่ Finder ให้มา ส่วน `temporary-exception` entitlements ใช้สำหรับ dev/แจกจ่ายเองเท่านั้น และต้องเอาออกถ้าจะขึ้น App Store

## แผนพัฒนา (Roadmap)

Copy Path · New Folder (พร้อมไฟล์ที่เลือก) · Import/Export templates · บีบอัดเป็น .zip · ตรวจจับโปรเจกต์ (`.git`) · iCloud sync · เพิ่มภาษาอื่นๆ

## License

_เลือก license (เช่น MIT) แล้วเพิ่มไฟล์ `LICENSE`_
