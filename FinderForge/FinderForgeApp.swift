//
//  FinderForgeApp.swift
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
import AppKit
import OSLog

let appLog = Logger(subsystem: "com.devsun.FinderForge", category: "app")

@main
struct FinderForgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The app lives in the menu bar — no Dock icon, no main window.
        MenuBarExtra("FinderForge", systemImage: "folder.badge.plus") {
            MenuBarContent()
        }
    }
}

/// Shows onboarding until it's completed, then the settings UI.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false

    var body: some View {
        if hasOnboarded {
            SettingsView()
        } else {
            OnboardingView(onComplete: { hasOnboarded = true })
        }
    }
}

/// Makes this a menu-bar-only (accessory) app and owns the single settings /
/// onboarding window. We manage the window by hand rather than using a SwiftUI
/// `Settings` / `Window` scene: those don't open reliably from a MenuBarExtra in
/// an accessory app.
final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) weak var shared: AppDelegate?
    private var window: NSWindow?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // First launch: pop the window so the user is told to enable the extension.
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            showMainWindow()
        }
    }

    func showMainWindow() {
        appLog.debug("showMainWindow() called; window exists=\(self.window != nil)")
        if window == nil {
            let hosting = NSHostingController(rootView: RootView())
            let win = NSWindow(contentViewController: hosting)
            win.title = "FinderForge"
            win.styleMask = [.titled, .closable, .miniaturizable]
            win.isReleasedWhenClosed = false        // reuse the window when reopened
            win.setContentSize(NSSize(width: 640, height: 520))
            win.center()
            window = win
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }
}
