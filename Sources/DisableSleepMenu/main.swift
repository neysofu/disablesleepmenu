import SwiftUI

@main
struct DisableSleepMenuApp: App {
    @StateObject private var sleepManager = SleepManager()

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 8) {
                Text(sleepManager.isDisabled ? "Sleep: Disabled" : "Sleep: Enabled")
                    .font(.headline)
                Divider()
                Button(sleepManager.isDisabled ? "Enable Sleep" : "Disable Sleep") {
                    sleepManager.toggle()
                }
                .keyboardShortcut("t")
                Divider()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(4)
        } label: {
            Image(systemName: sleepManager.isDisabled ? "moon.zzz.fill" : "moon.zzz")
        }
    }
}
