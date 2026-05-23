//
//  MenuBarContent.swift
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

import SwiftUI

/// The dropdown shown when the menu bar icon is clicked: quick toggles for the
/// two "Open in …" items, plus Settings and Quit. State is read from the App
/// Group on each open (the menu rebuilds), so it stays in sync with Settings.
struct MenuBarContent: View {
    @State private var openInTerminal = SharedSettings.loadOpenInTerminalEnabled()
    @State private var openInEditor = SharedSettings.loadOpenInEditorEnabled()

    var body: some View {
        Toggle("Open in Terminal", isOn: $openInTerminal)
            .onChange(of: openInTerminal) { SharedSettings.saveOpenInTerminalEnabled($0) }
        Toggle("Open in Editor", isOn: $openInEditor)
            .onChange(of: openInEditor) { SharedSettings.saveOpenInEditorEnabled($0) }

        Divider()

        Button("Settings…") {
            // Defer to the next runloop tick so the menu finishes dismissing
            // before we try to bring the window forward.
            DispatchQueue.main.async {
                appLog.debug("Settings… tapped")
                AppDelegate.shared?.showMainWindow()
            }
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Quit FinderForge") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q", modifiers: .command)
    }
}
