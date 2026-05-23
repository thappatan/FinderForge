# FinderForge

<img src="FinderForgeIcon.png" width="96" align="right" alt="">

แอป macOS ตัวเล็กๆ ที่เอาของที่ใช้ได้จริงไปใส่ในเมนูคลิกขวาของ Finder

เริ่มจากอยากได้เมนู "New File" (แบบที่ Windows มี แต่ macOS ไม่รู้ทำไมถึงยังไม่มีสักที) แล้วก็ค่อยๆ กลายเป็นของอีกหลายอย่างที่แอบอยากให้ Finder ทำได้มานาน

*[Read in English →](README.en.md)*

<p align="center">
  <img src="Images/Image.jpg" width="640" alt="เมนู New File และเมนูอื่นๆ ของ FinderForge ในเมนูคลิกขวาของ Finder">
</p>

## ทำอะไรได้บ้าง

**New File** จาก template หลายแบบ: text, Markdown, HTML, JSON, Python, shell, Swift, RTF เลือกได้ว่าจะให้โผล่อันไหนบ้าง แต่ละอันใส่เนื้อหาเริ่มต้นกับชื่อไฟล์ของตัวเองได้ และ template ยังใส่ตัวแปรได้ด้วย เช่น `{date}`, `{user}`, `{folder}`, `{uuid}`

**Cut / Paste (Move)** ย้ายไฟล์แบบเดียวกับ Windows แทนที่จะลากหรือกด ⌥ ตอนวาง ไฟล์ที่ตัดไว้จะมี badge รูปกรรไกรติดอยู่

**Open in Terminal** ด้วย terminal ที่ใช้อยู่จริง ไม่ว่าจะ Terminal, iTerm, Warp, Ghostty และอื่นๆ เหมือนกันกับ **Open in Editor** (VS Code, Cursor, Xcode, Zed…) ใน settings จะโชว์เฉพาะตัวที่ติดตั้งไว้

มีหน้าต่าง settings เล็กๆ กับหน้าแนะนำตอนเปิดครั้งแรก เขียนด้วย SwiftUI ส่วนตัวเมนูกับงานจัดการไฟล์ทั้งหมดอยู่ใน Finder Sync extension สองฝั่งนี้แชร์ค่า settings กันผ่าน App Group ตัว UI มีอังกฤษกับไทย และจะเปลี่ยนตามภาษาของระบบเอง

## วิธี build

ต้องมี Xcode 15 ขึ้นไป กับ XcodeGen:

```
brew install xcodegen
xcodegen generate
```

จากนั้นรันสคริปต์ช่วย ซึ่งจะ build, reload extension แล้วเปิดแอปให้:

```
./Scripts/run.sh
```

หรือจะเปิด `FinderForge.xcodeproj` แล้วกด Cmd+R ก็ได้

ตัว `.xcodeproj` ถูก generate จาก `project.yml` เลยไม่ได้เก็บไว้ใน git ให้แก้ที่ `project.yml` อย่าไปแก้ไฟล์โปรเจกต์ตรงๆ ถ้า fork ไปใช้ ก็เปลี่ยน `DEVELOPMENT_TEAM` เป็น team ของตัวเอง

ครั้งแรกต้องไปเปิด extension เองก่อน: System Settings → General → Login Items & Extensions แล้วหาในหัวข้อ Added Extensions (หรือ Finder) ติ๊กเปิด FinderForge จากนั้นคลิกขวาที่โฟลเดอร์ไหนก็ได้ เมนูน่าจะขึ้นมา ถ้าไม่ขึ้น `killall Finder` มักจะช่วยได้

## โครงสร้าง

```
FinderForge/             แอป SwiftUI (settings + onboarding)
FinderMenuExtension/     Finder Sync extension (เมนู, จัดการไฟล์)
Shared/                  SharedSettings.swift ใช้ร่วมกันทั้งสองฝั่ง
Scripts/                 run.sh กับสคริปต์ทำไอคอน
project.yml              สเปกของ XcodeGen
FinderForgeIcon.png      ไอคอนต้นฉบับ 1024px
```

`SharedSettings.swift` ถูก compile เข้าทั้งสอง target และเป็นอย่างเดียวที่สองฝั่งใช้ร่วมกันตอนรัน ผ่าน App Group

## เรื่องที่ควรรู้ไว้

Finder ส่งเมนูข้ามขอบเขต XPC แล้วตัดอะไรที่ serialize ไม่ได้ทิ้งระหว่างทาง เลยเป็นเหตุผลว่าทำไมในเมนูถึงไม่มีเส้น separator จริงๆ หรือหัวข้อ section แบบมีสไตล์ และทำไมไอคอนในเมนูถึงเป็น bitmap สีธรรมดาแทนที่จะเป็น SF Symbol (symbol แบบ template จะกลายเป็นสีดำทึบฝั่งโน้น) กว่าจะรู้ก็เสียเวลาไปพอควร

อีกอย่างคือ Finder extension ดักจับ ⌘X / ⌘V ระดับทั้งระบบไม่ได้ Cut กับ Paste เลยอยู่ในเมนูคลิกขวาอย่างเดียว ไม่มีคีย์ลัด

## เปลี่ยนไอคอน

แทนไฟล์ `FinderForgeIcon.png` แล้วรัน:

```
./Scripts/make_app_icon.sh
```

มันจะ trim ขอบโปร่งใส ขยายภาพให้เต็มกรอบ แล้ว export ออกมาทุกขนาด ใส่ตัวเลขต่อท้ายได้ (เช่น `./Scripts/make_app_icon.sh 1000`) ถ้าอยากให้ชิดขอบกว่าหรือหลวมกว่านี้

## เพิ่มภาษา

ข้อความอยู่ใน `en.lproj/` กับ `th.lproj/` ของแต่ละ target และข้อความภาษาอังกฤษในโค้ดคือ key ที่ใช้ค้นหา ถ้าจะเพิ่มภาษา ก็เอา `<lang>.lproj/Localizable.strings` ใส่เข้าไปทั้งสอง target ด้วย key ชุดเดียวกัน แล้วรัน `xcodegen generate`

## ที่ยังค้างอยู่

Copy Path, New Folder จากไฟล์ที่เลือก, import/export templates, บีบอัด zip, template ที่รู้จัก `.git`, iCloud sync

## License

GPLv3 ข้อความเต็มอยู่ในไฟล์ [LICENSE](LICENSE) เอาไป fork ได้เลย ขอแค่เปิด source ต่อ

© 2026 thappatan chanphen
