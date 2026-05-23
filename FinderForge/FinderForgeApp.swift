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
