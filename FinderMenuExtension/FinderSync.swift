//
//  FinderSync.swift
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

import Cocoa
import FinderSync
import OSLog

let extLog = Logger(subsystem: "com.devsun.FinderForge", category: "extension")

class FinderSync: FIFinderSync {

    private let menuBuilder = MenuBuilder()
    private let fileCreator = FileCreator()
    private let cutPasteManager = CutPasteManager()

    override init() {
        super.init()
        configure()
    }

    private func configure() {
        let controller = FIFinderSyncController.default()

        // monitor ทุก path ในเครื่อง
        controller.directoryURLs = [URL(fileURLWithPath: "/")]

        // register badge สำหรับ cut items
        if let cutIcon = NSImage(systemSymbolName: "scissors",
                                 accessibilityDescription: "Cut") {
            controller.setBadgeImage(cutIcon,
                                     label: "Cut",
                                     forBadgeIdentifier: "cut")
        }

        // restore cut state จาก session ก่อน
        SharedSettings.purgeStaleCutItems()
        for path in SharedSettings.loadCutItems() {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                controller.setBadgeIdentifier("cut", for: url)
            }
        }
    }

    // MARK: - Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        extLog.debug("menu(for:) kind=\(menuKind.rawValue) pid=\(ProcessInfo.processInfo.processIdentifier)")
        let selected = FIFinderSyncController.default().selectedItemURLs() ?? []
        return menuBuilder.buildMenu(
            selectedItems: selected,
            target: self,
            createAction: #selector(handleCreate(_:)),
            cutAction: #selector(handleCut(_:)),
            pasteAction: #selector(handlePaste(_:)),
            clearCutAction: #selector(handleClearCut(_:)),
            openTerminalAction: #selector(handleOpenTerminal(_:)),
            openEditorAction: #selector(handleOpenEditor(_:))
        )
    }

    // MARK: - Actions

    @objc func handleCreate(_ sender: NSMenuItem) {
        extLog.debug("handleCreate fired; title=\(sender.title, privacy: .public)")
        // representedObject is the template's String id (see MenuBuilder note).
        // Fall back to matching by the menu item title if needed.
        let templates = SharedSettings.loadTemplates()
        let template: FileTemplate? = {
            if let id = sender.representedObject as? String,
               let match = templates.first(where: { $0.id == id }) {
                return match
            }
            return templates.first(where: { $0.name == sender.title })
        }()
        guard let template else {
            extLog.error("handleCreate: could not resolve template for '\(sender.title, privacy: .public)'")
            return
        }
        let folder = resolveTargetFolder()
        guard let folder else {
            extLog.error("handleCreate: resolveTargetFolder returned nil")
            return
        }
        extLog.debug("handleCreate: creating .\(template.ext, privacy: .public) in \(folder.path, privacy: .public)")
        fileCreator.create(template: template, in: folder)
    }

    @objc func handleCut(_ sender: NSMenuItem) {
        let selected = FIFinderSyncController.default().selectedItemURLs() ?? []
        extLog.debug("handleCut fired; \(selected.count) item(s)")
        cutPasteManager.cut(items: selected)
    }

    @objc func handlePaste(_ sender: NSMenuItem) {
        guard let folder = resolveTargetFolder() else {
            extLog.error("handlePaste: resolveTargetFolder returned nil")
            return
        }
        extLog.debug("handlePaste fired; dest=\(folder.path, privacy: .public)")
        cutPasteManager.pasteMove(to: folder)
    }

    @objc func handleClearCut(_ sender: NSMenuItem) {
        cutPasteManager.clearCut()
    }

    @objc func handleOpenTerminal(_ sender: NSMenuItem) {
        let term = SharedSettings.loadTerminal()
        openInApp(bundleID: term.bundleID, name: term.name)
    }

    @objc func handleOpenEditor(_ sender: NSMenuItem) {
        let editor = SharedSettings.loadEditor()
        openInApp(bundleID: editor.bundleID, name: editor.name)
    }

    // MARK: - Helpers

    /// Launches the app with the resolved target folder (opens it as cwd/workspace).
    private func openInApp(bundleID: String, name: String) {
        guard let folder = resolveTargetFolder() else {
            extLog.error("openInApp(\(name, privacy: .public)): resolveTargetFolder returned nil")
            return
        }
        guard let appURL = NSWorkspace.shared
            .urlForApplication(withBundleIdentifier: bundleID) else {
            extLog.error("openInApp: \(bundleID, privacy: .public) not installed")
            return
        }
        extLog.debug("openInApp: \(name, privacy: .public) at \(folder.path, privacy: .public)")
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.open([folder], withApplicationAt: appURL, configuration: config) { _, error in
            if let error {
                extLog.error("openInApp \(name, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func resolveTargetFolder() -> URL? {
        let controller = FIFinderSyncController.default()
        let selected = controller.selectedItemURLs() ?? []

        if selected.count == 1,
           let isDir = (try? selected[0].resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory,
           isDir {
            return selected[0]
        }
        return controller.targetedURL()
    }
}
