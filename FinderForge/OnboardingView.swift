import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var step = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            switch step {
            case 0:
                stepWelcome
            case 1:
                stepEnableExtension
            default:
                stepReady
            }

            Spacer()

            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                }
                Spacer()
                Button(step < 2 ? "Next" : "Get Started") {
                    if step < 2 { step += 1 } else { onComplete() }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(40)
    }

    private var stepWelcome: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            Text("Welcome to FinderForge").font(.largeTitle).bold()
            Text("Add a New File menu to Finder's right-click menu")
                .foregroundStyle(.secondary)
        }
    }

    private var stepEnableExtension: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enable the Extension").font(.title).bold()
            Text("To make the menu appear in Finder, you need to enable the extension first:")
            Group {
                Text("1. Open **System Settings**")
                Text("2. Go to **Privacy & Security → Extensions**")
                Text("3. Click **Added Extensions** or **Finder Extensions**")
                Text("4. Turn on **FinderForge**")
            }
            Button("Open System Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var stepReady: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("You're all set!").font(.largeTitle).bold()
            Text("Right-click any folder in Finder to see the New File menu")
                .multilineTextAlignment(.center)
        }
    }
}
