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

@main
struct FinderForgeApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                SettingsView()
                    .frame(minWidth: 520, minHeight: 480)
            } else {
                OnboardingView(onComplete: { hasOnboarded = true })
                    .frame(minWidth: 520, minHeight: 480)
            }
        }
        .windowResizability(.contentSize)
    }
}
