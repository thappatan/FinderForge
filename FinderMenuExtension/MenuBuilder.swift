//
//  MenuBuilder.swift
//  FinderForge
//
//  Copyright (C) 2026 thappatan chanphen
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import AppKit

final class MenuBuilder {

    func buildMenu(
        selectedItems: [URL],
        target: AnyObject,
        createAction: Selector,
        cutAction: Selector,
        pasteAction: Selector,
        clearCutAction: Selector,
        openTerminalAction: Selector,
        openEditorAction: Selector
    ) -> NSMenu {
        let menu = NSMenu(title: "")

        // --- New File submenu ---
        let newFileTitle = NSLocalizedString("New File", comment: "Root menu item")
        let newFileRoot = NSMenuItem(title: newFileTitle, action: nil, keyEquivalent: "")
        newFileRoot.image = coloredSymbol("doc.badge.plus", .systemBlue)

        let submenu = NSMenu(title: newFileTitle)
        let templates = SharedSettings.loadTemplates().filter { $0.enabled }

        if templates.isEmpty {
            let empty = NSMenuItem(title: NSLocalizedString("(No file types enabled)", comment: ""),
                                   action: nil, keyEquivalent: "")
            empty.isEnabled = false
            submenu.addItem(empty)
        } else {
            for template in templates {
                let item = NSMenuItem(title: template.name,
                                      action: createAction, keyEquivalent: "")
                item.target = target
                // NOTE: Finder serializes this menu across XPC, which drops any
                // non-NSCoding value. Store the template's String id (survives the
                // round-trip) and look the template back up in the action handler.
                item.representedObject = template.id
                item.image = iconForExtension(template.ext)
                submenu.addItem(item)
            }
        }

        newFileRoot.submenu = submenu
        menu.addItem(newFileRoot)

        // --- Open in Terminal ---
        if SharedSettings.loadOpenInTerminalEnabled() {
            let term = SharedSettings.loadTerminal()
            let title = String(format: NSLocalizedString("Open in %@", comment: "app name"), term.name)
            let item = NSMenuItem(title: title, action: openTerminalAction, keyEquivalent: "")
            item.target = target
            item.image = coloredSymbol("terminal", .systemGray)
            menu.addItem(item)
        }

        // --- Open in Editor (only when the chosen editor is installed) ---
        if SharedSettings.loadOpenInEditorEnabled() {
            let editor = SharedSettings.loadEditor()
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: editor.bundleID) != nil {
                let title = String(format: NSLocalizedString("Open in %@", comment: "app name"), editor.name)
                let item = NSMenuItem(title: title, action: openEditorAction, keyEquivalent: "")
                item.target = target
                item.image = coloredSymbol("chevron.left.forwardslash.chevron.right", .systemBlue)
                menu.addItem(item)
            }
        }

        // --- Cut / Paste section ---
        // No divider between the New File group and the clipboard group: Finder
        // strips separators / section-header styling across XPC, so any divider
        // ends up looking like a stray menu item. Items just sit adjacent instead.
        let cutPending = !SharedSettings.loadCutItems().isEmpty

        if !selectedItems.isEmpty {
            let count = selectedItems.count
            let title = count == 1
                ? NSLocalizedString("Cut", comment: "")
                : String(format: NSLocalizedString("Cut %d items", comment: ""), count)
            let cutItem = NSMenuItem(title: title, action: cutAction, keyEquivalent: "")
            cutItem.target = target
            cutItem.image = coloredSymbol("scissors", .systemOrange)
            menu.addItem(cutItem)
        }

        if cutPending {
            let count = SharedSettings.loadCutItems().count
            let title = count == 1
                ? NSLocalizedString("Paste (Move)", comment: "")
                : String(format: NSLocalizedString("Paste %d items (Move)", comment: ""), count)
            let pasteItem = NSMenuItem(title: title, action: pasteAction, keyEquivalent: "")
            pasteItem.target = target
            pasteItem.image = coloredSymbol("arrow.down.doc", .systemGreen)
            menu.addItem(pasteItem)

            let clearItem = NSMenuItem(title: NSLocalizedString("Clear Cut Selection", comment: ""),
                                       action: clearCutAction, keyEquivalent: "")
            clearItem.target = target
            clearItem.image = coloredSymbol("xmark.circle", .systemGray)
            menu.addItem(clearItem)
        }

        return menu
    }

    /// Renders an SF Symbol into a concrete, *colored* (non-template) bitmap.
    /// Template images get sent to Finder across XPC and render as flat black;
    /// baking the color in keeps them consistent regardless of who draws them.
    private func coloredSymbol(_ name: String, _ color: NSColor, size: CGFloat = 15) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
        guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return nil }

        let canvas = NSSize(width: size + 3, height: size + 3)
        let out = NSImage(size: canvas)
        out.lockFocus()
        let s = base.size
        let dr = NSRect(x: (canvas.width - s.width) / 2,
                        y: (canvas.height - s.height) / 2,
                        width: s.width, height: s.height)
        base.draw(in: dr)
        color.set()
        NSGraphicsContext.current?.compositingOperation = .sourceAtop
        NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()
        out.unlockFocus()
        out.isTemplate = false
        return out
    }

    private func iconForExtension(_ ext: String) -> NSImage? {
        // ใช้ icon ของ system สำหรับ file type นั้นๆ
        let workspace = NSWorkspace.shared
        let icon = workspace.icon(forFileType: ext)
        icon.size = NSSize(width: 16, height: 16)
        return icon
    }
}
