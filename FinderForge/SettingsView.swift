//
//  SettingsView.swift
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

enum SidebarItem: Hashable {
    case terminal
    case editor
    case template(FileTemplate.ID)
}

struct SettingsView: View {
    @State private var templates: [FileTemplate] = SharedSettings.loadTemplates()
    @State private var selection: SidebarItem?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("General") {
                    Label("Open in Terminal", systemImage: "terminal")
                        .tag(SidebarItem.terminal)
                    Label("Open in Editor", systemImage: "chevron.left.forwardslash.chevron.right")
                        .tag(SidebarItem.editor)
                }

                Section("File Types") {
                    ForEach($templates) { $template in
                        HStack {
                            Toggle(isOn: $template.enabled) {
                                EmptyView()
                            }
                            .toggleStyle(.switch)
                            .labelsHidden()

                            VStack(alignment: .leading) {
                                Text(template.name)
                                Text(".\(template.ext)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(SidebarItem.template(template.id))
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 220)
        } detail: {
            switch selection {
            case .terminal:
                TerminalSettingsView()
            case .editor:
                EditorSettingsView()
            case .template(let id):
                if let idx = templates.firstIndex(where: { $0.id == id }) {
                    TemplateDetailView(template: $templates[idx])
                } else {
                    EmptySelectionView()
                }
            case nil:
                EmptySelectionView()
            }
        }
        .onChange(of: templates) { newValue in
            SharedSettings.saveTemplates(newValue)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reset to defaults") {
                    templates = FileTemplate.defaults
                }
            }
        }
    }
}

struct TemplateDetailView: View {
    @Binding var template: FileTemplate

    var body: some View {
        Form {
            Section("General") {
                TextField("Name", text: $template.name)
                TextField("Extension", text: .constant(template.ext))
                    .disabled(true)
                TextField("Default file name", text: $template.baseName)
                Toggle("Enabled in menu", isOn: $template.enabled)
            }

            Section("Template Content") {
                Text("Supported variables: {date} {time} {user} {folder} {uuid} {counter} {cursor}")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: Binding(
                    get: { template.templateContent ?? "" },
                    set: { template.templateContent = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
            }
        }
        .formStyle(.grouped)
    }
}

struct TerminalSettingsView: View {
    @State private var enabled = SharedSettings.loadOpenInTerminalEnabled()
    @State private var choice = SharedSettings.loadTerminal()
    @State private var installed: [TerminalChoice] = []

    var body: some View {
        Form {
            Section("Open in Terminal") {
                Toggle("Show \"Open in Terminal\" in the Finder menu", isOn: $enabled)

                Picker("Terminal app", selection: $choice) {
                    ForEach(installed, id: \.self) { term in
                        Text(term.name).tag(term)
                    }
                }
                .disabled(!enabled || installed.count <= 1)
            }

            Section {
                Text("Choose the terminal app to open when you click \"Open in …\" in Finder's right-click menu. The menu opens that terminal at the folder. Only terminals installed on this Mac are shown (Terminal.app and iTerm support cd-ing into the folder best).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Open in Terminal")
        .onAppear { installed = Self.installedTerminals(including: choice) }
        .onChange(of: enabled) { SharedSettings.saveOpenInTerminalEnabled($0) }
        .onChange(of: choice) { SharedSettings.saveTerminal($0) }
    }

    /// Known terminals filtered to those installed, always including the saved choice.
    static func installedTerminals(including current: TerminalChoice) -> [TerminalChoice] {
        let ws = NSWorkspace.shared
        var result = TerminalChoice.known.filter {
            ws.urlForApplication(withBundleIdentifier: $0.bundleID) != nil
        }
        if !result.contains(where: { $0.bundleID == current.bundleID }) {
            result.insert(current, at: 0)
        }
        return result
    }
}

struct EditorSettingsView: View {
    @State private var enabled = SharedSettings.loadOpenInEditorEnabled()
    @State private var choice = SharedSettings.loadEditor()
    @State private var installed: [EditorChoice] = []

    var body: some View {
        Form {
            Section("Open in Editor") {
                Toggle("Show \"Open in Editor\" in the Finder menu", isOn: $enabled)

                if installed.isEmpty {
                    Text("No supported code editor found on this Mac (e.g. VS Code, Cursor, Xcode)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Editor app", selection: $choice) {
                        ForEach(installed, id: \.self) { editor in
                            Text(editor.name).tag(editor)
                        }
                    }
                    .disabled(!enabled || installed.count <= 1)
                }
            }

            Section {
                Text("Choose the editor app to open when you click \"Open in …\" in Finder's right-click menu. The menu opens the editor with the folder as its workspace. Only editors installed on this Mac are shown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Open in Editor")
        .onAppear {
            installed = Self.installedEditors(including: choice)
            // If the saved editor isn't installed, fall back to the first installed one.
            if let first = installed.first,
               NSWorkspace.shared.urlForApplication(withBundleIdentifier: choice.bundleID) == nil {
                choice = first
            }
        }
        .onChange(of: enabled) { SharedSettings.saveOpenInEditorEnabled($0) }
        .onChange(of: choice) { SharedSettings.saveEditor($0) }
    }

    /// Known editors filtered to those installed, always including the saved choice if present.
    static func installedEditors(including current: EditorChoice) -> [EditorChoice] {
        let ws = NSWorkspace.shared
        var result = EditorChoice.known.filter {
            ws.urlForApplication(withBundleIdentifier: $0.bundleID) != nil
        }
        if ws.urlForApplication(withBundleIdentifier: current.bundleID) != nil,
           !result.contains(where: { $0.bundleID == current.bundleID }) {
            result.insert(current, at: 0)
        }
        return result
    }
}

/// macOS 13-compatible placeholder (ContentUnavailableView is macOS 14+).
struct EmptySelectionView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Select an item")
                .font(.title2)
            Text("Choose an item from the list on the left")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
