import Foundation

// MARK: - File Template Model

struct FileTemplate: Codable, Identifiable, Hashable {
    var id: String { ext + name }
    var name: String              // "Markdown"
    let ext: String               // "md"
    var enabled: Bool
    var templateContent: String?  // nil = empty file
    var baseName: String = "Untitled"

    static let defaults: [FileTemplate] = [
        FileTemplate(name: "Text File", ext: "txt", enabled: true,
                     templateContent: nil),
        FileTemplate(name: "Markdown", ext: "md", enabled: true,
                     templateContent: "# {cursor}\n\n"),
        FileTemplate(name: "HTML File", ext: "html", enabled: true,
                     templateContent: """
                     <!DOCTYPE html>
                     <html>
                     <head>
                       <meta charset="utf-8">
                       <title></title>
                     </head>
                     <body>
                     {cursor}
                     </body>
                     </html>
                     """),
        FileTemplate(name: "JSON File", ext: "json", enabled: true,
                     templateContent: "{\n  {cursor}\n}\n"),
        FileTemplate(name: "Python Script", ext: "py", enabled: true,
                     templateContent: "#!/usr/bin/env python3\n\n{cursor}\n"),
        FileTemplate(name: "Shell Script", ext: "sh", enabled: false,
                     templateContent: "#!/bin/bash\n\n{cursor}\n"),
        FileTemplate(name: "Swift File", ext: "swift", enabled: false,
                     templateContent: "import Foundation\n\n{cursor}\n"),
        FileTemplate(name: "RTF Document", ext: "rtf", enabled: false,
                     templateContent: nil),
    ]
}

// MARK: - Terminal Model

/// The terminal app chosen in Settings for the "Open in Terminal" menu item.
struct TerminalChoice: Codable, Equatable, Hashable {
    var name: String
    var bundleID: String

    static let terminalApp = TerminalChoice(name: "Terminal", bundleID: "com.apple.Terminal")

    /// Curated list of common terminals; Settings shows the ones actually installed.
    static let known: [TerminalChoice] = [
        TerminalChoice(name: "Terminal", bundleID: "com.apple.Terminal"),
        TerminalChoice(name: "iTerm", bundleID: "com.googlecode.iterm2"),
        TerminalChoice(name: "Warp", bundleID: "dev.warp.Warp-Stable"),
        TerminalChoice(name: "Ghostty", bundleID: "com.mitchellh.ghostty"),
        TerminalChoice(name: "WezTerm", bundleID: "com.github.wez.wezterm"),
        TerminalChoice(name: "kitty", bundleID: "net.kovidgoyal.kitty"),
        TerminalChoice(name: "Alacritty", bundleID: "org.alacritty"),
        TerminalChoice(name: "Hyper", bundleID: "co.zeit.hyper"),
        TerminalChoice(name: "Tabby", bundleID: "org.tabby"),
    ]
}

// MARK: - Editor Model

/// The code editor chosen in Settings for the "Open in Editor" menu item.
struct EditorChoice: Codable, Equatable, Hashable {
    var name: String
    var bundleID: String

    static let vscode = EditorChoice(name: "Visual Studio Code", bundleID: "com.microsoft.VSCode")

    /// Curated list of common editors; Settings shows the ones actually installed.
    static let known: [EditorChoice] = [
        EditorChoice(name: "Visual Studio Code", bundleID: "com.microsoft.VSCode"),
        EditorChoice(name: "Cursor", bundleID: "com.todesktop.230313mzl4w4u92"),
        EditorChoice(name: "Windsurf", bundleID: "com.exafunction.windsurf"),
        EditorChoice(name: "Xcode", bundleID: "com.apple.dt.Xcode"),
        EditorChoice(name: "Sublime Text", bundleID: "com.sublimetext.4"),
        EditorChoice(name: "Zed", bundleID: "dev.zed.Zed"),
        EditorChoice(name: "Nova", bundleID: "com.panic.Nova"),
        EditorChoice(name: "BBEdit", bundleID: "com.barebones.bbedit"),
        EditorChoice(name: "VSCodium", bundleID: "com.vscodium"),
        EditorChoice(name: "TextMate", bundleID: "com.macromates.TextMate"),
    ]
}

// MARK: - Shared Storage

enum SharedSettings {
    /// ⚠️ ต้องตรงกับ App Group identifier ใน entitlements
    static let appGroupID = "group.com.devsun.finderforge"

    private static let templatesKey = "fileTemplates"
    private static let cutItemsKey = "cutItemPaths"
    private static let cutTimestampKey = "cutTimestamp"
    private static let terminalKey = "terminalChoice"
    private static let openInTerminalEnabledKey = "openInTerminalEnabled"
    private static let editorKey = "editorChoice"
    private static let openInEditorEnabledKey = "openInEditorEnabled"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: Templates

    static func loadTemplates() -> [FileTemplate] {
        guard let data = defaults.data(forKey: templatesKey),
              let templates = try? JSONDecoder().decode([FileTemplate].self, from: data)
        else {
            return FileTemplate.defaults
        }
        return templates
    }

    static func saveTemplates(_ templates: [FileTemplate]) {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        defaults.set(data, forKey: templatesKey)
    }

    // MARK: Cut/Paste Clipboard

    static func loadCutItems() -> [String] {
        defaults.stringArray(forKey: cutItemsKey) ?? []
    }

    static func saveCutItems(_ paths: [String]) {
        defaults.set(paths, forKey: cutItemsKey)
        defaults.set(Date(), forKey: cutTimestampKey)
    }

    static func clearCutItems() {
        defaults.removeObject(forKey: cutItemsKey)
        defaults.removeObject(forKey: cutTimestampKey)
    }

    /// Auto-clear cut items if older than N seconds (call before use)
    static func purgeStaleCutItems(maxAge: TimeInterval = 3600) {
        guard let ts = defaults.object(forKey: cutTimestampKey) as? Date else { return }
        if Date().timeIntervalSince(ts) > maxAge {
            clearCutItems()
        }
    }

    // MARK: Open in Terminal

    static func loadTerminal() -> TerminalChoice {
        guard let data = defaults.data(forKey: terminalKey),
              let choice = try? JSONDecoder().decode(TerminalChoice.self, from: data)
        else {
            return .terminalApp
        }
        return choice
    }

    static func saveTerminal(_ choice: TerminalChoice) {
        guard let data = try? JSONEncoder().encode(choice) else { return }
        defaults.set(data, forKey: terminalKey)
    }

    static func loadOpenInTerminalEnabled() -> Bool {
        defaults.object(forKey: openInTerminalEnabledKey) as? Bool ?? true
    }

    static func saveOpenInTerminalEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: openInTerminalEnabledKey)
    }

    // MARK: Open in Editor

    static func loadEditor() -> EditorChoice {
        guard let data = defaults.data(forKey: editorKey),
              let choice = try? JSONDecoder().decode(EditorChoice.self, from: data)
        else {
            return .vscode
        }
        return choice
    }

    static func saveEditor(_ choice: EditorChoice) {
        guard let data = try? JSONEncoder().encode(choice) else { return }
        defaults.set(data, forKey: editorKey)
    }

    static func loadOpenInEditorEnabled() -> Bool {
        defaults.object(forKey: openInEditorEnabledKey) as? Bool ?? true
    }

    static func saveOpenInEditorEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: openInEditorEnabledKey)
    }
}
